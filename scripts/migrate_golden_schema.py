#!/usr/bin/env python3
"""Phase 0 of golden_testing_plan.md: idempotently add the
golden-testing schema to port.sqlite.

Adds:
  - table  golden_fixtures (+ 3 indexes)
  - column methods.capture_state TEXT (default 'skip')
  - column test_status.test_tier TEXT (nullable)

Backs up port.sqlite to port.sqlite.bak.golden-schema.<unixtime>
on the first run that actually mutates the schema.

Safe to re-run: every step is conditional on existence.
"""
from __future__ import annotations

import os
import shutil
import sqlite3
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
_DB = os.path.join(os.path.dirname(_HERE), "port.sqlite")


def _table_exists(con: sqlite3.Connection, name: str) -> bool:
    cur = con.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (name,)
    )
    return cur.fetchone() is not None


def _column_exists(con: sqlite3.Connection, table: str, column: str) -> bool:
    cur = con.execute(f"PRAGMA table_info({table})")
    return any(row[1] == column for row in cur.fetchall())


def _index_exists(con: sqlite3.Connection, name: str) -> bool:
    cur = con.execute(
        "SELECT 1 FROM sqlite_master WHERE type='index' AND name=?", (name,)
    )
    return cur.fetchone() is not None


def _backup_once(db_path: str) -> str | None:
    bak = f"{db_path}.bak.golden-schema.{int(time.time())}"
    if os.path.exists(bak):
        return None
    shutil.copy2(db_path, bak)
    return bak


def main() -> int:
    if not os.path.exists(_DB):
        print(f"ERROR: {_DB} not found", file=sys.stderr)
        return 2

    con = sqlite3.connect(_DB)
    con.execute("PRAGMA foreign_keys = ON")

    needs_change = (
        not _table_exists(con, "golden_fixtures")
        or not _column_exists(con, "methods", "capture_state")
        or not _column_exists(con, "test_status", "test_tier")
    )

    if needs_change:
        bak = _backup_once(_DB)
        if bak:
            print(f"backup: {bak}")

    if not _table_exists(con, "golden_fixtures"):
        con.execute(
            """
            CREATE TABLE golden_fixtures (
                fixture_id         TEXT    PRIMARY KEY,
                method_key         TEXT    NOT NULL,
                fixture_path       TEXT    NOT NULL,
                args_bytes         INTEGER NOT NULL,
                return_bytes       INTEGER NOT NULL,
                captured_from_snap TEXT,
                captured_at        TEXT    NOT NULL,
                last_replayed_at   TEXT,
                last_replay_ms     REAL,
                last_replay_status TEXT
                    CHECK(last_replay_status IN ('pass','fail','skip','unknown')),
                last_replay_diff   TEXT,
                FOREIGN KEY (method_key) REFERENCES methods(method_key)
            )
            """
        )
        print("created table golden_fixtures")

    for idx_name, idx_sql in [
        ("idx_gf_method", "CREATE INDEX idx_gf_method ON golden_fixtures(method_key)"),
        ("idx_gf_status", "CREATE INDEX idx_gf_status ON golden_fixtures(last_replay_status)"),
        ("idx_gf_snap",   "CREATE INDEX idx_gf_snap   ON golden_fixtures(captured_from_snap)"),
    ]:
        if not _index_exists(con, idx_name):
            con.execute(idx_sql)
            print(f"created index {idx_name}")

    if not _column_exists(con, "methods", "capture_state"):
        # SQLite ALTER TABLE ADD COLUMN cannot add a CHECK constraint
        # in-place; we enforce it via the application layer instead.
        con.execute(
            "ALTER TABLE methods ADD COLUMN capture_state TEXT DEFAULT 'skip'"
        )
        # Backfill any pre-existing rows so the column is never NULL.
        con.execute(
            "UPDATE methods SET capture_state='skip' WHERE capture_state IS NULL"
        )
        print("added methods.capture_state")

    if not _column_exists(con, "test_status", "test_tier"):
        con.execute("ALTER TABLE test_status ADD COLUMN test_tier TEXT")
        print("added test_status.test_tier")

    con.commit()

    # Final summary so re-runs print something useful too.
    cur = con.execute("SELECT COUNT(*) FROM golden_fixtures")
    print(f"golden_fixtures rows: {cur.fetchone()[0]}")
    cur = con.execute("PRAGMA table_info(methods)")
    cols = [r[1] for r in cur.fetchall()]
    print(f"methods columns: {cols}")
    cur = con.execute("PRAGMA table_info(test_status)")
    cols = [r[1] for r in cur.fetchall()]
    print(f"test_status columns: {cols}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
