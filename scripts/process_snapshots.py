#!/usr/bin/env python3
"""process_snapshots.py
================================================================================
Reorganize raw `build/snapshots/{method}/step-NNNN-round-RRR-stepName/`
directories produced by SnapshotHarness into the
`conversion/odin_tests/{method}/snapshots/{NNNN}/before.json + after.json`
layout that the Odin snapshot_runner expects.

Pure python port of SnapshotProcessor.java — no JVM required.

Usage:
    python3 process_snapshots.py --input  <raw>     [default: build/snapshots]
                                 --output <out>     [default: conversion/odin_tests]
================================================================================
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

STEP_RE = re.compile(r"^step-(\d{4})-round-\d{3}-")

ODIN_TEST_TEMPLATE = '''package test_{name}

import "core:testing"
import game "../../odin_flat"
import tc "../test_common"

@(test)
test_all_snapshots :: proc(t: ^testing.T) {{
    tc.run_snapshot_tests(t,
        "conversion/odin_tests/{name}/snapshots",
        game.{name})
}}
'''


def process_method_dir(method_dir: Path, out_root: Path) -> int:
    name = method_dir.name
    step_dirs = {}
    for sub in sorted(method_dir.iterdir()):
        if not sub.is_dir():
            continue
        m = STEP_RE.match(sub.name)
        if not m:
            continue
        step_dirs[int(m.group(1))] = sub

    proc_dir = out_root / name
    snap_dir = proc_dir / "snapshots"
    snap_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for step_num in sorted(step_dirs):
        sd = step_dirs[step_num]
        before = sd / "step-before-gamedata.json"
        after = sd / "step-after-gamedata.json"
        if not (before.is_file() and after.is_file()):
            continue
        target = snap_dir / f"{step_num:04d}"
        target.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(before, target / "before.json")
        shutil.copyfile(after, target / "after.json")
        for meta_in, meta_out in (
            ("step-before-meta.txt", "before-meta.txt"),
            ("step-after-meta.txt", "after-meta.txt"),
        ):
            mi = sd / meta_in
            if mi.is_file():
                shutil.copyfile(mi, target / meta_out)
        count += 1

    print(f"  {name}: {count} snapshot pairs")

    odin_test = proc_dir / f"test_{name}.odin"
    if not odin_test.is_file():
        odin_test.write_text(ODIN_TEST_TEMPLATE.format(name=name))
        print(f"    wrote {odin_test.name}")

    return count


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", default="build/snapshots")
    ap.add_argument("--output", default="conversion/odin_tests")
    args = ap.parse_args()

    src = Path(args.input).resolve()
    dst = Path(args.output).resolve()
    if not src.is_dir():
        sys.exit(f"input dir not found: {src}")
    dst.mkdir(parents=True, exist_ok=True)

    print(f"processing {src} -> {dst}")
    total = 0
    for method_dir in sorted(src.iterdir()):
        if method_dir.is_dir():
            total += process_method_dir(method_dir, dst)
    print(f"done: {total} snapshot pairs")


if __name__ == "__main__":
    main()
