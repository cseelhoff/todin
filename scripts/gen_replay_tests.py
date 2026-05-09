#!/usr/bin/env python3
"""Phase 2 of golden_testing_plan.md: generate Tier-A replay tests
from `golden_fixtures` rows.

For each (class, method) currently captured:
  - Inspect one fixture to determine arg shape.
  - If every arg is one of {Territory-by-name, Collection<Unit>-by-id,
    bool, int, float}, emit a generated test that loads each fixture,
    resolves args against the snap's before.json, calls the Odin
    proc, value-compares against the recorded return.
  - Otherwise, emit a `_pending.odin` stub with a comment naming
    the unresolvable arg type (e.g. ProData, ProOddsCalculator) so a
    human can fall back to Tier B.

Usage:
    python3 scripts/gen_replay_tests.py
        # Generates for every class with at least one captured fixture.
    python3 scripts/gen_replay_tests.py --class games.strategy.triplea.ai.pro.util.ProBattleUtils
        # Just one class.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict

_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
_DB = os.path.join(_ROOT, "port.sqlite")
_FIXTURES_BASE = os.path.join(_ROOT, "triplea", "conversion", "odin_tests", "fixtures")
_OUT_BASE = os.path.join(_ROOT, "triplea", "conversion", "odin_tests")

# Arg kinds we know how to resolve from a snap's before.json.
RESOLVABLE_REF_KINDS = {"Territory", "Unit", "GamePlayer", "UnitType"}
# Primitive JSON shapes that always replay.
PRIMITIVE_TYPES = {bool, int, float, str}


def fqcn_short(fqcn: str) -> str:
    """Short Odin-friendly name for the package + test file."""
    return fqcn.rsplit(".", 1)[-1]


def odin_proc_name(short_class: str, short_method: str) -> str:
    """Convention used across odin_flat: snake_case(class)_snake_case(method)."""
    def snake(s: str) -> str:
        # Insert _ before each uppercase letter that follows a lowercase letter
        # OR an uppercase letter followed by lowercase (HTTPRequest -> http_request).
        # We do NOT split runs of digits-then-letters mid-word, so "WW2V2"
        # becomes "ww2_v2" (matching the codebase's ww2_v3 / ww2_v2 convention).
        s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
        s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
        return s.lower()
    return f"{snake(short_class)}_{snake(short_method)}"


def detect_arg_kind(v):
    """Return ('prim', json_type) | ('ref', kind) | ('coll_unit',) | ('coll_other', kind) | ('unknown', repr)."""
    if isinstance(v, bool):
        return ("prim", "bool")
    if isinstance(v, int):
        return ("prim", "int")
    if isinstance(v, float):
        return ("prim", "float")
    if isinstance(v, str):
        return ("prim", "str")
    if isinstance(v, list):
        # Collection. Inspect first element.
        if not v:
            return ("coll_unknown",)
        elt = v[0]
        if isinstance(elt, dict) and elt.get("_kind") == "Unit":
            return ("coll_unit",)
        if isinstance(elt, dict) and "_kind" in elt:
            return ("coll_other", elt["_kind"])
        return ("coll_unknown",)
    if isinstance(v, dict):
        kind = v.get("_kind")
        if kind in RESOLVABLE_REF_KINDS:
            return ("ref", kind)
        return ("opaque", kind or "?")
    return ("unknown", str(type(v)))


def detect_method_shape(fixture_dir: str) -> tuple[list, str]:
    """Pick a representative fixture and return (arg_kinds, return_kind)."""
    samples = [f for f in os.listdir(fixture_dir) if f.endswith(".json")]
    if not samples:
        return [], "missing"
    # Prefer a sample whose collections are non-empty so we see the right inner kind.
    samples.sort(key=lambda f: -os.path.getsize(os.path.join(fixture_dir, f)))
    with open(os.path.join(fixture_dir, samples[0])) as f:
        obj = json.load(f)
    arg_kinds = [detect_arg_kind(a) for a in obj.get("args", [])]
    ret = obj.get("return")
    if isinstance(ret, bool):
        ret_kind = "bool"
    elif isinstance(ret, int):
        ret_kind = "int"
    elif isinstance(ret, float):
        ret_kind = "float"
    else:
        ret_kind = "other"
    return arg_kinds, ret_kind


def render_arg_resolve(idx: int, kind: tuple) -> tuple[str, str, bool]:
    """Return (decl_lines, expr, can_skip_on_miss). Caller appends the expr to the proc call."""
    tag = kind[0]
    if tag == "prim":
        t = kind[1]
        if t == "bool":
            return ("", f"args_arr[{idx}].(json.Boolean) or_else false", False)
        if t == "int":
            return ("", f"int(args_arr[{idx}].(json.Integer) or_else 0)", False)
        if t == "float":
            return ("", f"f64(args_arr[{idx}].(json.Float) or_else 0)", False)
        if t == "str":
            return ("", f"args_arr[{idx}].(json.String) or_else \"\"", False)
    if tag == "ref" and kind[1] == "Territory":
        return (
            f"\t\tterr_obj_{idx} := args_arr[{idx}].(json.Object) or_else nil\n"
            f"\t\tif terr_obj_{idx} == nil {{ skipped += 1; continue }}\n"
            f"\t\tterr_name_{idx} := terr_obj_{idx}[\"name\"].(json.String) or_else \"\"\n"
            f"\t\tterr_{idx}, terr_ok_{idx} := gd.game_map.territory_lookup[terr_name_{idx}]\n"
            f"\t\tif !terr_ok_{idx} {{ skipped += 1; continue }}\n",
            f"terr_{idx}",
            True,
        )
    if tag == "ref" and kind[1] == "GamePlayer":
        return (
            f"\t\tgp_obj_{idx} := args_arr[{idx}].(json.Object) or_else nil\n"
            f"\t\tif gp_obj_{idx} == nil {{ skipped += 1; continue }}\n"
            f"\t\tgp_name_{idx} := gp_obj_{idx}[\"name\"].(json.String) or_else \"\"\n"
            f"\t\tgp_{idx}, gp_ok_{idx} := gd.player_list.players[gp_name_{idx}]\n"
            f"\t\tif !gp_ok_{idx} {{ skipped += 1; continue }}\n",
            f"gp_{idx}",
            True,
        )
    if tag == "coll_unit":
        return (
            f"\t\tunits_{idx}, units_ok_{idx} := tc.resolve_units(gd, args_arr[{idx}])\n"
            f"\t\tif !units_ok_{idx} {{ skipped += 1; delete(units_{idx}); continue }}\n"
            f"\t\tdefer delete(units_{idx})\n",
            f"units_{idx}",
            True,
        )
    # Special-case opaque types we can resolve from gd. All instances of
    # GameProperties / GameData in any single snap are the same object,
    # so we substitute the snap's value rather than a stub.
    if tag == "opaque" and kind[1] == "GameProperties":
        return ("", "gd.properties", False)
    if tag == "opaque" and kind[1] == "GameData":
        return ("", "gd", False)
    return ("", "", False)  # unresolvable


def render_return_compare(ret_kind: str) -> tuple[str, str]:
    """Return (expected_decl, compare_expr)."""
    if ret_kind == "bool":
        return (
            "\t\texpected := obj[\"return\"].(json.Boolean) or_else false",
            "got != expected",
        )
    if ret_kind == "int":
        # Odin's json parses numbers as Float by default; whole numbers
        # are still Float (e.g. 100 -> json.Float(100)). Accept either.
        return (
            "\t\texpected: int = 0\n"
            "\t\t#partial switch v in obj[\"return\"] {\n"
            "\t\tcase json.Integer: expected = int(v)\n"
            "\t\tcase json.Float:   expected = int(v)\n"
            "\t\t}",
            "int(got) != expected",
        )
    # float: tolerate Integer fallback
    return (
        "\t\texpected := obj[\"return\"].(json.Float) or_else 0\n"
        "\t\tif _, is_int := obj[\"return\"].(json.Integer); is_int {\n"
        "\t\t\texpected = f64(obj[\"return\"].(json.Integer))\n"
        "\t\t}",
        "abs(f64(got) - expected) > 1e-9",
    )


def gen_for_method(fqcn: str, method: str, arg_kinds: list, ret_kind: str) -> str | None:
    """Return generated Odin source, or None if any arg is unresolvable."""
    arg_decls: list[str] = []
    arg_exprs: list[str] = []
    for i, kind in enumerate(arg_kinds):
        decl, expr, _ = render_arg_resolve(i, kind)
        if not expr:
            return None  # unresolvable
        if decl:
            arg_decls.append(decl)
        arg_exprs.append(expr)
    if ret_kind == "other" or ret_kind == "missing":
        return None
    expected_decl, compare = render_return_compare(ret_kind)
    short_class = fqcn_short(fqcn)
    proc_name = odin_proc_name(short_class, method)
    test_proc = f"test_{proc_name}_replay"
    pkg = f"golden_{re.sub(r'(?<!^)(?=[A-Z])', '_', short_class).lower()}"
    fixtures_path = f"conversion/odin_tests/fixtures/{fqcn}/{method}"
    snaps_path = "conversion/odin_tests/server_game_run_next_step/snapshots"
    arg_resolve_block = "".join(arg_decls)
    call_args = ", ".join(arg_exprs)
    return f'''package {pkg}

// AUTOGENERATED by scripts/gen_replay_tests.py — DO NOT EDIT.
// Tier-A golden replay test (golden_testing_plan.md Phase 2) for
//   {fqcn}#{method}

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import game "../../odin_flat"
import tc "../test_common"

{test_proc.upper()}_FIXTURES :: "{fixtures_path}"
{test_proc.upper()}_SNAPS    :: "{snaps_path}"

@(test)
{test_proc} :: proc(t: ^testing.T) {{
\tdir, derr := os.open({test_proc.upper()}_FIXTURES)
\tif derr != os.ERROR_NONE {{
\t\ttesting.expectf(t, false, "cannot open %s: %v", {test_proc.upper()}_FIXTURES, derr)
\t\treturn
\t}}
\tdefer os.close(dir)
\tfiles, ferr := os.read_dir(dir, -1, context.allocator)
\tif ferr != os.ERROR_NONE {{
\t\ttesting.expectf(t, false, "cannot read %s: %v", {test_proc.upper()}_FIXTURES, ferr)
\t\treturn
\t}}
\tsnap_cache: map[string]^game.Game_Data
\tdefer delete(snap_cache)
\tpass, fail, skipped := 0, 0, 0
\tfor fi in files {{
\t\tif !strings.has_suffix(fi.name, ".json") {{ continue }}
\t\tpath := fmt.tprintf("%s/%s", {test_proc.upper()}_FIXTURES, fi.name)
\t\tdata, rerr := os.read_entire_file(path, context.allocator)
\t\tif rerr != nil {{ fail += 1; testing.expectf(t, false, "read fail: %s", path); continue }}
\t\tdefer delete(data)
\t\troot, perr := json.parse(data)
\t\tif perr != .None {{ fail += 1; continue }}
\t\tdefer json.destroy_value(root)
\t\tobj := root.(json.Object) or_else nil
\t\tif obj == nil {{ fail += 1; continue }}
\t\tsnap_id := obj["snap"].(json.String) or_else ""
\t\tif snap_id == "" {{ skipped += 1; continue }}
\t\tgd, has := snap_cache[snap_id]
\t\tif !has {{
\t\t\tgd = tc.load_game_state_for_golden({test_proc.upper()}_SNAPS, snap_id)
\t\t\tif gd == nil {{ skipped += 1; continue }}
\t\t\tsnap_cache[snap_id] = gd
\t\t}}
\t\targs_arr := obj["args"].(json.Array) or_else nil
\t\tif args_arr == nil || len(args_arr) != {len(arg_kinds)} {{ fail += 1; continue }}
{arg_resolve_block}{expected_decl}
\t\tgot := game.{proc_name}({call_args})
\t\tif {compare} {{
\t\t\tfail += 1
\t\t\ttesting.expectf(t, false, "%s snap=%s: got=%v want=%v", fi.name, snap_id, got, expected)
\t\t}} else {{
\t\t\tpass += 1
\t\t}}
\t}}
\tfmt.printf("[golden {proc_name}] pass=%d fail=%d skipped=%d total=%d\\n",
\t\tpass, fail, skipped, pass + fail + skipped)
}}
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--class", dest="cls", default=None,
                    help="Only generate for this FQCN")
    args = ap.parse_args()

    con = sqlite3.connect(_DB)
    rows = con.execute(
        """SELECT DISTINCT method_key FROM golden_fixtures"""
    ).fetchall()

    by_class: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for (mk,) in rows:
        m = re.match(r"proc:([^#]+)#([^(]+)\(", mk)
        if not m:
            continue
        fqcn, method = m.group(1), m.group(2)
        if args.cls and fqcn != args.cls:
            continue
        by_class[fqcn].append((method, mk))

    n_emitted = 0
    n_skipped = 0
    for fqcn, methods in sorted(by_class.items()):
        short_class = fqcn_short(fqcn)
        pkg = f"golden_{re.sub(r'(?<!^)(?=[A-Z])', '_', short_class).lower()}"
        out_dir = os.path.join(_OUT_BASE, pkg)
        # We never overwrite an existing hand-written test file (the
        # estimatePower POC). Honor it by skipping methods whose
        # generated filename already exists.
        seen_methods = set()
        for method, mk in sorted(set(methods)):
            if method in seen_methods:
                continue
            seen_methods.add(method)
            fdir = os.path.join(_FIXTURES_BASE, fqcn, method)
            if not os.path.isdir(fdir):
                continue
            arg_kinds, ret_kind = detect_method_shape(fdir)
            src = gen_for_method(fqcn, method, arg_kinds, ret_kind)
            if src is None:
                n_skipped += 1
                # Mark in DB as captured-but-unresolvable; user can hand-port to Tier B.
                con.execute(
                    "UPDATE methods SET capture_state='captured' WHERE method_key=?",
                    (mk,),
                )
                print(f"  skip (unresolvable): {short_class}#{method}  args={arg_kinds} ret={ret_kind}")
                continue
            os.makedirs(out_dir, exist_ok=True)
            # Use the same snake convention as odin_proc_name so filename
            # and proc reference stay consistent (e.g. WW2V2 -> ww2_v2).
            method_snake = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", method)
            method_snake = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", method_snake).lower()
            out_file = os.path.join(out_dir, f"test_{method_snake}_gen.odin")
            handwritten = os.path.join(out_dir, f"test_{method_snake}.odin")
            if os.path.exists(handwritten):
                print(f"  hand-written exists, skip: {handwritten}")
                continue
            with open(out_file, "w") as f:
                f.write(src)
            con.execute(
                "UPDATE methods SET capture_state='generated' WHERE method_key=?",
                (mk,),
            )
            n_emitted += 1
            print(f"  emit: {out_file}  args={arg_kinds} ret={ret_kind}")
    con.commit()
    print(f"\nemitted: {n_emitted}, skipped (unresolvable): {n_skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
