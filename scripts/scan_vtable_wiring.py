#!/usr/bin/env python3
"""scan_vtable_wiring.py
================================================================================
Scan odin_flat/ for missing constructor proc-field assignments ("vtable
wiring") needed for Java polymorphism to work in the Odin port, and
populate / refresh the `vtable_wiring` tracking table in port.sqlite.

Why this script exists
----------------------
Phase A/B port the structs and method bodies. They do NOT track the
*constructor-side wiring* that connects a subclass's overriding method
to the proc-typed field declared on the parent's "interface" struct.

Pattern recap
-------------
Java:
    class PurchaseDelegate extends BaseTripleADelegate {
        @Override public void start() { ... }
    }
gets translated to:
    Purchase_Delegate :: struct {
        using base_triple_a_delegate: Base_Triple_A_Delegate,
        ...
    }
    purchase_delegate_start :: proc(self: ^Purchase_Delegate) { ... }
    purchase_delegate_new :: proc() -> ^Purchase_Delegate {
        self := new(Purchase_Delegate)
        self.start = ...                  # <-- THE WIRING
        return self
    }
The body `purchase_delegate_start` is a Phase B method. The line
`self.start = ...` inside `purchase_delegate_new` is the wiring step
that Phase B's template never required, so subclass overrides
silently no-op at runtime: `i_delegate_start(d)` falls through to
the base default.

Detection strategy
------------------
1. Parse every `*.odin` file under odin_flat/ to extract:
      a. struct definitions (name -> { embeds: [parent_type, ...],
                                       proc_fields: { name: signature } })
      b. proc bodies, specifically `*_new` constructors (proc-name ->
         { struct: <Type>, assigned_fields: set[str] })
2. Build the embed graph: a struct transitively inherits its parents'
   proc-typed fields via `using parent: Parent`.
3. Read every `methods.method_key` from port.sqlite. For each
   `proc:<fq.Owner>#<name>(...)`, snake_case `<name>` and look up
   `<Type>.<name>` in the resolved proc-field map. If the owner's
   parent declares a proc-typed field with that same snake_case
   name, treat it as an `@Override` requiring constructor wiring.
4. Locate the matching `<owner>_new` constructor (owner snake_cased).
   If it does NOT assign `self.<field> = ...` (directly or through
   the `using` alias), record a vtable_wiring row with status='missing'.
   If it does assign, record status='ok'.
5. INSERT / UPSERT into `vtable_wiring` so the orchestrator can
   query and dispatch a fixup pass like Phase B does for methods.

A second pass also detects what we'll call "discriminator wiring":
constructors of subtypes whose parent struct carries a `kind:
<EnumType>` field used by a switch dispatcher (the Change /
Change_Kind pattern). Any `*_new` for a struct embedding a parent
that has a `kind:` enum field but never assigns `self.kind =` is
flagged status='missing_kind'.

Output
------
  - vtable_wiring rows in port.sqlite (idempotent):
        struct_key       TEXT      -- struct:fq.Owner
        odin_struct_name TEXT      -- Purchase_Delegate
        odin_constructor TEXT      -- purchase_delegate_new
        proc_field       TEXT      -- start | end | kind | ...
        parent_struct    TEXT      -- the type declaring the field
        status           TEXT      -- ok | missing | missing_kind
        odin_file_path   TEXT
        last_scanned     TEXT      -- ISO timestamp
        PRIMARY KEY (odin_struct_name, proc_field)
  - vtable_wiring_report.json with bucket counts and per-bucket samples.

Usage
-----
    python3 scripts/scan_vtable_wiring.py            # dry-run, prints summary
    python3 scripts/scan_vtable_wiring.py --commit   # writes to port.sqlite
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sqlite3
import sys
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
ODIN_FLAT = ROOT / "odin_flat"
DB_PATH = ROOT / "port.sqlite"
REPORT_PATH = ROOT / "vtable_wiring_report.json"

# ---------------------------------------------------------------------------
# Odin parsing
# ---------------------------------------------------------------------------

STRUCT_HDR_RE = re.compile(r"^([A-Z][A-Za-z0-9_]*)\s*::\s*struct\b")
USING_RE      = re.compile(r"^\s*using\s+\w+\s*:\s*([A-Z][A-Za-z0-9_]*)\s*,?\s*$")
# `name: proc(...)` field — we accept multi-line proc decls too by capturing
# only the field name and the leading `proc` keyword.
PROC_FIELD_RE = re.compile(r"^\s*([a-z_][a-z0-9_]*)\s*:\s*proc\b")
# Plain enum-typed field (data, not proc). We use this to catch the
# `kind: Change_Kind` discriminator pattern.
KIND_FIELD_RE = re.compile(r"^\s*kind\s*:\s*([A-Z][A-Za-z0-9_]*)\s*,?\s*$")

PROC_HDR_RE   = re.compile(r"^([a-zA-Z_][A-Za-z0-9_]*)\s*::\s*proc\b")
NEW_RETURN_RE = re.compile(r"->\s*\^?([A-Z][A-Za-z0-9_]*)")
NEW_LOCAL_RE  = re.compile(r"^\s*([a-z_][a-z0-9_]*)\s*:=\s*(?:new\(|([A-Z][A-Za-z0-9_]*)\s*\{)")
ENUM_HDR_RE   = re.compile(r"^([A-Z][A-Za-z0-9_]*)\s*::\s*enum\b")
ENUM_VAR_RE   = re.compile(r"^\s*([A-Z][A-Za-z0-9_]*)\s*,?\s*$")

# `self.start = ...`, `self.named_attachable.default_named.named.kind = ...`,
# `c.kind = .Foo`, etc. We capture (local_var, trailing_field_name) where
# `trailing_field_name` is the rightmost identifier on the LHS — `using`
# embedding flattens these into the same logical field on the parent.
ASSIGN_RE = re.compile(
    r"^\s*([a-z_][a-z0-9_]*)(?:\.[a-z_][a-z0-9_]*)*\.([a-z_][a-z0-9_]*)\s*=\s*"
)


def to_snake(name: str) -> str:
    """`PurchaseDelegate` -> `purchase_delegate`,
    `Change_Attachment_Change` -> `change_attachment_change`."""
    out = []
    for i, ch in enumerate(name):
        if ch == "_":
            out.append("_")
            continue
        if (ch.isupper() and i > 0
                and name[i - 1] != "_"
                and not name[i - 1].isupper()):
            out.append("_")
        out.append(ch.lower())
    return "".join(out)


def to_pascal(snake: str) -> str:
    return "".join(p.capitalize() for p in snake.split("_") if p)


class Struct:
    __slots__ = ("name", "file", "embeds", "proc_fields", "kind_enum")

    def __init__(self, name: str, file: pathlib.Path):
        self.name = name
        self.file = file
        self.embeds: list[str] = []
        self.proc_fields: set[str] = set()
        self.kind_enum: str | None = None  # enum type if struct has `kind: Foo` (data field, not proc)


def parse_odin_file(path: pathlib.Path) -> tuple[dict[str, Struct], dict[str, dict]]:
    """Returns (structs, constructors).

    `structs` maps Pascal_With_Underscores name -> Struct object.

    `constructors` maps proc name (e.g. `purchase_delegate_new`) ->
        { 'returns': '<StructType>',
          'assigned': set[str] of `<localvar>.<fieldname>` keys }
    where `<localvar>` is the variable bound to `new(<StructType>)`.
    """
    src = path.read_text(errors="replace").splitlines()
    structs: dict[str, Struct] = {}
    constructors: dict[str, dict] = {}
    enums: dict[str, set[str]] = {}

    i = 0
    n = len(src)
    while i < n:
        line = src[i]

        # ---- enum definition ----
        em = ENUM_HDR_RE.match(line)
        if em and "{" in line:
            ename = em.group(1)
            variants: set[str] = set()
            depth = line.count("{") - line.count("}")
            i += 1
            while i < n and depth > 0:
                body = src[i]
                depth += body.count("{") - body.count("}")
                vm = ENUM_VAR_RE.match(body)
                if vm:
                    variants.add(vm.group(1))
                i += 1
            enums[ename] = variants
            continue

        # ---- struct definition ----
        m = STRUCT_HDR_RE.match(line)
        if m and "{" in line:
            name = m.group(1)
            s = Struct(name, path)
            depth = line.count("{") - line.count("}")
            i += 1
            while i < n and depth > 0:
                body = src[i]
                depth += body.count("{") - body.count("}")
                um = USING_RE.match(body)
                if um:
                    s.embeds.append(um.group(1))
                pm = PROC_FIELD_RE.match(body)
                if pm:
                    s.proc_fields.add(pm.group(1))
                km = KIND_FIELD_RE.match(body)
                if km:
                    s.kind_enum = km.group(1)
                i += 1
            structs[name] = s
            continue

        # ---- proc definition ----
        pm = PROC_HDR_RE.match(line)
        if pm:
            proc_name = pm.group(1)
            # Accumulate the header lines until we hit `{` (body start).
            hdr = [line]
            j = i
            while "{" not in hdr[-1] and j + 1 < n:
                j += 1
                hdr.append(src[j])
            header_blob = "\n".join(hdr)
            ret_matches = NEW_RETURN_RE.findall(header_blob)
            ret_m = ret_matches[-1] if ret_matches else None

            if ("_new" in proc_name or proc_name.startswith("make_")) and ret_m:
                struct_type = ret_m
                # Walk the body looking for `local := new(<StructType>)`
                # OR `local := <StructType>{...}` (the value-constructor
                # convention used by `make_*` helpers), then any
                # `<local>.<field> = ...` assignments. We track the most
                # recent matching binding (most _new procs have one).
                local_var = None
                assigned: set[str] = set()
                depth = header_blob.count("{") - header_blob.count("}")
                k = j + 1
                while k < n and depth > 0:
                    body_line = src[k]
                    depth += body_line.count("{") - body_line.count("}")
                    nm = NEW_LOCAL_RE.match(body_line)
                    if nm:
                        # group(2) is set when matched the literal form
                        # `<local> := <Type>{...}`; otherwise the regex
                        # matched the `new(<Type>)` form and we need to
                        # extract the type via a follow-up search.
                        type_in_lit = nm.group(2)
                        if type_in_lit:
                            if type_in_lit == struct_type:
                                local_var = nm.group(1)
                        else:
                            mm = re.search(
                                r"new\(([A-Z][A-Za-z0-9_]*)\)", body_line,
                            )
                            if mm and mm.group(1) == struct_type:
                                local_var = nm.group(1)
                    am = ASSIGN_RE.match(body_line)
                    if am and local_var and am.group(1) == local_var:
                        assigned.add(am.group(2))
                    # Also accept assignments through `self` (the original
                    # convention before some constructors switched to the
                    # short local name).
                    if am and am.group(1) == "self":
                        assigned.add(am.group(2))
                    # Struct-literal wiring: `<field> = <val>,` inside a
                    # `Type{...}` literal (no `<local>.` prefix). Used by
                    # History_Node subclass constructors and others. We
                    # accept any bare `<ident> = ...,` line at any depth
                    # inside the proc body — false positives are
                    # harmless because we only check membership for a
                    # small set of known proc-fields/`kind`.
                    lit = re.match(
                        r"^\s*([a-z_][a-z0-9_]*)\s*=\s*[^=]",
                        body_line,
                    )
                    if lit:
                        assigned.add(lit.group(1))
                    k += 1
                constructors[proc_name] = {
                    "returns": struct_type,
                    "assigned": assigned,
                    "file": path,
                }
                i = k
                continue
            i = j + 1
            continue

        i += 1

    return structs, constructors, enums


# ---------------------------------------------------------------------------
# Cross-file resolution
# ---------------------------------------------------------------------------

def resolve_inherited_proc_fields(
    structs: dict[str, Struct],
) -> dict[str, dict[str, str]]:
    """For every struct, return {proc_field_name: declaring_struct}.

    Includes own proc-fields and every proc-field reachable through the
    transitive `using <embed>: <Parent>` chain. The declaring_struct is
    the closest ancestor that introduces the field.
    """
    resolved: dict[str, dict[str, str]] = {}

    def walk(name: str) -> dict[str, str]:
        if name in resolved:
            return resolved[name]
        s = structs.get(name)
        if s is None:
            resolved[name] = {}
            return resolved[name]
        # Seed self proc-fields (declared HERE).
        out: dict[str, str] = {f: name for f in s.proc_fields}
        # Inherit from each embedded parent (don't overwrite own decls).
        for parent in s.embeds:
            for fname, decl in walk(parent).items():
                out.setdefault(fname, decl)
        resolved[name] = out
        return out

    for name in list(structs):
        walk(name)
    return resolved


def resolve_kind_field(structs: dict[str, Struct]) -> dict[str, tuple[str, str]]:
    """For every struct, return {struct_name: (kind_enum_type,
    declaring_struct)} — only when SOME ancestor introduces a `kind:
    Enum` data field. Used to detect the `change_perform`-style
    discriminator-switch pattern.
    """
    out: dict[str, tuple[str, str]] = {}

    def walk(name: str) -> tuple[str, str] | None:
        if name in out:
            return out[name]
        s = structs.get(name)
        if s is None:
            return None
        if s.kind_enum:
            res = (s.kind_enum, name)
            out[name] = res
            return res
        for parent in s.embeds:
            r = walk(parent)
            if r is not None:
                out[name] = r
                return r
        return None

    for name in list(structs):
        walk(name)
    return out


# ---------------------------------------------------------------------------
# Main scan
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--commit", action="store_true",
                    help="write rows to port.sqlite (default is dry-run)")
    args = ap.parse_args()

    # ---- 1. Parse every odin_flat file ----
    all_structs: dict[str, Struct] = {}
    all_constructors: dict[str, dict] = {}
    all_enums: dict[str, set[str]] = {}
    all_procs: set[str] = set()
    files = sorted(ODIN_FLAT.glob("*.odin"))
    for f in files:
        try:
            structs, ctors, enums = parse_odin_file(f)
        except Exception as exc:
            print(f"warn: parse failed for {f.name}: {exc}", file=sys.stderr)
            continue
        for k, v in structs.items():
            if k in all_structs and all_structs[k].file != v.file:
                pass
            all_structs.setdefault(k, v)
        for k, v in ctors.items():
            all_constructors.setdefault(k, v)
        for k, v in enums.items():
            all_enums.setdefault(k, v)
        # Collect every top-level proc name in this file. Cheap separate
        # pass — we just need a global set for body-existence lookups.
        for line in f.read_text(errors="replace").splitlines():
            pm = PROC_HDR_RE.match(line)
            if pm:
                all_procs.add(pm.group(1))

    print(f"parsed {len(files)} files: "
          f"{len(all_structs)} structs, "
          f"{len(all_constructors)} *_new constructors")

    # ---- 2. Resolve inherited proc-fields per struct ----
    inherited = resolve_inherited_proc_fields(all_structs)
    kind_by_struct = resolve_kind_field(all_structs)

    # ---- 3. Read methods table to find Java @Overrides ----
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute(
        "SELECT method_key, owner_struct_key, odin_file_path FROM methods"
    )
    rows = cur.fetchall()

    # Map fq.OwnerJavaName -> Pascal_Underscore_Odin_Type. We compute the
    # Odin type from the simple Java name (last dotted segment, with
    # Inner$ stripped down to the last $-segment). Disambiguation table
    # for the few harness-overridden names lives in resume-prompt.md;
    # we don't replicate it here — they're not delegate types.
    def java_simple_to_odin(java_fq: str) -> str:
        simple = java_fq.split(".")[-1]
        # `Foo$Bar` -> `Bar` (we only care about the runtime simple name)
        if "$" in simple:
            simple = simple.split("$")[-1]
        # Insert underscores at camel boundaries.
        out = []
        for i, ch in enumerate(simple):
            if ch.isupper() and i > 0 and not simple[i - 1].isupper():
                out.append("_")
            out.append(ch)
        return "".join(out)

    METHOD_RE = re.compile(r"^proc:([\w\.\$]+)#([\w<>\$]+)\(")

    # struct_name -> set of method names (camelCase) defined in Java
    java_methods_by_struct: dict[str, set[str]] = {}
    java_methods_meta: dict[str, dict[str, str]] = {}   # struct -> { method: owner_struct_key }

    for method_key, owner_key, odin_file in rows:
        m = METHOD_RE.match(method_key)
        if not m:
            continue
        owner_fq, mname = m.group(1), m.group(2)
        if mname.startswith("<"):
            continue  # constructors don't override; tracked separately
        odin_type = java_simple_to_odin(owner_fq)
        java_methods_by_struct.setdefault(odin_type, set()).add(mname)
        java_methods_meta.setdefault(odin_type, {})[mname] = owner_key

    # ---- 4. Cross-reference: missing wirings ----
    findings: list[dict] = []
    seen_keys: set[tuple[str, str]] = set()

    for odin_type, struct in all_structs.items():
        # Constructor lookup: union assignments across every `*_new*`
        # proc that returns `^OdinType` (covers `foo_new`, `foo_new_2`,
        # `foo_new_canonical`, and any chain of delegating constructors).
        snake = to_snake(odin_type)
        ctors_for_type = [
            (cname, c) for cname, c in all_constructors.items()
            if c["returns"] == odin_type
        ]
        ctor_assigned: set[str] = set()
        for _, c in ctors_for_type:
            ctor_assigned |= c["assigned"]
        # Pick the canonical name for reporting: prefer `<snake>_new`
        # if it exists, otherwise the first matching constructor.
        ctor_name = f"{snake}_new"
        primary = next(
            (c for cname, c in ctors_for_type if cname == ctor_name),
            (ctors_for_type[0][1] if ctors_for_type else None),
        )
        ctor_file = primary["file"] if primary else struct.file

        own_proc_fields = struct.proc_fields
        all_pf = inherited.get(odin_type, {})
        # Parent-declared proc-fields (not introduced by this struct).
        parent_pf = {f: decl for f, decl in all_pf.items() if decl != odin_type}

        # 4a. Method-level overrides — Java has a `<methodCamel>` and
        # parent has a proc-field of the same snake_case name.
        camel_methods = java_methods_by_struct.get(odin_type, set())
        # Map snake -> camel for reverse lookup.
        snake_methods = {to_snake(m): m for m in camel_methods}

        for field_name, declaring in parent_pf.items():
            if field_name not in snake_methods:
                continue  # parent declares this proc-field but Java
                          # subclass doesn't override; legitimate skip
            # Only treat as a real override if the subclass's body proc
            # `<snake>_<field>` actually exists in odin_flat. Otherwise
            # the Java method is inherited (Lombok/javac-synthetic), the
            # parent's wiring already covers it, and no subclass wiring
            # is needed.
            body_proc = f"{snake}_{field_name}"
            if body_proc not in all_procs:
                continue
            wired = field_name in ctor_assigned
            status = "ok" if wired else "missing"
            key = (odin_type, field_name)
            if key in seen_keys:
                continue
            seen_keys.add(key)
            findings.append({
                "struct": odin_type,
                "field": field_name,
                "java_method": snake_methods[field_name],
                "parent_struct": declaring,
                "constructor": ctor_name,
                "status": status,
                "odin_file": str(ctor_file.relative_to(ROOT)) if ctor_file else None,
                "owner_struct_key": java_methods_meta.get(odin_type, {}).get(
                    snake_methods[field_name],
                ),
            })

        # 4b. `kind:` discriminator wiring — if SOME ancestor declares a
        # `kind: Enum` data field, this struct's constructor MUST assign
        # `self.kind = .<Variant>`. The expected variant name is
        # PascalCase of the snake `odin_type` itself (matching the enum
        # variant convention used by Change_Kind etc.).
        kind_info = kind_by_struct.get(odin_type)
        if kind_info and ctors_for_type:
            enum_type, enum_decl = kind_info
            variants = all_enums.get(enum_type, set())
            # Only flag if this struct is actually a leaf variant of the
            # discriminator enum. Intermediate base structs (Default_Named,
            # Named_Attachable, Tech_Advance subclasses with no variant,
            # etc.) are NOT switched on by name, so a missing assignment
            # is benign — the zero-init `.<First>` is fine.
            if odin_type in variants:
                wired = "kind" in ctor_assigned
                status = "ok" if wired else "missing_kind"
                key = (odin_type, "kind")
                if key not in seen_keys:
                    seen_keys.add(key)
                    findings.append({
                        "struct": odin_type,
                        "field": "kind",
                        "java_method": None,
                        "parent_struct": enum_decl,
                        "constructor": ctor_name,
                        "status": status,
                        "odin_file": str(ctor_file.relative_to(ROOT)) if ctor_file else None,
                        "owner_struct_key": None,
                    })

    # ---- 5. Summary buckets ----
    by_status = {"ok": 0, "missing": 0, "missing_kind": 0}
    samples: dict[str, list[dict]] = {"missing": [], "missing_kind": []}
    for f in findings:
        by_status[f["status"]] = by_status.get(f["status"], 0) + 1
        if f["status"] in samples and len(samples[f["status"]]) < 25:
            samples[f["status"]].append(f)

    report = {
        "scanned_at": datetime.now(timezone.utc).isoformat(),
        "files_scanned": len(files),
        "structs_total": len(all_structs),
        "constructors_total": len(all_constructors),
        "wirings_examined": len(findings),
        "by_status": by_status,
        "samples": samples,
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2))
    print(json.dumps({"by_status": by_status, "examined": len(findings)}, indent=2))

    # ---- 6. Persist to port.sqlite ----
    if args.commit:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS vtable_wiring (
                odin_struct_name TEXT NOT NULL,
                proc_field       TEXT NOT NULL,
                java_method      TEXT,
                parent_struct    TEXT,
                constructor      TEXT,
                status           TEXT NOT NULL,
                odin_file_path   TEXT,
                owner_struct_key TEXT,
                last_scanned     TEXT NOT NULL,
                PRIMARY KEY (odin_struct_name, proc_field)
            )
        """)
        ts = report["scanned_at"]
        cur.executemany("""
            INSERT INTO vtable_wiring
                (odin_struct_name, proc_field, java_method, parent_struct,
                 constructor, status, odin_file_path, owner_struct_key,
                 last_scanned)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (odin_struct_name, proc_field) DO UPDATE SET
                java_method      = excluded.java_method,
                parent_struct    = excluded.parent_struct,
                constructor      = excluded.constructor,
                status           = excluded.status,
                odin_file_path   = excluded.odin_file_path,
                owner_struct_key = excluded.owner_struct_key,
                last_scanned     = excluded.last_scanned
        """, [
            (
                f["struct"], f["field"], f["java_method"], f["parent_struct"],
                f["constructor"], f["status"], f["odin_file"],
                f["owner_struct_key"], ts,
            )
            for f in findings
        ])
        # Drop stale rows that the current scan no longer recognizes
        # (e.g. struct removed, or no longer matches a discriminator
        # variant after a scanner-rule change). Without this, fixed or
        # invalidated entries would forever read as missing*.
        current_keys = {(f["struct"], f["field"]) for f in findings}
        cur.execute("SELECT odin_struct_name, proc_field FROM vtable_wiring")
        stale = [k for k in cur.fetchall() if tuple(k) not in current_keys]
        if stale:
            cur.executemany(
                "DELETE FROM vtable_wiring "
                "WHERE odin_struct_name = ? AND proc_field = ?",
                stale,
            )
        conn.commit()
        print(f"committed {len(findings)} rows to vtable_wiring "
              f"(dropped {len(stale)} stale)")
    else:
        print("dry-run: pass --commit to write port.sqlite")
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
