# Next Steps — divergence work at HEAD (2026-05-15)

## Current state

### Confirmed at HEAD with FRESH data (this session)
- **Fresh Java DIGEST r=1**: `/tmp/java-digest-r1-fresh.txt` (52 lines, 16s via gradle).
- **Fresh Odin DIGEST r=1** (precache disabled): `/tmp/odin-digest-noprecache-083037.txt`
  (only 21 lines emitted before German purchase blocked further progress).
- **Odin and Java match byte-for-byte i=0..20** (gameInit + 10 bid steps + russianBid + russianTech +
  russianPurchase + russianCombat + russianBattle + russianNCM + russianPlace + russianTechActivation +
  russianEndTurn + germanTech + germanPurchase digest line).
- **The May 10 i=16 russianPlace divergence is FIXED**: Odin uc_h `a65d2cf5f1b8bbbe` matches Java exactly.
- **i=37 japanesePurchase divergence (May 10)**: cannot re-confirm at HEAD because the run
  blocks before reaching it (see Performance below).

### Performance blockers discovered this session
1. **Russian purchase** hangs 5+ min (RSS 2→6GB) when `BATTLE_PRECACHE_ENABLED=true` (default).
   Workaround: `export TRIPLEA_BATTLE_PRECACHE_ENABLED=0`. Config:
   `odin_flat/games__strategy__triplea__odds__calculator__precache__battle_precache_config.odin:21`.
2. **German purchase** runs 6-10+ min (RSS 4→8GB, climbing) WITHOUT precache and never emits
   the next DIGEST line. Russia at $0 PUs is a near no-op (1m17s); Germany at $41 PUs runs the
   full ProPurchaseAi which appears to call the on-demand odds calculator a huge number of times.
3. Java does the same 52 steps end-to-end in 16s. Odin's odds_calculator path is dramatically
   slower than Java's. This is a separate perf problem from divergence but blocks our ability to
   reach late steps via the full r=1 path.

## Recommended next actions (in priority order)

### Option 1 (recommended) — Java-driven per-step snapshots, then per-snap Odin diff
The full r=1 path is impractical at HEAD. Instead, generate a snapshot at EVERY step from the
Java side, then run each one independently in Odin via the existing snap test target. Each step
runs as a one-shot, so even slow german/japanese AI is bounded to a few minutes per snap.

Steps:
1. Extend `Ww2v5JacocoRun.runFullGameDeterminismProbe` (or the existing snapshot-agent) to dump
   a `snap_NNNN/before.json` for each step pre-state, NNNN = step index, into
   `triplea/conversion/odin_tests/dep_server_game_run_step/snapshots/NNNN/`.
   Currently only 0001..0019 exist; we need 0020..0052.
2. For each new snap, run:
   ```bash
   cd /home/caleb/todin/triplea
   $ODIN test conversion/odin_tests/server_game_run_next_step \
       -collection:flat=/home/caleb/todin/odin_flat \
       -collection:test_common=conversion/odin_tests/test_common \
       -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_TRACK_MEMORY=false \
       "-define:FILTER_SNAP=\"NNNN\"" \
       -extra-linker-flags:"-L/nix/store/ccif8gy9z7c4v6d3hnwsph9fqaqw8hwv-sqlite-3.50.4/lib"
   ```
3. Compare each snap's emitted `uc_h`/`comp_h` against the corresponding line in
   `/tmp/java-digest-r1-fresh.txt`. First mismatch identifies the offending step.
4. The step BEFORE the first divergent uc_h is the actual culprit (per `deterministic-maps.md`
   recipe — the divergent uc_h is downstream evidence).

### Option 2 — Investigate odds_calculator perf gap first
Java does a full r=1 AI run in 16s. Odin spends >10 min on a single AI purchase. Profile Odin's
`odds_calculator` and `pro_purchase_ai` during germanPurchase to find:
- Hot allocators (per-call `make([]T)` that should be reused).
- Missing memoization vs Java.
- O(n²) walks where Java uses HashMap lookups.

A 10× perf win likely both unblocks Option 1 directly via full r=1 AND surfaces real divergences
hiding behind perf-induced timeouts.

### Option 3 — AI bypass for non-Russian players (LIMITED)
Replace ProPurchaseAi with EasyAi (or DoesNothingAi) for non-Russian players in the Odin runner
only, just to advance the game. Drawback: Java oracle uses ProAi everywhere, so we can only
compare Russian-step rows. Useful only if we want to get further forward AND we trust that all
non-Russian rows still match (which we don't — that's the question we're trying to answer).
NOT recommended.

## Cleanup item (orthogonal)
- Remove stray `fmt.printf("DIGEST_CAUCASUS_PTR ...")` debug probe at
  [odin_flat/test_full_game_digest.odin](odin_flat/test_full_game_digest.odin#L129).
  Emits between i=11 and i=12 in DIGEST output.

## Environment recall
```
ODIN=/nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/bin/odin
LD_LIBRARY_PATH=/nix/store/ccif8gy9z7c4v6d3hnwsph9fqaqw8hwv-sqlite-3.50.4/lib
JAVA_HOME=/nix/store/c3pl7bqrx3d2rc3dh98z6yaj0mv1p52g-openjdk-21.0.10+7
TRIPLEA_BATTLE_PRECACHE_ENABLED=0   # REQUIRED for Odin DIGEST runs
```

## Reference files
- Java oracle: `/tmp/java-digest-r1-fresh.txt` (regenerate with gradle, 16s)
- Odin partial: `/tmp/odin-digest-noprecache-083037.txt` (21 lines i=0..20)
- Stripped Odin for diff: `/tmp/odin-fresh-clean.txt`
- Memory note: `/memories/repo/triplea-port-divergence.md`
- Previous version of this file: `next-steps.md.bak.20260515`
