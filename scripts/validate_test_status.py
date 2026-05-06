#!/usr/bin/env python3
"""Validate the colour invariant on `test_status` and (optionally) fix it.

INVARIANT
---------
A proc may be marked **green** only if every one of its transitive
call-graph descendants is also green (or absent / leaf with no recorded
deps).  In particular: **no green proc may transitively call a red
proc.**  If a parent's tests pass but a callee's tests fail, the
parent's tests are missing behaviour coverage — they're exercising
dispatch routing or a happy path that doesn't reach the broken
callee.  In that situation the parent must be at most **yellow**
("untested for the relevant behaviour"), never green.

Yellow→red is permitted but uncommon — yellow means "untested",
which is a valid honest state for a parent of a red proc when no
targeted test has been written yet.  This validator does NOT touch
yellow nodes.

Red→anything is fine; a red parent can have green or yellow children.

USAGE
-----
    # Show violations only (read-only):
    python3 scripts/validate_test_status.py

    # Demote every offending green to yellow (with an audit note):
    python3 scripts/validate_test_status.py --fix

    # Emit JSON for the dashboard / tooling:
    python3 scripts/validate_test_status.py --json

ALGORITHM
---------
For every green proc G:
  1. Walk the call graph from G via dependencies (edge_kind ∈
     {static, virtual, override}).
  2. If we reach any red proc, G violates the invariant.
  3. Record the offending green and the first red descendant we
     found (used as the audit note when --fix demotes G to yellow).

Both call-graph fan-out and depth are bounded; we cap visited at
50000 / depth at 64 to defend against pathological cycles.  The
script is read-only without `--fix`.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import sqlite3
import sys

_DB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "port.sqlite")
_CALL_EDGES = ("static", "virtual", "override")


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _open() -> sqlite3.Connection:
    conn = sqlite3.connect(_DB)
    conn.row_factory = sqlite3.Row
    return conn


def _load_status(conn: sqlite3.Connection) -> dict[str, str]:
    return {
        row["entity_key"]: row["status"]
        for row in conn.execute("SELECT entity_key, status FROM test_status")
    }


def _build_callgraph(conn: sqlite3.Connection) -> dict[str, list[str]]:
    """parent_key -> list of callee keys (call edges only)."""
    g: dict[str, list[str]] = {}
    for row in conn.execute(
        f"""SELECT primary_key, depends_on_key
            FROM dependencies
            WHERE edge_kind IN ({",".join("?" * len(_CALL_EDGES))})""",
        _CALL_EDGES,
    ):
        g.setdefault(row["primary_key"], []).append(row["depends_on_key"])
    return g


def _find_red_descendant(
    start: str,
    graph: dict[str, list[str]],
    status: dict[str, str],
    cap_visited: int = 50000,
    cap_depth: int = 64,
) -> str | None:
    """Return the first red descendant reachable from `start`, else None."""
    visited: set[str] = {start}
    # depth-tracked frontier; BFS so the returned descendant tends
    # to be the closest red, which makes the audit note useful.
    frontier: list[tuple[str, int]] = [(start, 0)]
    while frontier:
        node, depth = frontier.pop(0)
        if depth >= cap_depth:
            continue
        for child in graph.get(node, ()):  # noqa: B007 — explicit for clarity
            if child in visited:
                continue
            visited.add(child)
            if status.get(child) == "red":
                return child
            frontier.append((child, depth + 1))
            if len(visited) > cap_visited:
                return None
    return None


def find_violations(conn: sqlite3.Connection) -> list[dict]:
    status = _load_status(conn)
    graph = _build_callgraph(conn)
    out: list[dict] = []
    for key, st in status.items():
        if st != "green":
            continue
        red = _find_red_descendant(key, graph, status)
        if red is not None:
            out.append({"green": key, "red_descendant": red})
    out.sort(key=lambda v: v["green"])
    return out


def fix_violations(conn: sqlite3.Connection, violations: list[dict]) -> int:
    """Demote each offending green to yellow with an audit note."""
    if not violations:
        return 0
    now = _now()
    cur = conn.cursor()
    for v in violations:
        cur.execute(
            """UPDATE test_status
               SET status = 'yellow',
                   note = COALESCE(note || ' | ', '')
                          || 'auto-demoted: green parent of red descendant '
                          || ?,
                   updated_at = ?
               WHERE entity_key = ? AND status = 'green'""",
            (v["red_descendant"], now, v["green"]),
        )
    conn.commit()
    return len(violations)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--fix", action="store_true",
                  help="Demote every offending green to yellow.")
    p.add_argument("--json", action="store_true",
                  help="Emit machine-readable JSON.")
    args = p.parse_args(argv)

    if not os.path.isfile(_DB):
        print(f"error: db not found at {_DB}", file=sys.stderr)
        return 1
    conn = _open()
    try:
        violations = find_violations(conn)
        if args.fix:
            n = fix_violations(conn, violations)
            if args.json:
                print(json.dumps({"fixed": n, "violations": violations}, indent=2))
            else:
                if n:
                    for v in violations:
                        print(f"  fixed: {v['green']}")
                        print(f"      red descendant: {v['red_descendant']}")
                    print(f"-- demoted {n} green proc(s) to yellow")
                else:
                    print("no violations to fix; invariant holds")
            return 0

        if args.json:
            print(json.dumps({"violations": violations}, indent=2))
            return 0
        if not violations:
            print("invariant holds: no green proc transitively calls a red proc")
            return 0
        print(f"INVARIANT VIOLATIONS — {len(violations)} green proc(s) transitively call a red:")
        for v in violations:
            print(f"  green: {v['green']}")
            print(f"      → red descendant: {v['red_descendant']}")
        print()
        print("Re-run with --fix to demote them to yellow.")
        return 2
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
