#!/usr/bin/env python3
"""
Scan odin_flat/ for procs that take `map[K]V` parameters by VALUE and mutate
them inside the body. These are the silent-corruption bug sites: Odin maps
are passed by value (header copy), so callee inserts/deletes are invisible
to the caller AND lookups short-circuit on stale len==0. The fix is to
promote the param to `^map[K]V` and pass `&map` at every call site.

See llm-instructions.md §"Map parameter-passing" and map_repro/ for the
worked counter-example.

Usage:
    python3 scripts/scan_map_by_value.py            # writes map_by_value_report.json
    python3 scripts/scan_map_by_value.py --verbose  # also prints summary

Output JSON shape:
    {
      "summary": {"files_scanned": N, "procs_with_map_params": N,
                  "procs_with_mutated_value_maps": N, "total_hits": N},
      "hits": [
        {
          "file": "odin_flat/...odin",
          "proc": "foo_bar",
          "proc_line": 123,
          "param": "move_map",
          "param_type": "map[^Territory]^Pro_Territory",
          "shadow_line": 125,           # null if no `m := m` shadow seen
          "mutations": [
            {"line": 130, "kind": "insert", "snippet": "move_map[t] = created"},
            {"line": 135, "kind": "delete_key", "snippet": "delete_key(&move_map, k)"}
          ]
        },
        ...
      ]
    }
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ODIN_FLAT = ROOT / "odin_flat"

# Match `proc_name :: proc(...)` declarations. Captures name + the full
# signature including return type up to the opening `{`.
PROC_DECL_RE = re.compile(
    r"^(?P<name>[a-zA-Z_][a-zA-Z0-9_]*)\s*::\s*proc\b",
    re.MULTILINE,
)

# A map-typed parameter inside a proc signature, e.g. `move_map: map[^T]^V`.
# We match the parameter NAME and its TYPE. Negative lookahead on `^map` /
# `^[\s]*map` rules out pointer-to-map (the correct form).
PARAM_MAP_RE = re.compile(
    r"(?<![a-zA-Z0-9_])"
    r"(?P<name>[a-zA-Z_][a-zA-Z0-9_]*)"
    r"\s*:\s*"
    r"(?P<type>map\s*\[[^\]]+\][^,)\n]+)"
)

# Detect the `name := name` shadow trick that the AI port uses to silence
# Odin's "cannot assign to value of map" compile error. This is a marker of
# the bug — the shadow makes the bare-map-by-value code compile but does
# not fix the semantic problem.
def shadow_re(name: str) -> re.Pattern:
    return re.compile(rf"^\s*{re.escape(name)}\s*:=\s*{re.escape(name)}\s*$", re.MULTILINE)


def mutation_patterns(name: str):
    """Return list of (kind, regex) tuples for mutation detection."""
    n = re.escape(name)
    return [
        # Insert/overwrite: name[expr] = ...    (NOT name[expr] == ...)
        ("insert", re.compile(rf"(?<![a-zA-Z0-9_]){n}\s*\[[^\]]+\]\s*=(?!=)")),
        # delete_key(name, ...) or delete_key(&name, ...)
        ("delete_key", re.compile(rf"\bdelete_key\s*\(\s*&?\s*{n}\b")),
        # clear(name) / clear(&name) (Odin builtin works on map by ptr)
        ("clear", re.compile(rf"\bclear\s*\(\s*&?\s*{n}\s*\)")),
        # Re-assign the local: name = make(...) — usually means the proc
        # is treating the param like an out-param via the shadow trick.
        ("reassign", re.compile(rf"^\s*{n}\s*=\s*make\b", re.MULTILINE)),
    ]


def find_proc_body(text: str, proc_open: int) -> tuple[int, int]:
    """Given offset of a `proc` keyword, find the body's `{`..`}` range.
    Returns (open_brace_offset, close_brace_offset). Skips over the
    parameter list and return-type, then brace-matches the body."""
    # Walk forward looking for the opening `{` of the body. Track paren
    # depth so we don't trip on `(` inside the signature.
    paren = 0
    i = proc_open
    while i < len(text):
        c = text[i]
        if c == "(":
            paren += 1
        elif c == ")":
            paren -= 1
        elif c == "{" and paren == 0:
            break
        elif c == "/" and i + 1 < len(text) and text[i + 1] == "/":
            # line comment
            nl = text.find("\n", i)
            if nl == -1:
                return -1, -1
            i = nl
        i += 1
    if i >= len(text):
        return -1, -1
    open_brace = i
    depth = 1
    i += 1
    while i < len(text) and depth > 0:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif c == "/" and i + 1 < len(text) and text[i + 1] == "/":
            nl = text.find("\n", i)
            if nl == -1:
                return -1, -1
            i = nl
            continue
        elif c in ('"', '`'):
            # skip string literal (don't worry about escapes — false-pos OK)
            quote = c
            i += 1
            while i < len(text) and text[i] != quote:
                if text[i] == "\\" and quote == '"':
                    i += 1
                i += 1
        i += 1
    if depth != 0:
        return open_brace, -1
    return open_brace, i  # i is one past the closing `}`


def signature_text(text: str, proc_kw_offset: int) -> tuple[str, int]:
    """Return the signature substring `proc(...) -> ...` up to the body
    `{`, plus the offset of that `{`."""
    paren = 0
    i = proc_kw_offset
    start = i
    while i < len(text):
        c = text[i]
        if c == "(":
            paren += 1
        elif c == ")":
            paren -= 1
        elif c == "{" and paren == 0:
            return text[start:i], i
        i += 1
    return text[start:], -1


def line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def scan_file(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="replace")
    hits: list[dict] = []
    for m in PROC_DECL_RE.finditer(text):
        proc_name = m.group("name")
        proc_kw = m.end() - len("proc")
        sig, brace_off = signature_text(text, proc_kw)
        if brace_off < 0:
            continue  # forward decl, no body
        body_open, body_close = find_proc_body(text, proc_kw)
        if body_close < 0:
            continue
        body = text[body_open + 1 : body_close - 1]
        body_start_line = line_of(text, body_open)

        # Find every bare-map parameter in the signature.
        for pm in PARAM_MAP_RE.finditer(sig):
            param = pm.group("name")
            ptype = pm.group("type").strip().rstrip(",").rstrip(")")
            # Sanity-skip if the matched span is actually preceded by `^`
            # (would mean `^map[K]V`, not `map[K]V`).
            type_start = pm.start("type")
            # Step back past whitespace/colon to check for `^`
            j = type_start - 1
            while j >= 0 and sig[j].isspace():
                j -= 1
            if j >= 0 and sig[j] == "^":
                continue

            # Look for shadow `param := param`
            sh = shadow_re(param).search(body)
            shadow_line = line_of(text, body_open + 1 + sh.start()) if sh else None

            mutations = []
            for kind, mut_re in mutation_patterns(param):
                for mm in mut_re.finditer(body):
                    line = line_of(text, body_open + 1 + mm.start())
                    # snippet: containing line
                    line_start = body.rfind("\n", 0, mm.start()) + 1
                    line_end = body.find("\n", mm.end())
                    if line_end < 0:
                        line_end = len(body)
                    snippet = body[line_start:line_end].strip()
                    mutations.append({"line": line, "kind": kind, "snippet": snippet[:200]})

            if mutations or shadow_line is not None:
                hits.append({
                    "file": str(path.relative_to(ROOT)),
                    "proc": proc_name,
                    "proc_line": line_of(text, m.start()),
                    "param": param,
                    "param_type": ptype,
                    "shadow_line": shadow_line,
                    "mutations": mutations,
                })
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--out", default=str(ROOT / "map_by_value_report.json"))
    args = ap.parse_args()

    odin_files = sorted(ODIN_FLAT.rglob("*.odin"))
    all_hits = []
    procs_with_map_params = 0  # informational
    for p in odin_files:
        all_hits.extend(scan_file(p))

    # Tally distinct procs with bare-map params (whether mutated or not)
    # by re-scanning signatures only (cheap second pass).
    seen_procs = set()
    for p in odin_files:
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in PROC_DECL_RE.finditer(text):
            sig, brace_off = signature_text(text, m.end() - len("proc"))
            if brace_off < 0:
                continue
            for pm in PARAM_MAP_RE.finditer(sig):
                type_start = pm.start("type")
                j = type_start - 1
                while j >= 0 and sig[j].isspace():
                    j -= 1
                if j >= 0 and sig[j] == "^":
                    continue
                seen_procs.add((str(p), m.group("name")))
                break
    procs_with_map_params = len(seen_procs)

    summary = {
        "files_scanned": len(odin_files),
        "procs_with_bare_map_params": procs_with_map_params,
        "procs_with_mutated_value_maps": len(all_hits),
        "total_mutation_hits": sum(len(h["mutations"]) for h in all_hits),
        "shadow_pattern_count": sum(1 for h in all_hits if h["shadow_line"] is not None),
    }

    out = {"summary": summary, "hits": all_hits}
    Path(args.out).write_text(json.dumps(out, indent=2))

    print(f"summary: {json.dumps(summary)}")
    print(f"report : {args.out}")
    if args.verbose:
        # Top 10 files by hit count
        from collections import Counter
        fc = Counter(h["file"] for h in all_hits)
        print("\ntop files by mutation-hit count:")
        for f, n in fc.most_common(10):
            print(f"  {n:4d}  {f}")


if __name__ == "__main__":
    main()
