#!/usr/bin/env python3
"""Phase 1 of golden_testing_plan.md: walk the proc-recorder agent's
output dir, copy fixtures into the in-tree fixtures path, and populate
``golden_fixtures`` rows in port.sqlite.

Default source:  triplea/game-app/smoke-testing/build/golden_fixtures/
Default dest:    triplea/conversion/odin_tests/fixtures/

Layout under the source/dest is identical:
    <FQCN>/<method>/<args-sha256>.json

For each file copied:
  - row in golden_fixtures keyed by  fixture_id = "<FQCN>#<method>::<sha>"
  - method_key resolved via owner_struct_key='struct:<FQCN>' AND method_name=<method>
  - methods.capture_state set to 'captured' for the resolved method_key

Note: <method> in the directory name is the *short* method name (e.g.
``estimatePower``) without parameter signature. Java overloads share a
directory; the args content + sha disambiguates them. We resolve to the
specific method_key by matching on owner+name and, if multiple matches,
recording one row per overload candidate so replay can pick by arity.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import shutil
import sqlite3
import sys
from typing import Iterable

_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
_DB = os.path.join(_ROOT, "port.sqlite")
_DEFAULT_SRC = os.path.join(
    _ROOT, "triplea", "game-app", "smoke-testing", "build", "golden_fixtures"
)
_DEFAULT_DEST = os.path.join(
    _ROOT, "triplea", "conversion", "odin_tests", "fixtures"
)


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _walk_fixtures(src: str) -> Iterable[tuple[str, str, str, str]]:
    """Yield (fqcn, method_short, sha, abs_path) for every *.json under src."""
    if not os.path.isdir(src):
        return
    for fqcn in sorted(os.listdir(src)):
        cls_dir = os.path.join(src, fqcn)
        if not os.path.isdir(cls_dir):
            continue
        for method in sorted(os.listdir(cls_dir)):
            m_dir = os.path.join(cls_dir, method)
            if not os.path.isdir(m_dir):
                continue
            for f in sorted(os.listdir(m_dir)):
                if not f.endswith(".json"):
                    continue
                sha = f[:-5]
                yield fqcn, method, sha, os.path.join(m_dir, f)


def _resolve_method_keys(con: sqlite3.Connection, fqcn: str, method: str) -> list[str]:
    """Find all method_keys under struct:<fqcn> whose short name matches."""
    struct_key = "struct:" + fqcn
    rows = con.execute(
        "SELECT method_key FROM methods WHERE owner_struct_key=?",
        (struct_key,),
    ).fetchall()
    out: list[str] = []
    for (mk,) in rows:
        # method_key: "proc:<fqcn>#<name>(<sig>)"
        m = re.search(r"#([^(]+)\(", mk)
        if m and m.group(1) == method:
            out.append(mk)
    return out


def _arity_from_args(path: str) -> int | None:
    try:
        with open(path) as f:
            obj = json.load(f)
        args = obj.get("args")
        if isinstance(args, list):
            return len(args)
    except Exception:
        return None
    return None


def _arity_from_method_key(method_key: str) -> int | None:
    m = re.search(r"\((.*)\)", method_key)
    if not m:
        return None
    sig = m.group(1)
    if not sig:
        return 0
    # Top-level comma split (generics aren't present in method_key signatures
    # — they're erased FQCNs separated by commas).
    return sig.count(",") + 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=_DEFAULT_SRC)
    ap.add_argument("--dest", default=_DEFAULT_DEST)
    ap.add_argument("--no-copy", action="store_true",
                    help="Update DB only; don't copy files into the tree")
    ap.add_argument("--snap", default="",
                    help="Override captured_from_snap (default: read from fixture's 'snap' field)")
    args = ap.parse_args()

    if not os.path.isdir(args.src):
        print(f"ERROR: src not found: {args.src}", file=sys.stderr)
        return 2

    con = sqlite3.connect(_DB)
    con.execute("PRAGMA foreign_keys = ON")

    n_files = 0
    n_inserted = 0
    n_updated = 0
    n_unresolved = 0
    captured_methods: set[str] = set()

    for fqcn, method, sha, src_path in _walk_fixtures(args.src):
        n_files += 1
        candidates = _resolve_method_keys(con, fqcn, method)
        if not candidates:
            n_unresolved += 1
            continue

        # Prefer arity match if multiple overloads.
        if len(candidates) > 1:
            arity = _arity_from_args(src_path)
            if arity is not None:
                narrowed = [
                    mk for mk in candidates
                    if _arity_from_method_key(mk) == arity
                ]
                if narrowed:
                    candidates = narrowed

        # Copy file into the dest tree (one per fqcn/method/sha).
        rel = os.path.join(fqcn, method, sha + ".json")
        dest_path = os.path.join(args.dest, rel)
        if not args.no_copy:
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            shutil.copy2(src_path, dest_path)
        size = os.path.getsize(src_path)
        ret_bytes = 0
        snap = args.snap
        try:
            with open(src_path) as f:
                obj = json.load(f)
            if not snap:
                snap = obj.get("snap", "") or ""
            ret_bytes = len(json.dumps(obj.get("return"))) if "return" in obj else 0
        except Exception:
            pass

        for method_key in candidates:
            fixture_id = f"{fqcn}#{method}::{sha}"
            existing = con.execute(
                "SELECT 1 FROM golden_fixtures WHERE fixture_id=?",
                (fixture_id,),
            ).fetchone()
            if existing:
                con.execute(
                    """UPDATE golden_fixtures
                       SET fixture_path=?, args_bytes=?, return_bytes=?,
                           captured_from_snap=?, captured_at=?,
                           method_key=?
                       WHERE fixture_id=?""",
                    (dest_path, size, ret_bytes, snap, _now(),
                     method_key, fixture_id),
                )
                n_updated += 1
            else:
                con.execute(
                    """INSERT INTO golden_fixtures
                       (fixture_id, method_key, fixture_path, args_bytes,
                        return_bytes, captured_from_snap, captured_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (fixture_id, method_key, dest_path, size,
                     ret_bytes, snap, _now()),
                )
                n_inserted += 1
            captured_methods.add(method_key)

    if captured_methods:
        placeholders = ",".join("?" * len(captured_methods))
        con.execute(
            f"UPDATE methods SET capture_state='captured' "
            f"WHERE method_key IN ({placeholders})",
            tuple(captured_methods),
        )
    con.commit()
    con.close()

    print(f"src={args.src}")
    print(f"dest={args.dest}")
    print(f"files seen: {n_files}")
    print(f"inserted:   {n_inserted}")
    print(f"updated:    {n_updated}")
    print(f"unresolved (no matching method_key): {n_unresolved}")
    print(f"methods promoted to capture_state='captured': {len(captured_methods)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
