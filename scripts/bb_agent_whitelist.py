#!/usr/bin/env python3
"""Manage the Byte Buddy agent's class whitelist (golden_testing_plan.md
Phase 1).

Usage:
    scripts/bb_agent_whitelist.py --list
    scripts/bb_agent_whitelist.py --add  <class FQCN> [<class FQCN> ...]
    scripts/bb_agent_whitelist.py --remove <class FQCN>
    scripts/bb_agent_whitelist.py --suggest [--limit 10]
        # data-driven priority queue: classes in port.sqlite that have
        # impl & called methods with NO golden_fixtures rows yet.

Side effect on --add: marks every implemented, non-abstract,
non-test-harness method on those classes as
``methods.capture_state='queued'`` so the dashboard knows they're
expected to produce fixtures on the next Java run.
"""
from __future__ import annotations

import argparse
import os
import sqlite3
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_DB = os.path.join(os.path.dirname(_HERE), "port.sqlite")
_WHITELIST = os.path.join(
    os.path.dirname(_HERE),
    "triplea", "conversion", "proc-recorder-agent", "agent.whitelist",
)

_HEADER = (
    "# Tier-A capture whitelist (golden_testing_plan.md).\n"
    "# One fully-qualified class name per line. # comments allowed.\n"
    "# Managed by scripts/bb_agent_whitelist.py.\n"
)


def _read() -> list[str]:
    if not os.path.exists(_WHITELIST):
        return []
    with open(_WHITELIST) as f:
        return [
            ln.strip() for ln in f
            if ln.strip() and not ln.strip().startswith("#")
        ]


def _write(classes: list[str]) -> None:
    classes = sorted(set(classes))
    with open(_WHITELIST, "w") as f:
        f.write(_HEADER)
        for c in classes:
            f.write(c + "\n")


def _mark_queued(con: sqlite3.Connection, fqcns: list[str]) -> int:
    n = 0
    for fqcn in fqcns:
        struct_key = "struct:" + fqcn
        cur = con.execute(
            """UPDATE methods
               SET capture_state='queued'
               WHERE owner_struct_key=?
                 AND is_implemented=1
                 AND is_abstract=0
                 AND is_test_harness=0
                 AND (capture_state IS NULL OR capture_state IN ('skip','queued'))""",
            (struct_key,),
        )
        n += cur.rowcount
    con.commit()
    return n


def cmd_list(_args) -> int:
    for c in _read():
        print(c)
    return 0


def cmd_add(args) -> int:
    cur = _read()
    cur_set = set(cur)
    added = [c for c in args.classes if c not in cur_set]
    cur.extend(args.classes)
    _write(cur)

    con = sqlite3.connect(_DB)
    n = _mark_queued(con, args.classes)
    con.close()

    print(f"added {len(added)} new class(es); whitelist now has {len(set(cur))} entries")
    print(f"queued {n} method(s) in port.sqlite")
    return 0


def cmd_remove(args) -> int:
    cur = _read()
    new = [c for c in cur if c != args.class_fqcn]
    _write(new)
    print(f"removed {args.class_fqcn}; whitelist now has {len(set(new))} entries")
    return 0


def cmd_suggest(args) -> int:
    con = sqlite3.connect(_DB)
    rows = con.execute("""
        SELECT
            substr(m.owner_struct_key, 8) AS fqcn,
            COUNT(*) AS impl_methods,
            SUM(CASE WHEN gf.fixture_id IS NOT NULL THEN 1 ELSE 0 END) AS with_fixtures
        FROM methods m
        JOIN entities e ON e.primary_key = m.method_key
        LEFT JOIN golden_fixtures gf ON gf.method_key = m.method_key
        WHERE m.is_implemented=1
          AND m.is_abstract=0
          AND m.is_test_harness=0
          AND e.actually_called_in_ai_test=1
        GROUP BY fqcn
        HAVING with_fixtures = 0 AND impl_methods >= 3
        ORDER BY impl_methods DESC
        LIMIT ?
    """, (args.limit,)).fetchall()
    con.close()
    print(f"{'class':<70} {'impl':>5}")
    for fqcn, impl, _ in rows:
        print(f"{fqcn:<70} {impl:>5}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Manage the proc-recorder agent whitelist."
    )
    sp = ap.add_subparsers(dest="cmd", required=True)
    sp.add_parser("list")
    sp_add = sp.add_parser("add")
    sp_add.add_argument("classes", nargs="+")
    sp_rm = sp.add_parser("remove")
    sp_rm.add_argument("class_fqcn")
    sp_sg = sp.add_parser("suggest")
    sp_sg.add_argument("--limit", type=int, default=10)

    # Accept legacy "--list / --add" forms by stripping the leading dashes.
    if len(sys.argv) >= 2 and sys.argv[1].startswith("--") and sys.argv[1] != "--help":
        sys.argv[1] = sys.argv[1][2:]

    args = ap.parse_args()
    if args.cmd == "list":
        return cmd_list(args)
    if args.cmd == "add":
        return cmd_add(args)
    if args.cmd == "remove":
        return cmd_remove(args)
    if args.cmd == "suggest":
        return cmd_suggest(args)
    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
