#!/usr/bin/env python3
"""Capture Tier-A fixtures for ONE class (or a small set) at a time.

Idiomatic per-class capture: targets only the FQCN(s) you specify so
adding a new class doesn't recapture every other class. Streams gradle
+ agent output live, records start/end/wall-time/intercepts/writes in
port.sqlite's `captures` table, then runs import_fixtures + processes
snaps so the additive capture lands in the DB.

Usage:
    scripts/capture_class.py games.strategy.triplea.delegate.battle.MustFightBattle
    scripts/capture_class.py FQCN1 FQCN2 ...      # capture multiple in ONE gradle run
    scripts/capture_class.py --per-cap 50 FQCN    # tighter cap to bound cost
"""
from __future__ import annotations

import argparse
import datetime as _dt
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time

_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
_DB = os.path.join(_ROOT, "port.sqlite")
_TRIPLEA = os.path.join(_ROOT, "triplea")
_AGENT_JAR = os.path.join(
    _TRIPLEA, "conversion", "proc-recorder-agent", "build", "libs",
    "proc-recorder-agent.jar",
)
_FIXTURES_OUT = os.path.join(
    _TRIPLEA, "game-app", "smoke-testing", "build", "golden_fixtures"
)
_SNAPS_BUILD = os.path.join(
    _TRIPLEA, "game-app", "smoke-testing", "build", "snapshots"
)
_SNAPS_TREE = os.path.join(_TRIPLEA, "conversion", "odin_tests")


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def _start_capture_row(con: sqlite3.Connection, fqcn: str) -> int:
    cur = con.execute(
        "INSERT INTO captures (fqcn, started_at, status) VALUES (?, ?, 'running')",
        (fqcn, _now()),
    )
    con.commit()
    return cur.lastrowid


def _finish_capture_row(con: sqlite3.Connection, row_id: int, status: str,
                        elapsed_ms: int, fixtures: int, intercepts: int,
                        note: str | None = None) -> None:
    con.execute(
        """UPDATE captures
           SET finished_at=?, status=?, elapsed_ms=?, fixtures_written=?,
               intercepts_total=?, note=?
           WHERE id=?""",
        (_now(), status, elapsed_ms, fixtures, intercepts, note, row_id),
    )
    con.commit()


def _count_fixtures_for(fqcn: str) -> int:
    cls_dir = os.path.join(_FIXTURES_OUT, fqcn)
    if not os.path.isdir(cls_dir):
        return 0
    n = 0
    for root, _dirs, files in os.walk(cls_dir):
        n += sum(1 for f in files if f.endswith(".json"))
    return n


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("classes", nargs="+",
                    help="Fully-qualified class names to capture")
    ap.add_argument("--per-cap", type=int, default=200,
                    help="Per-(class, method) fixture cap (default 200)")
    ap.add_argument("--max-bytes", type=int, default=200 * 1024 * 1024)
    ap.add_argument("--progress-ms", type=int, default=5000)
    ap.add_argument("--keep-existing", action="store_true",
                    help="Don't delete other classes' fixtures from build/golden_fixtures (default: keep)")
    ap.add_argument("--no-import", action="store_true",
                    help="Skip import_fixtures.py + process_snapshots.py at end")
    args = ap.parse_args()

    if not os.path.exists(_AGENT_JAR):
        print(f"ERROR: agent jar not built: {_AGENT_JAR}", file=sys.stderr)
        print("  cd triplea/conversion/proc-recorder-agent && gradle jar", file=sys.stderr)
        return 2

    con = sqlite3.connect(_DB)

    inline_class = "+".join(args.classes)

    # Per-class capture is ADDITIVE: we only blow away the target classes'
    # subdirs, not the whole golden_fixtures/ tree (which holds previously
    # captured classes that shouldn't pay re-capture cost). Idiomatic
    # incremental Tier-A workflow per golden_testing_plan.md §1.
    for fqcn in args.classes:
        target = os.path.join(_FIXTURES_OUT, fqcn)
        if os.path.isdir(target):
            shutil.rmtree(target)
            print(f"  cleared previous fixtures: {target}")

    row_ids = {fqcn: _start_capture_row(con, fqcn) for fqcn in args.classes}

    cmd = [
        "./gradlew", ":game-app:smoke-testing:test",
        "--tests", "*Ww2v5JacocoRun.runWithSnapshots",
        f"-PprocRecorderAgent={_AGENT_JAR}",
        f"-DprocRecorder.outDir={_FIXTURES_OUT}",
        f"-DprocRecorder.perMethodCap={args.per_cap}",
        f"-DprocRecorder.maxBytes={args.max_bytes}",
        f"-DprocRecorder.progressEveryMs={args.progress_ms}",
        f"-DprocRecorder.class={inline_class}",
        "--rerun-tasks",
    ]
    print(f"\n=== capturing {len(args.classes)} class(es) ===")
    for c in args.classes:
        print(f"  - {c}")
    print(f"  per-method cap = {args.per_cap}")
    print(f"  progress every  = {args.progress_ms} ms\n")

    started = time.time()
    log_path = f"/tmp/capture_{int(started)}.log"
    print(f"\n  log: {log_path}\n")

    # Use --console=plain so gradle doesn't paint a progress bar (which
    # confuses our parser); --no-daemon so the JVM exits cleanly when the
    # task finishes (otherwise the daemon keeps its stdout pipe open and
    # subprocess.communicate hangs waiting for EOF).
    cmd_str = " ".join(['"%s"' % a if " " in a else a for a in cmd])
    cmd_str += " --console=plain --no-daemon 2>&1 | tee " + log_path
    rc = os.system(f"cd {_TRIPLEA} && {cmd_str}")
    if rc != 0:
        # os.system returns waitpid status; convert to plain exit code.
        rc = (rc >> 8) & 0xff if rc > 255 else rc

    final_intercepts = 0
    final_writes = 0
    final_elapsed_ms = 0
    try:
        with open(log_path) as f:
            for line in f:
                m = re.search(r"\[ProcRecorderAgent\] SUMMARY elapsed_ms=(\d+) intercepts=(\d+) writes=(\d+) bytes=(\d+)", line)
                if m:
                    final_elapsed_ms = int(m.group(1))
                    final_intercepts = int(m.group(2))
                    final_writes = int(m.group(3))
    except Exception as e:
        print(f"  warning: could not parse log: {e}")

    wall_ms = int((time.time() - started) * 1000)
    if final_elapsed_ms == 0:
        final_elapsed_ms = wall_ms

    status = "ok" if rc == 0 else ("aborted" if rc < 0 else "failed")
    for fqcn, row_id in row_ids.items():
        n = _count_fixtures_for(fqcn)
        _finish_capture_row(
            con, row_id, status, final_elapsed_ms, n, final_intercepts,
            note=f"shared run with {len(args.classes)} class(es); rc={rc}",
        )
        print(f"  recorded captures.id={row_id} fqcn={fqcn} fixtures={n}")

    con.close()

    if rc != 0:
        print(f"\n!! gradle exited rc={rc}")
        return rc if rc > 0 else 1

    if not args.no_import:
        print("\n=== process_snapshots ===")
        subprocess.check_call(
            ["python3", os.path.join(_HERE, "process_snapshots.py"),
             "--input", _SNAPS_BUILD, "--output", _SNAPS_TREE],
            cwd=_ROOT,
        )
        print("\n=== import_fixtures ===")
        subprocess.check_call(
            ["python3", os.path.join(_HERE, "import_fixtures.py")],
            cwd=_ROOT,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
