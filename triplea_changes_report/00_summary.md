# triplea local-change report

Generated: 2026-05-12T15:36:19-05:00
Upstream baseline: `9a18d931a Add copilot instructions file and ignore (#14296) (2026-04-26)`
Workspace path:    `/home/caleb/todin/triplea`

## Counts

- Tracked files changed vs upstream HEAD: **82** (Java: 80)
- New untracked Java files under `game-app/`: **8**

## Files

| Section | File |
| --- | --- |
| Name + status (M/A/D/R) of tracked changes | [01_name_status.txt](01_name_status.txt) |
| Per-file line counts                       | [02_diffstat.txt](02_diffstat.txt) |
| Full unified diff of tracked changes       | [03_tracked.diff](03_tracked.diff) |
| New untracked Java files (game-app/)       | [04_untracked_new_java.diff](04_untracked_new_java.diff) |

## New untracked Java files

- `game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/ProDeterminism.java`
- `game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/ProNcmTrace.java`
- `game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/ProPurTrace.java`
- `game-app/smoke-testing/src/test/java/games/strategy/engine/data/GameStateJsonSerializer.java`
- `game-app/smoke-testing/src/test/java/games/strategy/engine/data/GenericValueSerializer.java`
- `game-app/smoke-testing/src/test/java/games/strategy/engine/data/SnapshotHarness.java`
- `game-app/smoke-testing/src/test/java/games/strategy/engine/data/SnapshotProcessor.java`
- `game-app/smoke-testing/src/test/java/org/triplea/portbootstrap/Ww2v5JacocoRun.java`

## Reproduce

```sh
./scripts/triplea_changes_report.sh
```
