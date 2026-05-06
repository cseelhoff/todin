# TripleA Java→Odin Port: Plan

## Goal

Port TripleA from Java to Odin with byte-for-byte snapshot equivalence
on a deterministic AI-vs-AI game (`AiGameTest.testWW2v5Game`,
WW2v5_1942_2nd map, `SeededRandomSource(42)`).

## Tracker

The single source of truth is `port.sqlite` (built by `bootstrap.sh`).
Every porting decision is driven by:

```sql
SELECT * FROM structs WHERE is_implemented = 0 ORDER BY id_design_layer;
SELECT * FROM methods WHERE is_implemented = 0 ORDER BY method_layer;
```

## Architecture

ID-based, data-oriented:

- `Game_Data` is the single owning struct. It holds `[dynamic]`s of
  every concrete entity (`units`, `territories`, `players`, ...).
- Cross-references are `*_Id :: distinct u32` indexes, not pointers.
- Lookups go through `Game_Data` (`unit_get(gd, id) -> ^Unit`).
- Save/load is array memcpy.
- The 50-struct cycle and the 12-struct AI cycle that exist in the
  Java reference graph **dissolve** under this design — the
  inheritance-only graph is a strict DAG with depth ≤ 5.

## Phases

### Phase 0 — Bootstrap (one-time)

Run `./bootstrap.sh`. Produces `port.sqlite` and `odin_flat/`.
Run `BOOTSTRAP_SNAPSHOTS=1 ./bootstrap.sh` (or just step 5b/5c
standalone) to additionally produce a deterministic 1-round snapshot
corpus under `triplea/conversion/odin_tests/<proc>/snapshots/<NNNN>/`,
with RNG pinned to `PlainRandomSource.fixedSeed = 42L`. See
`README.md`.

### Phase 0.5 — Odin runtime scaffolding (one-time, before any layer-0 work)

The per-row workflow described under `llm-instructions.md` requires
these pieces to exist in the Odin tree before the first struct or
proc can be marked `is_implemented = 1`:

1. `odin_flat/game_data.odin` defining `Game_Data` (the single owning
   struct), `[dynamic]` arrays per concrete entity, and the `*_Id`
   distinct types used in place of cross-struct pointers.
2. Lookup procs (`unit_get`, `territory_get`, ...) so the JSON loader
   has a place to deposit deserialized records.
3. The Odin-side test harness, already provided by
   `bootstrap.sh` (it copies
   `templates/odin_test_common/{json_loader,game_state_compare,snapshot_runner}.odin`
   into `triplea/conversion/odin_tests/test_common/`).
4. A working `odin test` invocation that the per-proc generated test
   files (`test_<proc>.odin`, written by `process_snapshots.py`) can
   pick up.

Done when: a single layer-0 entity round-trips through `json_loader`
+ `game_state_compare` against the Phase-0 snapshot corpus.

### Phase 1 — Layer-0 structs (≈380 entities)

Pure leaves of the inheritance graph: enums, value records, pure
interfaces, and base classes that don't extend any other tracked
class. Each is ported in isolation.

Done when: every row with `id_design_layer = 0` has
`is_implemented = 1`.

### Phase 2 — Layer-1..5 structs

Depth one through five of the inheritance DAG. Each layer has all
its dependencies satisfied by the time you start.

Done when: `id_design_layer` is fully green for all layers.

### Phase 3 — Layer-0 methods (≈900 entities)

Methods that don't call any other tracked method. Mostly accessors,
predicates, simple computations.

### Phase 4..N — Layer-1..24 methods

Methods that call only methods from previous layers.

### Phase ∞ — Validation

Replay the full WW2v5 game in Odin with the same seed. JSON must be
identical to the Java capture at every step.

When a snapshot diverges, **do NOT guess**. Use the layered drill-down
procedure in `llm-instructions.md` "Layered drill-down debugging":

1. Identify the failing proc → look up its `method_layer` in
   `port.sqlite`. Mark it **red** in `test_status`.
2. Run `python3 scripts/next_task.py`. The picker chooses the
   deepest red and lists its yellow (unclassified) dependencies.
3. **Classify every yellow dependency via a fixture-driven
   golden test** (see `llm-instructions.md` §"How to classify a
   yellow proc"). Acceptable proof of green is one of:
   (a) the proc fires under a passing snapshot whose post-state
   matches `after.json`, confirmed by instrumentation; or
   (b) a targeted test that loads a real `before.json`, calls
   the proc with the parent's real call-site arguments, and
   value-compares outputs to a golden derived from Java.
   **Crash-only / non-nil / non-empty / trivial-input asserts
   are forbidden as proof of green.** Yellow means UNKNOWN, not
   "the bug"; never drill into a yellow node directly. If you
   cannot build a real golden test for a dep, leave it yellow.
4. If any sibling came back red, the picker will choose it as
   the new deepest red on the next iteration; drill there.
5. If every sibling came back green, the picker pops up to
   `INVESTIGATE_PROC` on the original red — the bug is in its
   own body. Re-read the original Java in full and fix the Odin
   port line-for-line.
6. The recursion strictly decreases layer and terminates at
   layer 0 leaves. Never write Odin logic from scratch.
7. Never mark a proc green based on "doesn't crash." False
   greens hide bugs at the wrong layer and defeat the drill-down.

## Rules

(Verbatim from `llm-instructions.md`)

- Only port entities flagged `actually_called_in_ai_test = 1` **OR** transitively
  reachable from such entities through the call graph (the closure pass in
  `build_called_layered_tables.py` already pulls these in).
- Always port in ascending layer order.
- No stubs. No "simplified". No "skipped".
- ID-based data layout.
- Match snapshot output byte-for-byte.
- RNG is `SeededRandomSource(42)` always.

## Layering policy (revised iter-7)

Two systemic bugs in the original layering caused 45% of methods to bottom
out at layer 0. Fixed in iter-7 of the pipeline:

1. **Virtual-dispatch override edges.** javap's `INVOKE_RE` records the
   *declared* receiver type from the constant pool. For
   `playerBridge.getRemoteDelegate().purchase(...)` this writes
   `proc:IPurchaseDelegate#purchase(...)` — an interface method with no
   `Code:` block, hence no outgoing edges, hence layer 0. Callers never
   saw the transitive dep on the actual `ProAi#purchase` implementation
   (which itself runs the entire AI dispatch tree). Fix:
   `build_called_layered_tables.py` now synthesizes one `override` edge
   per (abstract method M on type C) → (concrete proc S.M for every
   subtype S of C in the methods set), persisted to `dependencies` with
   `edge_kind='override'` and fed into the method-layering adjacency.
2. **Test-harness procs.** The actual top-of-stack is
   `Ww2v5JacocoRun.run`, which lives in the smoke-testing test sourceSet
   that JaCoCo doesn't instrument. The harness was therefore invisible
   to the entire pipeline. Fix: `extract_entities.py` now optionally
   scans `build/classes/java/test` (`--include-tests` /
   `INCLUDE_TEST_CLASSES=1`) and tags scanned classes
   `is_test_harness=1`. `build_called_layered_tables.py` seeds those
   procs into the methods table even without a JaCoCo flag (they're the
   drivers — they don't need one).

After the fix:
- Methods at layer 0 should number in the low hundreds (true leaves),
  not thousands.
- The chain `Ww2v5JacocoRun#run → ServerGame#runStep → … →
  IPurchaseDelegate#purchase → ProAi#purchase → …` should appear with
  monotonically descending layers.

## Tools

- `port.sqlite` — tracker database.
- `bootstrap.sh` — rebuilds the tracker from scratch.
- `scripts/extract_entities.py` — incremental rebuild after Java changes.
- `scripts/apply_jacoco.py` — re-apply coverage after a new test run.
- `scripts/build_called_layered_tables.py` — re-layer.
- `scripts/id_design_layering.py` — re-layer the ID-design DAG.

## What to track in this file as work proceeds

- Decisions about edge cases (which Java types are values vs IDs, etc.).
- Layer-completion checkpoints with dates.
- Snapshot infrastructure additions.
- Anything that the LLM should know on the next session.
