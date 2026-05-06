#!/usr/bin/env python3
"""Post-process /tmp/cov.txt: emit (proc_key -> set of snap_ids that fired
it AND passed). A proc with at least one passing snap is green-eligible
under criterion (a) of the doctrine.

Reads /tmp/cov.txt, expects:
  '=== Snapshot <id> starting'           — sets current snap
  '@@COV|<id>|<proc_key>@@'              — proc fired under snap <id>
  'Snapshot <id> FAILED:'                — marks snap <id> as failed
"""
from __future__ import annotations

import re
import sys
from collections import defaultdict

snap_re      = re.compile(r"=== Snapshot (\S+) starting")
cov_re       = re.compile(r"@@COV\|([^|]*)\|([^@]+)@@")
fail_re      = re.compile(r"Snapshot (\S+) FAILED")

failed: set[str] = set()
fired: dict[str, set[str]] = defaultdict(set)  # proc_key -> {snap_ids}
all_snaps: set[str] = set()

with open("/tmp/cov.txt") as f:
    for line in f:
        if m := snap_re.search(line):
            all_snaps.add(m.group(1))
        if m := fail_re.search(line):
            failed.add(m.group(1))
        if m := cov_re.search(line):
            snap, key = m.group(1), m.group(2)
            if snap:
                fired[key].add(snap)

passing = all_snaps - failed
print(f"snaps: {len(all_snaps)} total, {len(passing)} passing, {len(failed)} failing")
print()
print("=== Yellow proc coverage report ===")
for key in sorted(fired):
    fired_in   = sorted(fired[key])
    pass_fires = sorted(fired[key] & passing)
    fail_fires = sorted(fired[key] & failed)
    status = "GREEN-ELIGIBLE" if pass_fires else "needs targeted test"
    print(f"\n{status}: {key}")
    print(f"  fired in {len(fired_in)} snaps")
    print(f"    passing ({len(pass_fires)}): {pass_fires[:8]}{'...' if len(pass_fires)>8 else ''}")
    print(f"    failing ({len(fail_fires)}): {fail_fires[:8]}{'...' if len(fail_fires)>8 else ''}")
