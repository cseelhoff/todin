#!/usr/bin/env python3
"""scan_missing_procs.py
================================================================================
Scan odin_flat/ for unresolved identifiers (`Undeclared name: X`), map each
back to its Java owner class + method, and INSERT new rows into the
`methods` table of port.sqlite so the orchestrator's Phase B loop can
queue them like any other unimplemented method.

Why this script exists
----------------------
The original `extract_entities.py` + JaCoCo + static-call-graph pipeline
is conservative on three axes that systematically under-report procs:

  1. javac-synthetic lambdas / anonymous inner classes never appear in
     the source AST extractor.
  2. Reflective factories (XmlGameElementMapper.getDeclaredConstructor)
     leave no static call edge.
  3. JIT-inlined getters / short-circuit-skipped lines confuse JaCoCo's
     line-coverage filter; their `actually_called_in_ai_test` stays 0
     even though a hit caller depends on them.

The Phase A/B subagents and orchestrator have no way to detect the
fourth axis: a callee that simply isn't a row in `methods`. The compiler
is the source of truth — every "Undeclared name" `odin check` emits is a
gap in `methods`.

This script closes the gap by treating `odin check`'s diagnostics as
authoritative and back-filling `methods` from them.

Strategy
--------
1. Run `odin check odin_flat/`. Capture every `Undeclared name: X`
   diagnostic.
2. Bucket each X into:
     - lambda-synthetic   ( `*_lambda_*_<n>$`  )                 → SKIP
     - constant           ( ALL_UPPER_SNAKE )                    → REPORT
     - proc candidate     (everything else)                      → MAP
3. For proc candidates: greedy-prefix-match X against the snake-case
   simple-names of `structs.struct_key` rows. The longest matching
   owner wins. The remaining suffix is the method's snake_case name.
4. Open the owner's `java_file_path` and locate a method whose
   camelCased name equals the snake_case suffix. Capture the parameter
   types from the Java source. Build:

       method_key        := proc:<fq.Owner>#<methodCamel>(<paramTypes>)
       owner_struct_key  := struct:<fq.Owner>
       java_file_path    := <copied from owner struct>
       java_lines        := "<startLine>-<endLine>" if regex captures it
       odin_file_path    := <copied from owner struct>
       is_implemented    := 0
       method_layer      := MAX(method_layer)+1   (queue at the end)

   `INSERT OR IGNORE` so re-running is idempotent.
5. Emit a JSON report listing:
     - inserted_methods            (one row per new methods row)
     - unresolved_constants        (uppercase identifiers we punt)
     - unresolved_lambdas          (synthetic; orchestrator stubs)
     - unresolved_unknown_owner    (snake-prefix didn't match any struct)
     - unresolved_no_java_match    (owner found, but no Java method matches)

Usage
-----
    python3 scripts/scan_missing_procs.py             # dry-run, report only
    python3 scripts/scan_missing_procs.py --commit    # write to port.sqlite

Env vars: PORT_DB (default ./port.sqlite), ODIN_FLAT (default ./odin_flat).
================================================================================
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent.parent
PORT_DB = Path(os.environ.get("PORT_DB", ROOT / "port.sqlite"))
ODIN_FLAT = Path(os.environ.get("ODIN_FLAT", ROOT / "odin_flat"))

# ---------------------------------------------------------------------------
# odin check driver
# ---------------------------------------------------------------------------

UNDECLARED_RE = re.compile(
    r"^(?P<file>[^():]+\.odin)\((?P<line>\d+):(?P<col>\d+)\)\s+Error:\s+"
    r"Undeclared name:\s+(?P<name>\w+)\s*$"
)


def run_odin_check() -> str:
    """Return combined stdout+stderr of `odin check`."""
    cmd_options = [
        ["odin", "check", str(ODIN_FLAT), f"-collection:flat={ODIN_FLAT}"],
        [
            "nix",
            "develop",
            "--command",
            "odin",
            "check",
            str(ODIN_FLAT),
            f"-collection:flat={ODIN_FLAT}",
        ],
    ]
    last_err: subprocess.CalledProcessError | FileNotFoundError | None = None
    for cmd in cmd_options:
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=ROOT,
                check=False,
            )
            return (proc.stdout or "") + (proc.stderr or "")
        except FileNotFoundError as e:
            last_err = e
            continue
    raise RuntimeError(
        f"could not invoke `odin check` (last error: {last_err})"
    )


def parse_undeclared(check_output: str) -> list[dict[str, str]]:
    """Extract every (file, line, col, name) tuple from odin check output."""
    seen: dict[str, dict[str, str]] = {}
    for raw in check_output.splitlines():
        m = UNDECLARED_RE.match(raw.strip())
        if not m:
            continue
        d = m.groupdict()
        # keep first occurrence per name (extra duplicates just add noise)
        if d["name"] not in seen:
            seen[d["name"]] = d
    return list(seen.values())


# ---------------------------------------------------------------------------
# Owner resolution
# ---------------------------------------------------------------------------


def fqcn_simple(struct_key: str) -> str:
    """`struct:foo.bar.Baz$Inner` -> `Baz$Inner` (last dot segment)."""
    fq = struct_key.split(":", 1)[1]
    return fq.rsplit(".", 1)[-1]


def pascal_to_snake(name: str) -> str:
    """PascalCase_with_underscores style -> snake_case.

    Java simple names map to Odin types via the convention used by
    `bootstrap.sh`:
        Foo                -> Foo
        FooBar             -> Foo_Bar
        Foo$Bar            -> Foo_Bar  (inner classes also flatten)
    The Odin proc name uses the same root, snake-cased:
        Foo_Bar.doThing()  -> foo_bar_do_thing
    """
    # Drop inner-class separator so AlliancesTracker$SerializationProxy
    # collapses to AlliancesTrackerSerializationProxy first.
    name = name.replace("$", "")
    # Insert underscores before every transition lower→upper / digit→upper.
    s = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", name)
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
    return s.lower()


def snake_to_camel(name: str) -> str:
    parts = name.split("_")
    return parts[0] + "".join(p.title() for p in parts[1:])


def build_owner_index(conn: sqlite3.Connection) -> list[tuple[str, str, str]]:
    """Return list of (snake_prefix, struct_key, java_file_path).

    Sorted by descending prefix length so longest match wins.
    """
    cur = conn.execute(
        "SELECT struct_key, java_file_path FROM structs WHERE java_file_path IS NOT NULL"
    )
    rows: list[tuple[str, str, str]] = []
    for struct_key, java_path in cur.fetchall():
        simple = fqcn_simple(struct_key)
        snake = pascal_to_snake(simple)
        if snake:
            rows.append((snake, struct_key, java_path))
    rows.sort(key=lambda r: -len(r[0]))
    return rows


def resolve_owner(
    proc_name: str, owners: list[tuple[str, str, str]]
) -> tuple[str, str, str, str] | None:
    """Find the longest owner snake-prefix that matches.

    Returns (owner_snake, struct_key, java_path, method_snake_suffix)
    or None.
    """
    for snake, struct_key, java_path in owners:
        if proc_name == snake:
            # exact match: ambiguous between "constructor" and "missing method"
            # treat as constructor → method name "<init>"
            return snake, struct_key, java_path, "<init>"
        if proc_name.startswith(snake + "_"):
            return snake, struct_key, java_path, proc_name[len(snake) + 1 :]
    return None


# ---------------------------------------------------------------------------
# Java method resolution
# ---------------------------------------------------------------------------

# Match a method declaration. Captures: modifiers, return-type, name,
# arg list. Skips constructors handled separately.
JAVA_METHOD_RE = re.compile(
    r"""
    ^[ \t]*
    (?P<mods>(?:public|private|protected|static|final|abstract|synchronized|default|native|strictfp|@\w+(?:\([^)]*\))?\s+)*)
    (?P<ret>[\w<>\[\]?,.\s]+?)\s+
    (?P<name>[a-zA-Z_]\w*)\s*
    \((?P<args>[^)]*)\)
    [^;{]*[\{;]
    """,
    re.MULTILINE | re.VERBOSE,
)


def java_args_to_keylist(arg_block: str) -> str:
    """Convert `final String foo, int bar` -> `java.lang.String,int`.

    Best effort. Trailing generic params and `final` modifiers are stripped.
    Unqualified types are left as-is (the bootstrap doesn't expand them
    either, so existing method_keys also use raw simple names).
    """
    arg_block = arg_block.strip()
    if not arg_block:
        return ""
    parts: list[str] = []
    depth = 0
    current = ""
    for ch in arg_block:
        if ch == "<":
            depth += 1
            current += ch
        elif ch == ">":
            depth -= 1
            current += ch
        elif ch == "," and depth == 0:
            parts.append(current.strip())
            current = ""
        else:
            current += ch
    if current.strip():
        parts.append(current.strip())

    out: list[str] = []
    for p in parts:
        # drop "final ", drop annotations, drop varargs ellipsis
        p = re.sub(r"@\w+(?:\([^)]*\))?\s+", "", p)
        p = re.sub(r"\bfinal\s+", "", p)
        p = p.replace("...", "[]")
        # split off the parameter name
        toks = p.rsplit(None, 1)
        type_tok = toks[0] if len(toks) == 2 else p
        # collapse generics: List<Foo> -> List
        type_tok = re.sub(r"<[^<>]*>", "", type_tok)
        out.append(type_tok.strip())
    return ",".join(out)


def _scan_methods(text: str, method_camel: str) -> list[dict[str, str]]:
    matches: list[dict[str, str]] = []
    for m in JAVA_METHOD_RE.finditer(text):
        if m.group("name") != method_camel:
            continue
        ret = m.group("ret").strip()
        if ret in {"return", "new", "if", "while", "for", "switch", "throw"}:
            continue
        start_line = text[: m.start()].count("\n") + 1
        end_line = text[: m.end()].count("\n") + 1
        matches.append(
            {
                "ret": ret,
                "args": java_args_to_keylist(m.group("args")),
                "java_lines": f"{start_line}-{end_line}",
            }
        )
    return matches


# Lombok @Getter / @Setter synthesis. A class-level @Getter generates a
# getter for every non-static instance field; a field-level @Getter does
# the same just for that field. boolean fields use `is<Name>()`.
LOMBOK_FIELD_RE = re.compile(
    r"""
    (?P<anns>(?:@\w+(?:\([^)]*\))?\s+)*)
    (?:public|private|protected|\s)\s*
    (?:final\s+|static\s+|transient\s+|volatile\s+)*
    (?P<type>[\w<>\[\]?,.\s]+?)\s+
    (?P<name>[a-zA-Z_]\w*)\s*[=;]
    """,
    re.MULTILINE | re.VERBOSE,
)


def _lombok_synthesized(text: str, method_camel: str) -> list[dict[str, str]]:
    """If the class is annotated `@Getter` / `@Setter` (or a field is) and
    `method_camel` is `getFoo` / `setFoo` / `isFoo` for some field, return a
    synthetic match with java_lines pointing at the field declaration."""
    # Class-level annotations live before the `class Foo` line.
    class_decl = re.search(r"^[^/\n]*\b(?:public\s+|abstract\s+|final\s+)*class\s+\w+", text, re.MULTILINE)
    if class_decl is None:
        # might be an interface; lombok still allowed but rare
        class_decl = re.search(r"^[^/\n]*\binterface\s+\w+", text, re.MULTILINE)
    class_has_getter = False
    class_has_setter = False
    if class_decl:
        head = text[: class_decl.start()]
        # look at the nearest 30 lines preceding class declaration
        head_tail = "\n".join(head.splitlines()[-30:])
        class_has_getter = bool(re.search(r"@Getter\b", head_tail))
        class_has_setter = bool(re.search(r"@Setter\b", head_tail))

    out: list[dict[str, str]] = []
    for fm in LOMBOK_FIELD_RE.finditer(text):
        anns = fm.group("anns") or ""
        ftype = fm.group("type").strip()
        fname = fm.group("name")
        # Strip generics for Odin keyish args
        ftype_simple = re.sub(r"<[^<>]*>", "", ftype).strip()
        field_has_getter = "@Getter" in anns or class_has_getter
        field_has_setter = "@Setter" in anns or class_has_setter
        if not (field_has_getter or field_has_setter):
            continue
        # candidate method names
        is_bool = ftype_simple in {"boolean", "Boolean"}
        cap = fname[:1].upper() + fname[1:]
        getter_name = ("is" if is_bool else "get") + cap
        setter_name = "set" + cap
        line = text[: fm.start()].count("\n") + 1
        if field_has_getter and method_camel == getter_name:
            out.append(
                {
                    "ret": ftype_simple,
                    "args": "",
                    "java_lines": str(line),
                }
            )
        if field_has_setter and method_camel == setter_name:
            out.append(
                {
                    "ret": "void",
                    "args": ftype_simple,
                    "java_lines": str(line),
                }
            )
    return out


# Walk the extends chain. We resolve a parent class's java path by mapping
# its simple name to a struct row in the structs table when possible.
def _parent_class_simple(text: str) -> str | None:
    m = re.search(
        r"\b(?:public\s+|abstract\s+|final\s+)*class\s+\w+\s+extends\s+([\w.]+)",
        text,
    )
    return m.group(1).split(".")[-1] if m else None


def _interface_parents(text: str) -> list[str]:
    m = re.search(
        r"\b(?:public\s+)?interface\s+\w+\s+extends\s+([\w.,\s]+?)\s*[\{]",
        text,
    )
    if not m:
        m = re.search(
            r"\b(?:public\s+|abstract\s+|final\s+)*class\s+\w+(?:\s+extends\s+[\w.<>?, ]+)?\s+implements\s+([\w.,\s<>?]+?)\s*[\{]",
            text,
        )
    if not m:
        return []
    raw = re.sub(r"<[^<>]*>", "", m.group(1))
    return [p.split(".")[-1].strip() for p in raw.split(",") if p.strip()]


def find_java_method(
    java_path: Path,
    method_camel: str,
    conn: sqlite3.Connection | None = None,
    visited: set[str] | None = None,
) -> list[dict[str, str]]:
    """Return matching method declarations, walking parent class + Lombok.

    visited prevents cycles on diamond inheritance.
    """
    if visited is None:
        visited = set()
    if str(java_path) in visited:
        return []
    visited.add(str(java_path))
    try:
        text = java_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []

    matches = _scan_methods(text, method_camel)
    if matches:
        return matches

    # Lombok synthesis on this class
    syn = _lombok_synthesized(text, method_camel)
    if syn:
        return syn

    # Walk the parent class
    if conn is not None:
        parents: list[str] = []
        parent = _parent_class_simple(text)
        if parent:
            parents.append(parent)
        parents.extend(_interface_parents(text))
        for p_simple in parents:
            row = conn.execute(
                "SELECT java_file_path FROM structs "
                "WHERE struct_key LIKE ? AND java_file_path IS NOT NULL "
                "LIMIT 1",
                (f"%.{p_simple}",),
            ).fetchone()
            if row and row[0]:
                inherited = find_java_method(
                    Path(row[0]), method_camel, conn, visited
                )
                if inherited:
                    return inherited
    return []


def find_java_constructor(java_path: Path, simple_name: str) -> list[dict[str, str]]:
    """Constructors don't have return types; find `SimpleName(args) {`."""
    try:
        text = java_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    pat = re.compile(
        rf"\b(public|protected|private|\s)\s*{re.escape(simple_name)}\s*\((?P<args>[^)]*)\)\s*[\{{]",
    )
    out: list[dict[str, str]] = []
    for m in pat.finditer(text):
        start_line = text[: m.start()].count("\n") + 1
        out.append(
            {
                "ret": "void",
                "args": java_args_to_keylist(m.group("args")),
                "java_lines": str(start_line),
            }
        )
    return out


# ---------------------------------------------------------------------------
# Already-defined-in-odin filter
# ---------------------------------------------------------------------------


def existing_odin_proc_names() -> set[str]:
    """Names already defined as `<name> :: proc(...)` somewhere in odin_flat.

    These are real proc symbols. If the compiler still complains they're
    undeclared, that means another error earlier in the file is poisoning
    the package — those are not missing-method cases.
    """
    pat = re.compile(r"^\s*([a-zA-Z_]\w*)\s*::\s*proc\b", re.MULTILINE)
    names: set[str] = set()
    for f in ODIN_FLAT.glob("*.odin"):
        try:
            for m in pat.finditer(f.read_text(encoding="utf-8", errors="replace")):
                names.add(m.group(1))
        except OSError:
            continue
    return names


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    ap.add_argument(
        "--commit",
        action="store_true",
        help="actually INSERT new rows into port.sqlite (default: dry-run)",
    )
    ap.add_argument(
        "--report",
        type=Path,
        default=ROOT / "missing_procs_report.json",
        help="path to write the JSON report (default: ./missing_procs_report.json)",
    )
    args = ap.parse_args()

    print(f"[scan] running odin check on {ODIN_FLAT}", file=sys.stderr)
    output = run_odin_check()
    diagnostics = parse_undeclared(output)
    print(
        f"[scan] {len(diagnostics)} distinct undeclared names found",
        file=sys.stderr,
    )

    conn = sqlite3.connect(PORT_DB)
    owners = build_owner_index(conn)
    existing_procs = existing_odin_proc_names()
    existing_keys = {
        r[0] for r in conn.execute("SELECT method_key FROM methods")
    }
    max_layer_row = conn.execute(
        "SELECT COALESCE(MAX(method_layer), 0) FROM methods"
    ).fetchone()
    next_layer = (max_layer_row[0] or 0) + 1

    inserted: list[dict[str, str]] = []
    unresolved_constants: list[dict[str, str]] = []
    unresolved_lambdas: list[dict[str, str]] = []
    unresolved_unknown_owner: list[dict[str, str]] = []
    unresolved_no_java_match: list[dict[str, str]] = []
    skipped_already_defined: list[dict[str, str]] = []

    # Pre-compute fq-class lookup from struct_key
    for d in diagnostics:
        name = d["name"]
        diag = {
            "name": name,
            "first_seen": f"{Path(d['file']).name}:{d['line']}",
        }

        if name in existing_procs:
            skipped_already_defined.append(diag)
            continue

        if "_lambda_" in name:
            unresolved_lambdas.append(diag)
            continue

        if name.isupper() or re.fullmatch(r"[A-Z][A-Z0-9_]*", name):
            unresolved_constants.append(diag)
            continue

        owner = resolve_owner(name, owners)
        if owner is None:
            unresolved_unknown_owner.append(diag)
            continue

        owner_snake, struct_key, java_path_str, method_snake = owner
        java_path = Path(java_path_str)
        owner_fq = struct_key.split(":", 1)[1]
        owner_simple = fqcn_simple(struct_key)

        if method_snake == "<init>":
            cands = find_java_constructor(java_path, owner_simple.replace("$", "."))
            method_camel = "<init>"
        else:
            method_camel = snake_to_camel(method_snake)
            cands = find_java_method(java_path, method_camel, conn)

        if not cands:
            diag["resolved_owner"] = struct_key
            diag["expected_java_method"] = method_camel
            diag["java_file"] = java_path_str
            unresolved_no_java_match.append(diag)
            continue

        # Look up the owner's odin_file_path for the new row
        owner_odin = conn.execute(
            "SELECT odin_file_path FROM structs WHERE struct_key = ?",
            (struct_key,),
        ).fetchone()
        odin_file_path = owner_odin[0] if owner_odin else None

        # If overloaded, insert each. method_key uses arg-type list to
        # disambiguate, matching the bootstrap convention.
        for cand in cands:
            method_key = (
                f"proc:{owner_fq}#{method_camel}({cand['args']})"
                if method_camel != "<init>"
                else f"proc:{owner_fq}#<init>({cand['args']})"
            )
            if method_key in existing_keys:
                continue
            row = {
                "method_key": method_key,
                "owner_struct_key": struct_key,
                "java_file_path": java_path_str,
                "java_lines": cand["java_lines"],
                "odin_file_path": odin_file_path,
                "is_implemented": 0,
                "method_layer": next_layer,
                "first_seen": diag["first_seen"],
                "resolved_method_camel": method_camel,
                "resolved_args": cand["args"],
            }
            inserted.append(row)
            existing_keys.add(method_key)

    if args.commit and inserted:
        cur = conn.cursor()
        cur.executemany(
            """
            INSERT OR IGNORE INTO methods
                (method_key, owner_struct_key, java_file_path, java_lines,
                 odin_file_path, is_implemented, method_layer)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    r["method_key"],
                    r["owner_struct_key"],
                    r["java_file_path"],
                    r["java_lines"],
                    r["odin_file_path"],
                    r["is_implemented"],
                    r["method_layer"],
                )
                for r in inserted
            ],
        )
        conn.commit()
        print(
            f"[scan] inserted {cur.rowcount} new rows into methods (layer {next_layer})",
            file=sys.stderr,
        )
    elif inserted:
        print(
            f"[scan] DRY-RUN: would insert {len(inserted)} new rows "
            f"into methods (layer {next_layer}). re-run with --commit.",
            file=sys.stderr,
        )

    report = {
        "summary": {
            "diagnostics_found": len(diagnostics),
            "inserted": len(inserted),
            "unresolved_constants": len(unresolved_constants),
            "unresolved_lambdas": len(unresolved_lambdas),
            "unresolved_unknown_owner": len(unresolved_unknown_owner),
            "unresolved_no_java_match": len(unresolved_no_java_match),
            "skipped_already_defined": len(skipped_already_defined),
            "committed": bool(args.commit),
            "next_method_layer": next_layer,
        },
        "inserted": inserted,
        "unresolved_constants": unresolved_constants,
        "unresolved_lambdas": unresolved_lambdas,
        "unresolved_unknown_owner": unresolved_unknown_owner,
        "unresolved_no_java_match": unresolved_no_java_match,
        "skipped_already_defined": skipped_already_defined,
    }
    args.report.write_text(json.dumps(report, indent=2))
    print(f"[scan] report written to {args.report}", file=sys.stderr)

    print(json.dumps(report["summary"], indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
