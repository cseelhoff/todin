#!/usr/bin/env python3
"""Phase 2 of golden_testing_plan.md: parse the output of an `odin test`
run for the golden_* tests and update port.sqlite test_status + the
golden_fixtures table.

Promotion rules (per plan §6, decision #6):
  - For each method that produced a `[golden <proc>] pass=N fail=M skipped=K total=T` line:
      * If T == 0      → no fixtures replayed; leave test_status alone.
      * If M == 0      → green, note `golden: N/T pass (K skipped)`, test_tier='A'.
      * If M >  0      → red,   note `golden: N/T pass, M fail (K skipped)`, test_tier='A'.
  - Aggregate counts are also written back to every fixture row of that
    method (last_replay_status reflects the method's overall outcome —
    individual fixture-level pass/fail isn't surfaced by the Odin test
    runner today, so the aggregate is the best signal we have).

Usage:
    odin test ... 2>&1 | python3 scripts/record_replay_results.py
    python3 scripts/record_replay_results.py --from-file run.log
    python3 scripts/record_replay_results.py --dry-run < run.log
"""
from __future__ import annotations

import argparse
import datetime as _dt
import os
import re
import sqlite3
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_DB = os.path.join(os.path.dirname(_HERE), "port.sqlite")

LINE_RE = re.compile(
    r"\[golden\s+(?P<proc>[a-zA-Z0-9_]+)\]\s+pass=(?P<pass>\d+)\s+fail=(?P<fail>\d+)\s+skipped=(?P<skipped>\d+)\s+total=(?P<total>\d+)"
)


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _resolve_method_keys(con: sqlite3.Connection, proc_token: str) -> list[str]:
    """Find method_keys whose snake_cased class+method match `proc_token`.

    proc_token might be either:
      - 'estimate_power'                    (just the method)
      - 'pro_battle_utils_check_for_overwhelming_win'  (class_method)
    Match either against any method_key whose snake-cased class+#+method
    *ends with* the token.
    """
    rows = con.execute(
        "SELECT method_key, owner_struct_key FROM methods WHERE capture_state IN ('captured','generated')"
    ).fetchall()
    out = []
    target = proc_token

    def snake(s: str) -> str:
        # Same rules as scripts/gen_replay_tests.py — do NOT split runs of
        # digits-then-letters mid-word, so "WW2V2" -> "ww2_v2".
        s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
        s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
        return s.lower()

    for mk, osk in rows:
        # method_key: 'proc:<fqcn>#<name>(<sig>)'
        m = re.search(r"#([^(]+)\(", mk)
        if not m:
            continue
        method = m.group(1)
        klass = osk.removeprefix("struct:").rsplit(".", 1)[-1]
        snake_method = snake(method)
        snake_class  = snake(klass)
        candidates = [snake_method, f"{snake_class}_{snake_method}"]
        if target in candidates:
            out.append(mk)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--from-file", default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if args.from_file:
        with open(args.from_file) as f:
            text = f.read()
    else:
        text = sys.stdin.read()

    matches = list(LINE_RE.finditer(text))
    if not matches:
        print("no [golden ...] result lines found", file=sys.stderr)
        return 1

    con = sqlite3.connect(_DB)
    n_promoted = 0
    n_demoted  = 0
    for m in matches:
        proc = m.group("proc")
        np = int(m.group("pass"))
        nf = int(m.group("fail"))
        nk = int(m.group("skipped"))
        nt = int(m.group("total"))
        keys = _resolve_method_keys(con, proc)
        if not keys:
            print(f"  ?? unresolved proc token: {proc} ({np}/{nt})")
            continue
        if nt == 0:
            print(f"  - {proc}: 0 total — skipping")
            continue
        status = "green" if nf == 0 else "red"
        if nf == 0:
            note = f"golden: {np}/{nt} pass ({nk} skipped)"
        else:
            note = f"golden: {np}/{nt} pass, {nf} fail ({nk} skipped)"
        agg = "pass" if nf == 0 else "fail"
        for mk in keys:
            print(f"  {status:5} {mk}  | {note}")
            if args.dry_run:
                continue
            existing = con.execute(
                "SELECT status FROM test_status WHERE entity_key=?", (mk,)
            ).fetchone()
            if existing is None:
                con.execute(
                    "INSERT INTO test_status (entity_key, status, note, updated_at, test_tier) VALUES (?, ?, ?, ?, 'A')",
                    (mk, status, note, _now()),
                )
                n_promoted += 1 if status == "green" else 0
                n_demoted  += 1 if status == "red"   else 0
            else:
                con.execute(
                    "UPDATE test_status SET status=?, note=?, updated_at=?, test_tier='A' WHERE entity_key=?",
                    (status, note, _now(), mk),
                )
                if existing[0] != status:
                    if status == "green": n_promoted += 1
                    else:                 n_demoted  += 1
            # Aggregate update to every fixture of this method.
            con.execute(
                """UPDATE golden_fixtures
                   SET last_replay_status=?, last_replayed_at=?, last_replay_diff=?
                   WHERE method_key=?""",
                (agg, _now(), None if nf == 0 else f"{nf} method-level fail", mk),
            )
    if not args.dry_run:
        con.commit()
    print(f"\npromoted: {n_promoted}, demoted: {n_demoted}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
