# How to take per-method snapshots that include args, receiver, and return value

This document walks through the pipeline that captures **per-call before/after
goldens** for one Java method (e.g. `BattleSteps#get`) and then replays the
captured input through the Odin port, marshals the result back to JSON, and
loose-compares it against the captured Java return value to find the first
divergence.

It is a living reference — the pipeline was built incrementally while porting
`BattleSteps#get` and the same plumbing applies to any other yellow proc.

---

## Overview

```
                 ┌──────────────────────────────────────┐
                 │  scripts/capture_proc_snapshot.py    │
                 │    --class FQCN  --method NAME       │
                 └──────────────┬───────────────────────┘
                                │ writes per-call snapshot.config
                                │ runs Ww2v5JacocoRun.runWithSnapshots
                                ▼
   ┌─────────────────────────────────────────────────────────────┐
   │  TripleA smoke test JVM, with -javaagent=snapshot-agent.jar │
   │                                                              │
   │   SnapshotAgent → ByteBuddy onMethodEnter/onMethodExit       │
   │     SnapshotInterceptor.java:                                │
   │       • tick++ for every method in jfr-methods.txt           │
   │       • on entry: dumps before-self.json, before-param-N.json│
   │       • on exit : dumps after-return.json (+ before/after.json│
   │                  full-game-data context if extractable)      │
   │     GenericValueSerializer.java (Jackson ObjectMapper):      │
   │       • @class default typing on every Object                │
   │       • @id/@ref via JsonIdentityInfo mixin (cycle-safe)     │
   │       • IdentityHintSerializer prunes ~40 game-data classes  │
   │         to a 2-deep structured stub (NOT toString)           │
   └──────────────┬───────────────────────────────────────────────┘
                  │ tick-NNNNNNNNNN/ raw dirs in scratch
                  ▼
   ┌─────────────────────────────────────────────────────────────┐
   │  capture_proc_snapshot.py post-processes:                    │
   │    filters tick-* dirs whose meta says class+method matched  │
   │    copies them into snapshots/{NNNN}/ under your test pkg    │
   │    each: before.json before-self.json before-param-*.json    │
   │           after.json after-return.json *meta.txt return.txt  │
   └──────────────┬───────────────────────────────────────────────┘
                  │
                  ▼ (Odin side)
   ┌─────────────────────────────────────────────────────────────┐
   │  triplea/conversion/odin_tests/test_common/                  │
   │    proc_snapshot_marshal.odin   reflection → Jackson-shape   │
   │    proc_snapshot_compare.odin   loose JSON diff w/ canonical │
   │  Per-test pkg:                                                │
   │    test_marshal_smoke.odin                                   │
   │    test_compare_smoke.odin                                   │
   │    test_compare_real_golden.odin                             │
   │    (TODO) test_<class>_<method>.odin runs all snapshots/     │
   └─────────────────────────────────────────────────────────────┘
```

---

## Java side — capture

### Files

| File | Role |
|---|---|
| `templates/snapshot-agent/src/main/java/agent/SnapshotAgent.java` | Byte Buddy premain, registers `SnapshotInterceptor` on every method in `jfr-methods.txt`. |
| `templates/snapshot-agent/src/main/java/agent/SnapshotInterceptor.java` | Tick counter + before/after dumps. `extractGameData(self, seen, depth)` does an identity-set, depth-capped reflective walk to find the `GameData` reachable from the receiver so the full state can be saved as `before.json`/`after.json` alongside the per-call values. |
| `templates/snapshot-agent/jfr-methods.txt` | Master list of methods that get a tick increment. Methods not in this file are invisible to the agent. |
| `templates/snapshot-agent/snapshot.config.template` | Default config; `methods.file`, `snapshot.outDir`, `snapshot.maxBytes`, `snapshot.maxMillis`, `snapshot.maxSnapshots`, and the optional `include.classes` / `include.methods` filters. |
| `templates/snapshot/GenericValueSerializer.java` | Jackson `ObjectMapper` config for the per-call dumps. |
| `templates/snapshot/SnapshotProcessor.java`, `SnapshotHarness.java`, `GameStateJsonSerializer.java` | Whole-game-data dumping (`before.json`, `after.json`). |

### Jackson serializer (the part that matters most)

`GenericValueSerializer.java`:

```java
ObjectMapper m = new ObjectMapper()
    .setVisibility(... FIELD/ANY ...)
    .activateDefaultTyping(            // emits "@class" : FQCN on every Object
        BasicPolymorphicTypeValidator.builder().allowIfBaseType(Object.class).build(),
        DefaultTyping.OBJECT_AND_NON_CONCRETE);

m.addMixIn(Object.class, IdentityMixin.class);   // adds @JsonIdentityInfo via mixin

// For each class in PRUNE_TYPES (~40 game-data types), register a custom
// IdentityHintSerializer that:
//   - emits @class
//   - recurses into fields up to IDENTITY_MAX_DEPTH = 2
//     (root → one level of pruned children → grandchildren collapse to {@class})
//   - skips back-pointers (gameData)
//   - skips empty collections / maps / nulls
//   - overrides serializeWithType so default-typing doesn't blow up with
//     InvalidDefinitionException
```

**Why this shape?** A bare `toString()` is not a true serialization — it loses
nested structure, can't be diffed structurally, and breaks for types we
haven't seen yet. The structured stub is **fully generic**: every game-data
type emits the same shape (scalar fields + nested pruned-type stubs +
collections of those), and there is zero per-type code on the Odin side.

### Build/run

`scripts/patch_triplea.py` makes the upstream TripleA checkout snapshot-ready:

- Copies `templates/snapshot-agent/` → `triplea/conversion/snapshot-agent/`.
- Copies `templates/snapshot/*.java` → `triplea/game-app/smoke-testing/...`.
- Adds `jackson-databind = ...` to `triplea/gradle/libs.versions.toml`.
- Appends `testImplementation(libs.jackson.databind)` to
  `triplea/game-app/smoke-testing/build.gradle.kts`.
- Adds the snapshot-agent JVM-args block to the smoke-testing gradle build so
  `-PsnapshotAgent=<jar>` engages the `-javaagent` flag.

All idempotent — safe to re-run.

### Capturing one method

```bash
python3 scripts/capture_proc_snapshot.py \
  --class  games.strategy.triplea.delegate.battle.steps.BattleSteps \
  --method get \
  --triplea triplea \
  --max-minutes 15 \
  --max-bytes $((100 * 1024 * 1024)) \
  --max-snapshots 500
```

What the script does:

1. Builds the agent fat-jar via `./gradlew jar` inside
   `triplea/conversion/snapshot-agent/` (cached).
2. Writes a per-call `snapshot.config` (in a tempfile) with
   `include.classes=BattleSteps` and `include.methods=get`. **Why per-call?**
   Gradle `-D` does **not** propagate to the test JVM — caps had to move into
   the config file the agent reads at premain.
3. Runs `Ww2v5JacocoRun.runWithSnapshots` with `-PsnapshotAgent=<jar>
   -Dsnapshot.outDir=<scratch> -Dsnapshot.config=<cfg>`. The smoke test
   exercises a real WW2v5 game so every reachable `BattleSteps#get` call gets
   its own `tick-NNNNNNNNNN/` directory.
4. Walks the scratch dir, picks tick-dirs whose `before-meta.txt` `method`
   line matches the filter, and copies them into
   `triplea/conversion/odin_tests/dep_battle_steps_get/snapshots/{NNNN}/`.
5. Each captured snapshot directory contains:

   ```
   before.json        # full GameData (~280 KB) — Jackson dump of game state
   before-self.json   # the receiver, recursively (~23 KB for BattleSteps)
   before-param-N.json (one per non-receiver argument)
   before-meta.txt    # tick, signature, args summary
   after.json         # full GameData after the call
   after-return.json  # the returned value (~197 KB for the 8-element list)
   after-meta.txt
   return.txt         # toString() of the return for human inspection
   ```

Concrete result: 190+ goldens for `BattleSteps#get` from one smoke run.

---

## Odin side — replay & compare

### Files

| File | Role |
|---|---|
| `triplea/conversion/odin_tests/test_common/proc_snapshot_marshal.odin` | Reflection-based generic JSON marshaller. |
| `triplea/conversion/odin_tests/test_common/proc_snapshot_compare.odin` | Loose JSON comparator. |
| `triplea/conversion/odin_tests/test_common/json_loader.odin` | Existing loader for `before.json` → `^Game_Data` (used by the existing snapshot runner; per-method tests will reuse it). |
| `triplea/conversion/odin_tests/dep_<class>_<method>/test_marshal_smoke.odin` | Sanity check for marshaller output shape. |
| `triplea/conversion/odin_tests/dep_<class>_<method>/test_compare_smoke.odin` | Comparator unit tests for canonicalization rules. |
| `triplea/conversion/odin_tests/dep_<class>_<method>/test_compare_real_golden.odin` | End-to-end round-trip through the actual captured Java JSON. |

### Marshaller — `proc_snapshot_marshal.odin`

```
marshal :: proc(v: any, pretty: bool, allocator) -> string
```

- Uses `runtime.Type_Info_*` and `core:reflect` only — **zero per-type code**.
- Emits Jackson-compatible shape:
  - `"@class": "<Type_Info_Named.name>"` on every struct.
  - `"@id": N` first time a `^T` is emitted; `"@ref": N` on every subsequent
    visit of the same pointer (cycle-safe).
  - Fields declared `using inner: Inner_Type` are **flattened inline** to
    match Java inheritance — so `Roll_Dice_Step` (which `using battle_step:
    Battle_Step`) emits the parent's fields at the outer level.
- Pruned-type list (`is_pruned_type` — ~40 entries: `Game_Data`, `Game_Map`,
  `Territory`, `Unit`, `Game_Player`, `Battle_State`, `Battle_Actions`,
  `Must_Fight_Battle`, all attachments, etc.) — these emit at most 2 levels
  deep and only fields that are scalar/enum/pointer-to-pruned/collection-of-those.
- Skips proc-typed fields (vtable slots).
- Skips empty containers and `nil` pointers (matches Java's
  `IdentityHintSerializer`).
- Handles slice / dynamic_array / fixed array / map / struct / pointer /
  scalar / enum / string.

**Gotcha:** put `#+feature dynamic-literals` as the first line of the file if
you want to use `map[string]bool{ ... }` compound literals at file scope. We
chose not to and used a `switch` proc instead so the feature flag isn't needed.

**Map iteration:** the right API is `reflect.iterate_map(val: any, it: ^int)
-> (key, value: any, ok: bool)`, not the older `Map_Iterator` struct.

### Comparator — `proc_snapshot_compare.odin`

```
compare_proc_snapshot :: proc(odin_json, java_json: string) -> string
```

Returns `""` on match, otherwise a JSON-pointer-style first-divergence path
plus a one-line reason. Canonicalization rules:

| Rule | Example |
|---|---|
| `@class` name canonicalization | Java `games.strategy....fire.RollDiceStep` ≡ Odin `Roll_Dice_Step` (both → `roll_dice_step`); inner-class `BattleStep$StepDetails` ≡ `Battle_Step_Step_Details`. |
| Field-name canonicalization | Java `battleState` ≡ Odin `battle_state`. |
| `null` ≡ missing key ≡ empty container | `{a:null}` ≡ `{}` ≡ `{a:[]}`. |
| `int` ≡ `float` if numerically equal | `0` ≡ `0.0`. |
| Object key order | Ignored. |
| Array order | Respected (lists are ordered in both languages). |
| `@ref` indirection | Resolved per-side via an `@id` table built at the start; isomorphism, not pointer equality. |

`@id` integers themselves are **not** value-compared — only the topology of
the @id graph is.

### Smoke tests

`triplea/conversion/odin_tests/dep_battle_steps_get/test_marshal_smoke.odin`
builds two `Battle_Step_Step_Details` sharing one `^Battle_Step` and verifies
the marshaller emits ≥3 `@class`, ≥2 `@id`, and ≥1 `@ref` (the cycle dedup):

```json
[
  {"@class":"Battle_Step_Step_Details","@id":1,"name":"Russians fire",
   "step":{"@class":"Battle_Step","@id":2}},
  {"@class":"Battle_Step_Step_Details","@id":3,"name":"Germans fire",
   "step":{"@ref":2}}
]
```

`test_compare_smoke.odin` covers each canonicalization rule individually.

`test_compare_real_golden.odin` reads the actual captured 6034-line
`snapshots/0001/after-return.json` and round-trips it through
`compare_proc_snapshot(s, s)` (must return `""`), then mutates one byte and
confirms divergence is detected. This validates the comparator handles the
real Jackson output shape end-to-end.

### Running

```bash
cd triplea
odin test conversion/odin_tests/dep_battle_steps_get \
  -collection:flat=../odin_flat \
  -collection:test_common=conversion/odin_tests/test_common
```

All 10 tests should pass.

---

## What's still missing (next steps)

1. **Receiver reconstructor.** Read `before-self.json`, look up the
   referenced `Territory` / `Game_Player` / etc. by `name` in the
   `Game_Data` already loaded from `before.json`, build a `^Must_Fight_Battle`
   wrapper, and wrap it in `Battle_Steps{battle_state, battle_actions}`. Param
   files (`before-param-N.json`) are reconstructed the same way.

2. **Per-method test runner.** For each `snapshots/NNNN/`:
   1. Load `before.json` → `^Game_Data` (existing `json_loader.odin`).
   2. Load `before-self.json` + `before-param-*.json` → reconstruct receiver
      and args.
   3. Call the proc under test.
   4. `marshal(result, pretty=false, allocator)` → JSON.
   5. Read `after-return.json`.
   6. `compare_proc_snapshot(odin, java)`; report the first failing `NNNN`
      and diff path.

3. **Bisect.** When the runner reports a diff for `BattleSteps#get` snap
   0001, the path will tell us whether the bug is in `battle_step_get_all`
   (wrong subset of step constructors), `battle_step_get_all_step_details`
   (wrong fan-out per step), or the `get_order` sort key on some subtype.

---

## Quick reference

```bash
# Capture goldens for one method
python3 scripts/capture_proc_snapshot.py \
  --class FQCN --method NAME \
  [--triplea triplea] [--out DIR] \
  [--max-minutes 15] [--max-bytes 104857600] [--max-snapshots 500]

# Patch upstream TripleA (idempotent)
python3 scripts/patch_triplea.py [--triplea triplea]

# Run Odin tests
cd triplea && odin test conversion/odin_tests/dep_<class>_<method> \
  -collection:flat=../odin_flat \
  -collection:test_common=conversion/odin_tests/test_common
```

```odin
// Mini cookbook
import test_common "../test_common"

odin_json := test_common.marshal(my_value, pretty = false, allocator = context.allocator)
diff      := test_common.compare_proc_snapshot(odin_json, java_golden_string)
if diff != "" do log.errorf("snapshot %s diverges: %s", id, diff)
```
