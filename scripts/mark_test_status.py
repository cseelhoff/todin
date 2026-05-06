#!/usr/bin/env python3
"""Mark the test status of an entity in port.sqlite.

Usage:
    scripts/mark_test_status.py <entity_key> <green|red|yellow> [--note "..."]
    scripts/mark_test_status.py --list [red|yellow|green]
    scripts/mark_test_status.py --summary

Status semantics (drill-down doctrine):
    green  = entity is covered by tests AND those tests pass.
    red    = entity has failing tests OR is the known cause of a downstream failure.
    yellow = untested / unknown (default for any entity not yet visited).

Drill-down workflow (enforced by scripts/next_task.py):
    1. The picker chooses the deepest red proc.
    2. Yellow children of that red are UNCLASSIFIED, not "the bug."
       You MUST evaluate every yellow sibling (write a targeted test,
       mark green or red) before drilling.  Order does not matter, but
       all yellow siblings must be classified first.
    3. If any sibling came back red, drill into the deepest such red
       on the next picker iteration.  If every sibling came back green,
       the picker pops up to INVESTIGATE_PROC on the parent red — the
       bug is in its own body.
    4. Never drill into a yellow node directly (it might be perfectly
       fine and waste an iteration); always classify it red first.

`entity_key` is the exact `primary_key` value from the `entities` table
(e.g. `proc:games.strategy.engine.framework.ServerGame#runNextStep()` or
`struct:games.strategy.triplea.delegate.battle.BattleDelegate`).
"""
from __future__ import annotations

import argparse
import datetime as _dt
import os
import sqlite3
import sys

_DB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "port.sqlite")


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _ensure_table(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS test_status (
            entity_key  TEXT PRIMARY KEY,
            status      TEXT NOT NULL DEFAULT 'yellow'
                        CHECK(status IN ('green','red','yellow')),
            note        TEXT,
            updated_at  TEXT NOT NULL
        )
        """
    )
    conn.execute("CREATE INDEX IF NOT EXISTS idx_test_status_status ON test_status(status)")


def cmd_set(args: argparse.Namespace) -> int:
    if args.status not in ("green", "red", "yellow"):
        print(f"error: status must be green|red|yellow, got {args.status!r}", file=sys.stderr)
        return 2
    conn = sqlite3.connect(_DB)
    _ensure_table(conn)
    row = conn.execute(
        "SELECT 1 FROM entities WHERE primary_key = ?", (args.entity_key,)
    ).fetchone()
    if row is None and not args.force:
        print(f"error: no entity with primary_key={args.entity_key!r} (use --force to record anyway)", file=sys.stderr)
        return 1
    # Invariant guard: refuse to mark a proc green when it transitively
    # calls a red proc.  See scripts/validate_test_status.py for the
    # full doctrine.  This catches the most common drill-down mistake:
    # marking a dispatcher / wrapper green based on a routing test
    # while its callee is still red.
    if args.status == "green" and not args.force:
        offender = _find_red_descendant_for_guard(conn, args.entity_key)
        if offender is not None:
            print(
                f"error: refusing to mark {args.entity_key!r} green — it "
                f"transitively calls a red proc:\n"
                f"    red descendant: {offender}\n"
                f"Either fix the descendant first, or pass --force if you "
                f"have audited that the test really does cover this proc's "
                f"behaviour despite the red below it.",
                file=sys.stderr,
            )
            return 3
    conn.execute(
        """
        INSERT INTO test_status(entity_key, status, note, updated_at)
        VALUES(?, ?, ?, ?)
        ON CONFLICT(entity_key) DO UPDATE SET
            status = excluded.status,
            note = excluded.note,
            updated_at = excluded.updated_at
        """,
        (args.entity_key, args.status, args.note, _now()),
    )
    conn.commit()
    print(f"{args.status:>6}  {args.entity_key}")
    if args.note:
        print(f"        note: {args.note}")
    return 0


def _find_red_descendant_for_guard(conn: sqlite3.Connection, start: str) -> str | None:
    """Lightweight BFS on the call graph; returns the first red descendant.

    Mirrors `validate_test_status.py::_find_red_descendant` but inlined
    here so the helper script stays single-file (no cross-imports).
    """
    status = {
        row[0]: row[1]
        for row in conn.execute("SELECT entity_key, status FROM test_status")
    }
    visited: set[str] = {start}
    frontier: list[str] = [start]
    depth = 0
    while frontier and depth < 64:
        if not frontier:
            break
        ph = ",".join("?" * len(frontier))
        rows = list(conn.execute(
            f"""SELECT DISTINCT depends_on_key FROM dependencies
                WHERE primary_key IN ({ph})
                  AND edge_kind IN ('static','virtual','override')""",
            frontier,
        ))
        next_frontier: list[str] = []
        for row in rows:
            child = row[0]
            if child in visited:
                continue
            visited.add(child)
            if status.get(child) == "red":
                return child
            next_frontier.append(child)
            if len(visited) > 50000:
                return None
        frontier = next_frontier
        depth += 1
    return None


def cmd_list(args: argparse.Namespace) -> int:
    conn = sqlite3.connect(_DB)
    _ensure_table(conn)
    if args.status:
        rows = conn.execute(
            "SELECT entity_key, status, note, updated_at FROM test_status WHERE status = ? ORDER BY updated_at DESC",
            (args.status,),
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT entity_key, status, note, updated_at FROM test_status ORDER BY status, updated_at DESC"
        ).fetchall()
    for entity_key, status, note, updated_at in rows:
        suffix = f"  -- {note}" if note else ""
        print(f"{status:>6}  {updated_at}  {entity_key}{suffix}")
    print(f"-- {len(rows)} row(s)")
    return 0


def cmd_summary(_: argparse.Namespace) -> int:
    conn = sqlite3.connect(_DB)
    _ensure_table(conn)
    counts = dict(conn.execute("SELECT status, COUNT(*) FROM test_status GROUP BY status").fetchall())
    total = sum(counts.values())
    for color in ("green", "red", "yellow"):
        print(f"{color:>6}: {counts.get(color, 0)}")
    print(f" total: {total}")
    return 0


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd")

    s = sub.add_parser("set", help="Set the status of an entity (default subcommand).")
    s.add_argument("entity_key")
    s.add_argument("status", choices=["green", "red", "yellow"])
    s.add_argument("--note", default=None)
    s.add_argument("--force", action="store_true",
                   help="Record even when the entity is missing from the entities table.")
    s.set_defaults(func=cmd_set)

    l = sub.add_parser("list", help="List entities with a given status (or all).")
    l.add_argument("status", nargs="?", choices=["green", "red", "yellow"])
    l.set_defaults(func=cmd_list)

    sm = sub.add_parser("summary", help="Print counts per status.")
    sm.set_defaults(func=cmd_summary)

    # Convenience: positional `mark_test_status.py KEY STATUS` defaults to set.
    if len(argv) >= 2 and argv[0] not in ("set", "list", "summary", "-h", "--help") \
            and not argv[0].startswith("-"):
        argv = ["set"] + argv

    args = p.parse_args(argv)
    if not getattr(args, "func", None):
        p.print_help()
        return 2
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
