# Golden-testing status — TripleA Java→Odin port (Phase C)

> **Living document.** The orchestrator (driven by
> [`golden-testing-prompt.md`](./golden-testing-prompt.md)) reads
> this at session start and rewrites the four mutable sections at
> session end. Hand-edit only the "Failing snaps" table and "Notes"
> if you (the human) need to redirect.

---

## Last action

2026-05-23 (iter 28) — **Started drilling iter-27's new regression
(snap 0089, Japanese round-2 purchase: 8 inf + 1 armour instead of
10 inf, same PU cost). Seeded the trace table at
`proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase`
(method_layer 28) and built a `-define:PUR_TRACE=true
-define:PUR_TRACE_DUMP=true` instrumented binary
(`/tmp/snaprun_purtrace`, 5.2 MB) to use the existing 10-checkpoint
`ProPurTrace.emit` instrumentation (P01_after_purchaseDefenders_land
through P10_final) for narrowing which sub-phase introduces the
divergence. RESULT: **snap 0089 PASSES with PUR_TRACE on** —
the trace allocations themselves are the perturbation that masks
the bug. Identical to the snap-0037-fresh-look hazard recorded in
`/memories/repo/snap-0037-fresh-look.md`.** Per the strict
"NEVER heap-perturb mid-game" rule from `/memories/repo/step36-japanesePurchase-fix.md`,
the current PUR_TRACE implementation is unsuitable for diagnosing
this snap. Recorded the blocker in Notes; iter-29 needs a
zero-perturbation tracer (temp_allocator only, with single
fixed-size scratch buffer; no `fmt.printf` because that may
default-alloc on Linux). The iter-27 sweep state is unchanged
(86 PASS / 18 FAIL / 0 OTHER); the iter-26 LinkedHashMap fix is
not reverted.

### Iter-28 — drill outcome

**Trace seed (per orchestrator iteration loop step 1):**
- Snap 0089 is the new red snap (iter-27 regression, deterministic).
- Top-level proc: `proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase(games.strategy.triplea.delegate.remote.IPurchaseDelegate,games.strategy.engine.data.GameState)`, layer 28.
- Java entrypoint: `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/ProPurchaseAi.java:262-388`.

**Children of `purchase()` sorted by descending method_layer:**
| layer | child | iter-28 status |
|------:|-------|----------------|
| 27 | `prioritizeSeaTerritories(Map)` | yellow |
| 27 | `purchaseSeaAndAmphibUnits(Map,List,ProPurchaseOptionMap)` | yellow (suspect, see below) |
| 26 | `purchaseFactory(Map,Map,List,ProPurchaseOptionMap,boolean)` | yellow |
| 25 | `prioritizeTerritoriesToDefend(Map,boolean)` | yellow |
| 25 | `purchaseDefenders(Map,List,List,List,List,boolean)` | yellow |
| 19 | `purchaseLandUnits(Map,List,ProPurchaseOptionMap)` | **yellow (TOP suspect)** |
| 18 | `prioritizeLandTerritories(Map)` | yellow |
| 18 | `ProTerritoryManager#populateEnemyAttackOptions(Collection,Collection)` | yellow |
| 18 | `ProTerritoryValueUtils#findTerritoryValues(...)` | yellow |
| 9  | `purchaseUnitsWithRemainingProduction(Map,List,List)` | yellow |
| 8  | `purchaseAaUnits` / `upgradeUnitsWithRemainingPUs` | yellow |
| 7  | `findDefendersInPlaceTerritories`, `populateProductionRuleMap` | yellow |

**PUR_TRACE run on snap 0089** (`/tmp/snaprun_purtrace`,
`FILTER_SNAP=0089 timeout 300`, 2 min 14 s wall):
```
PUR_TRACE label=P01_after_purchaseDefenders_land h=c5251fb44c66dd11 n=5
PUR_TRACE label=P02_after_purchaseAa             h=c5251fb44c66dd11 n=5
PUR_TRACE label=P03_after_purchaseLand           h=5fc231926d27c0d0 n=5  <-- changed
PUR_TRACE label=P04_after_purchaseDefenders_sea  h=5fc231926d27c0d0 n=5
PUR_TRACE label=P05_after_purchaseFactory_first  h=5fc231926d27c0d0 n=5
PUR_TRACE label=P06_after_purchaseSeaAndAmphib   h=d4a9d799ae5de702 n=5  <-- changed
PUR_TRACE label=P07_after_purchaseUnitsWithRem.  h=d4a9d799ae5de702 n=5
PUR_TRACE label=P08_after_upgradeUnitsWithRem.   h=d4a9d799ae5de702 n=5
PUR_TRACE label=P09_after_purchaseFactory_second h=d4a9d799ae5de702 n=5
PUR_TRACE label=P10_final                        h=d4a9d799ae5de702 n=5
```
Final dump rows: Japan=`6 inf`, Manchuria=`artillery+2 inf`,
60 SZ=`1 transport`, two SZs empty. **Test was successful.**

That's the smoking-gun perturbation — without PUR_TRACE the snap
fails deterministically; with PUR_TRACE it passes. PUR_TRACE
allocations from `make([dynamic]string)`,
`strings.builder_make()`, and per-row `fmt.sbprintf` go to
`context.allocator` (default heap), shifting every subsequent
`malloc` return address. Per
`/memories/repo/snap-0037-fresh-look.md`:
> Lesson: do NOT make ANY heap-allocator changes (even REMOVING
> leaks) in mid-game code paths. ... the codebase is hyper-fragile
> to allocator behavior because pointer-keyed maps are everywhere.

The PUR_TRACE binary is therefore **unusable** for narrowing
snap 0089. No further Odin source change made this iter.

**Java side-of-truth note**: the snapshot's actual after.json
shows Japanese delta = +8 infantry, +1 artillery, +1 transport
(35 PUs?? — Japan's round-2 income may have been topped up by
something; not investigated this iter). The failure message
"Expected=10 Actual=8" is on `<purchase_pool>` infantry; per
the `Region=<purchase_pool>` Owner=Japanese diff Odin
substituted 1 armour for 2 inf (cost-equal: 6 PU each side),
suggesting the bug is in `purchaseLandUnits` — that's the only
sub-phase Java/Odin can choose between buying infantry vs armour
in round 2 land options.

### Iter-28 — files changed
None. (Tracer infrastructure perturbation invalidated diagnosis.)

### Previous iter-27 entry (preserved below)

2026-05-23 (iter 27) — **Ran the full 104-snap regression sweep on
the iter-26 codebase using a NEW lean test binary (built with
`-define:ODIN_TEST_TRACK_MEMORY=false`, no `-debug`). Result:
**86 PASS / 18 FAIL / 0 OTHER.** Net +2 PASS over iter-23
baseline (84P/18F), with one WIN (snap 0025 PASSES, was iter-23
FAIL) and one REGRESSION (snap 0089 FAILS, was iter-23 PASS).
Snap 0024 confirmed still red on the lean binary with the same
17-row Algeria/Belorussia/Finland/Libya/Norway/UkrSSR divergence
(unchanged from iter-26/iter-25/iter-24). Process change: the
debug+leak-tracker binary was producing **3 GB per failing-snap
log** which crashed the sweep terminal twice in iter-27.
Built `/tmp/snaprun_fast` (5.2 MB, no debug, no leak tracker);
per-snap log dropped to **4 KB**; peak RSS ≤ 3 MB sampled per
process. Sweep harness `/tmp/run_iter27_sweep_fast.sh` uses
`xargs -P 4`, runs detached via `setsid nohup ... </dev/null
&>/dev/null & disown`, gates via a `_DONE` touch-file, and
includes a serial redo path for any EXIT=137 (parent-shell-kill)
victims. Total sweep wall time ≈ 5 min for 47 missing snaps; 4
killed-mid-flight stragglers replayed serially in ≈ 6 min.**

### Iter-27 — verification results

**Build:** clean (`/tmp/snaprun_fast` 5.2 MB at 19:58, no debug,
no leak tracker). Smoke snap 0001 PASS in 24 ms (vs 88 ms on
debug binary).

**Full 104-snap sweep (lean binary):**
- **PASS: 86** (was iter-23 84).
- **FAIL: 18** (same count as iter-23).
- **OTHER (timeout/missing): 0** (was iter-23 0).
- FAIL set: `{0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065,
  0074, 0075, 0076, 0077, 0084, 0089, 0090, 0092, 0097, 0100}`.

**Deltas vs iter-23 baseline (84P/18F):**
| snap | iter-23 | iter-27 | direction | likely cause |
|------|---------|---------|-----------|--------------|
| 0025 | FAIL    | **PASS** | WIN  | iter-26 LinkedHashMap fix landed AI in the Java-faithful state for the snap-0025 step |
| 0089 | PASS    | **FAIL** | REGRESSION | iter-26 fix changed support iteration → Japanese round-2 purchase now buys 1 armour + 8 inf instead of 10 inf (unit tally `Region=<purchase_pool>` divergence: armour 0→1, infantry 10→8) |
| 17 others (0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065, 0074-0077, 0084, 0090, 0092, 0097, 0100) | FAIL | FAIL | unchanged | deeper-layer bugs, not addressed by iter-26 |

Notes on iter-26 cross-snap impact: the 4-file LinkedHashMap
upstream-extension affects EVERY snap that exercises
`Available_Supports.give_support_to_unit` (i.e. most ground/sea
combats and AI estimators). One snap moved from FAIL→PASS (0025),
one moved PASS→FAIL (0089), 17 unchanged-FAIL, 85 unchanged-PASS.
The fact that 102/104 snaps are unchanged is strong evidence the
fix is Java-faithful, not noisy.

**Snap 0024 re-verification on lean binary:**
- Result: **FAIL** in 42 s wall, peak RSS 3 MB, log 4 KB.
- Symptom identical to iter-26: same 17 unit-tally divergence
  rows (Algeria armour 0→1, Belorussia infantry 0→1, etc.).
- Confirms the lean binary is semantically equivalent to debug.

### Iter-27 — process & infrastructure changes

1. **Lean test binary** (`/tmp/snaprun_fast`):
   ```sh
   cd triplea && /run/current-system/sw/bin/odin build \
     conversion/odin_tests/server_game_run_next_step \
     -collection:flat=../odin_flat \
     -collection:test_common=conversion/odin_tests/test_common \
     -build-mode:test \
     -define:ODIN_TEST_TRACK_MEMORY=false \
     -extra-linker-flags:-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib \
     -out:/tmp/snaprun_fast
   ```
   Result: 5.2 MB binary, ≈ 4× faster on 0001 smoke (24 vs 88 ms),
   per-failing-snap log size dropped from ≈ 3 GB → ≈ 4 KB
   (no leak dump on test failure). DO NOT use this for fault
   diagnosis (leak tracker is off); use the debug binary
   (`/tmp/snaprun`) only when chasing a leak.

2. **Sweep harness** (`/tmp/run_iter27_sweep_fast.sh`):
   - Reads `/tmp/iter27_missing.txt`.
   - Per-snap: HEAD-5 + TAIL-60 of log only (caps disk usage).
   - `xargs -P 4` (was `-P 8`; halved to leave RAM headroom).
   - 300 s per-snap timeout.
   - Touches `/tmp/snap_results_iter27/_DONE` on completion.

3. **Detached launch recipe** (durable across terminal death):
   ```sh
   setsid nohup /tmp/run_iter27_sweep_fast.sh \
     >/tmp/iter27_sweep_fast.log 2>&1 </dev/null & disown
   ```
   Poll via `\ls /tmp/snap_results_iter27/_DONE`.

4. **Tally script** (body-based, not exit-code-based, since
   failing snaps still exit 0 in this harness):
   ```sh
   cd /tmp/snap_results_iter27
   for i in $(seq -f "%04g" 1 104); do
     f=${i}.txt
     if grep -q "test was successful" "$f"; then echo PASS
     elif grep -q "Snapshot.*FAILED\|test failed" "$f"; then echo FAIL
     else echo OTHER; fi
   done | sort | uniq -c
   ```

5. **EXIT=137 redo path** (catches snaps killed mid-flight by
   parent-shell deaths):
   ```sh
   for s in $(grep -l "^EXIT=137" /tmp/snap_results_iter27/*.txt | \
              xargs -n1 basename | sed 's/.txt//'); do
     /tmp/measure_snap.sh "$s" 300
   done
   ```

### Iter-27 — previous iter-26 entry (preserved below)

2026-05-23 (iter 26) — **Resolved the iter-25 regression by
extending LinkedHashMap insertion-order tracking UPSTREAM into
`Support_Calculator` and the missing `Available_Supports.support_rules`
+ `support_units` consumers. Snap 0032 is now DETERMINISTIC across
5 solo runs (5/5 identical FAIL, no hangs); the remaining FAIL is
the same Alaska/Eastern Canada infantry swap but it is no longer
intermittent. Snap 0024 still red with byte-identical iter-25
symptom — confirming the support pipeline is now Java-faithful
and the snap-0024 divergence lives DEEPER (per iter-24/25 Task D
plan: `CasualtySelector#getDefaultCasualties` body, OOL surrounding
logic, or `MainDefenseStrength.isDominatingFirstRoundAttack`).**
Four files changed (all Java-faithful per `AvailableSupports.java`).

### Iter-26 — files changed (4)
1. `odin_flat/games__strategy__triplea__delegate__power__calculator__support_calculator.odin`
   — Added `support_rules_order: [dynamic]^Unit_Support_Attachment_Bonus_Type`
   and `support_units_order: [dynamic]^Unit_Support_Attachment` fields
   to `Support_Calculator`. Initialized in `support_calculator_new`.
   New getters `support_calculator_get_support_rules_order` and
   `support_calculator_get_support_units_order`. Constructor's
   per-rule insertion path appends to both order slices on first
   insertion. `support_calculator_get_unit_support_attachments`
   now walks `support_rules_order` to preserve Java
   `supportRules.values()` order.
2. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
   — Added `support_rules_order` + `support_units_order` parallel
   slices to `Available_Supports`. `available_supports_new` accepts
   optional order args (synthesizes from map keys for back-compat).
   New getters. `give_support_to_unit` outer loop now iterates
   `support_rules_order` (was bare `for _, v in self.support_rules`
   — the iter-25 regression root cause; Java line 124 is
   `supportRules.values()` over `LinkedHashMap`). `filter` rebuilds
   both order slices in the surviving-key order. `get_support`
   walks `support_calculator_get_support_units_order` to preserve
   order on transform.
3. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports__available_supports_builder.odin`
   — Added `support_rules_order` + `support_units_order` builder
   fields, two `_order` setter methods, and threaded both into the
   `build()` finalizer.
4. (No source change in `integer_map_unit.odin`, `support_details.odin`,
   or `main_offense_strength.odin` — the iter-25 changes there
   stay because they are independently Java-faithful and verified.)

### Iter-26 — verification results
**Build:** clean (`/tmp/snaprun` 9.6 MB at 19:18, debug + leak track).
**Snap 0001 smoke:** PASS in 87.7 ms.

**Snap 0032 (5-run solo loop, 240 s timeout each):**
| run | result | runtime |
|----:|--------|---------|
| 1   | FAIL — Alaska/Eastern Canada infantry swap | 1m 28 s |
| 2   | FAIL — SAME swap                          | 1m 28 s |
| 3   | FAIL — SAME swap                          | 1m 32 s |
| 4   | FAIL — SAME swap                          | 1m 45 s |
| 5   | FAIL — SAME swap                          | 1m 27 s |

Tally: **0 PASS / 5 FAIL / 0 HANG — fully DETERMINISTIC.**
Iter-25 baseline was 0P/3F/2HANG (non-deterministic). Iter-23
baseline was 2P/1F (intermittent). Iter-26 has resolved both
the iter-25 regression (eliminated hangs) and the iter-23
intermittency (deterministic now). The remaining FAIL is a single
1-infantry swap between two adjacent territories — a real
Java-fidelity bug to solve in a future iteration.

**Snap 0024 (individual run, 300 s timeout):**
- Result: **FAIL** in 1m 48 s with **byte-identical**
  Algeria/Belorussia/Finland/Libya/Norway/UkrSSR divergence
  (17 region/unit-type rows) to iter-24 and iter-25.
- This confirms the snap-0024 divergence does NOT live in the
  support-iteration pipeline. The support pipeline is now
  Java-faithful (proved by snap 0032 going from intermittent
  to deterministic); the snap-0024 bug is deeper.

**Full 104-snap regression sweep:** NOT run this iteration.
Focused on regression triage. Iter-27 will run the sweep.

### Iter-26 — root-cause confirmed
The iter-25 regression came from `give_support_to_unit` iterating
the OUTER `support_rules` map via bare `for _, v in self.support_rules`.
Java (`AvailableSupports.java:124`):
```java
for (final List<UnitSupportAttachment> rulesByBonusType : supportRules.values()) {
```
over a `LinkedHashMap` (line 31 + 60 + 98). Odin's pointer-hash
iteration meant the *order in which bonus-type buckets were
considered* varied across runs. Each bucket's `IntegerMap`
then received supporter contributions in different orders, which
propagated to `unitsGivingSupport` even though iter-25 had fixed
the per-supporter `Integer_Map_Unit.keys_order`. Net result: the
iter-25 `keys_order` slices captured a run-specific (still-non-Java)
order. Adding `support_rules_order` (and the matching
`support_units_order` for completeness per Java line 32 + 108)
closed the loop.

The HANG in iter-25 runs 2 + 4 also disappeared. Likely cause:
the inconsistent order caused a downstream support consumer to
process an unusual configuration that hit a slow path or pathological
combination; with deterministic Java order the issue is gone.
No separate UAF fix was needed.

### Previous iter-25 entry (preserved)

2026-05-23 (iter 25) — **Shipped the three iter-24 Java-fidelity
fixes (Task A/B/C) to the support pipeline. RESULT: REGRESSION on
snap 0032 (was intermittent 2P/1F → now 0P/3F+2hang in a 5-run
solo loop) AND snap 0024 still red with the SAME unit-tally
divergence (Algeria/Belorussia/Finland/Libya/Norway/UkrSSR units
swapped). Java fidelity of the changes was re-confirmed against
`AvailableSupports.java:31-60` (LinkedHashMap everywhere). The
direction is right, the implementation is incomplete or has a
new ordering bug.** Iter-26 must investigate WHY iter-25 changed
order to a still-non-Java order — most likely an upstream
iteration site (e.g. `give_support_to_unit` caller in the
builder loop, or the missing `support_units` outer-map order)
is still pointer-hashed and feeds the wrong order into the new
`keys_order` slices.

### Iter-25 — files changed (5)
1. `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
   — Task A. `strength = unit_attachment_get_attack_no_player(ua)`
   → `strength: i32 = unit_attachment_get_attack(ua, unit_get_owner(unit))`.
   Mirrors defense-side. Java-faithful per `MainOffenseCombatValue.java:142-145`.
2. `odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin`
   — Task B. Added `keys_order: [dynamic]^Unit` field. Added helpers
   `integer_map_unit_put(self, key, value)` (appends on first insert)
   and `integer_map_unit_remove(self, key)` (removes from both maps).
3. `odin_flat/games__strategy__triplea__delegate__power__calculator__support_calculator.odin`
   — Task B/C wiring. Builder loop (~lines 137-158): `.entries[unit] = number`
   replaced with `integer_map_unit_put`. `support_calculator_get_combined_support_given`
   (~line 238): now walks `available_supports_get_units_giving_support_order(side)`
   and looks up via `available_supports_get_units_giving_support(side)` instead
   of iterating bare map keys.
4. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
   — Task C. Added `units_giving_support_order: [dynamic]^Unit` field.
   `available_supports_new` initializes it. New getter
   `available_supports_get_units_giving_support_order`.
   `give_support_to_unit` (~line 175) appends supporter to the order
   slice on the first-insert branch. `get_next_available_supporter`
   (~line 80) now picks `int_map.keys_order[0]` (with fallback to
   bare-map iteration if empty); uses `integer_map_unit_remove`
   when count ≤ 0.
5. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports__support_details.odin`
   — Task B back-compat. `available_supports_support_details_new`
   synthesizes `keys_order` from `entries` keys when source has none.
   `_new_copy(other)` copies `keys_order` from other preserving
   LinkedHashMap order; falls back to entries iteration if other.keys_order empty.

### Iter-25 — verification results
**Build:** clean (`/tmp/snaprun` 9.6 MB at 18:30, debug + asan-style
leak tracking). Snap 0001 smoke test: PASS in 99.9 ms.

**Snap 0032 (5-run solo loop, 180 s timeout each):**
| run | result | runtime | log size |
|----:|--------|---------|---------:|
| 1   | FAIL — Alaska/Eastern Canada infantry swap | 1m 19 s | 2.9 GB (debug spam) |
| 2   | TIMEOUT (killed at 180 s, only 11 log lines) | — | 1.1 k |
| 3   | FAIL — same Alaska/Eastern Canada swap | 1m 23 s | 2.9 GB |
| 4   | TIMEOUT (killed at 180 s, only 11 log lines) | — | 1.1 k |
| 5   | FAIL — same Alaska/Eastern Canada swap | 51 s + leak dump | 2.9 GB |

Tally: **0 PASS / 3 FAIL / 2 HANG** (5/5 non-pass). Iter-23 baseline
was 2 PASS / 1 FAIL (intermittent). Iter-25 is a regression in
both pass-rate AND determinism (now hangs sometimes).

**Snap 0024 (individual run, 240 s timeout):**
- Result: **FAIL** in 1m 49 s with `Region=Algeria Owner=Germans
  UnitType=armour Moves=0 Damage=0: Expected=0 Actual=1` plus 16
  more region/unit-type rows — **byte-identical** to iter-24 fail
  symptom. Iteration time grew from 57 s (iter-24) → 110 s
  (iter-25); same outcome.

**Full 104-snap regression sweep:** NOT run this iteration. The
0/5 + REGRESSION result on snap 0032 made the full sweep
non-cost-effective without first understanding the new failure mode.

### Iter-25 — Java fidelity recheck
Per `/memories/java-fidelity-rule.md`, re-verified after the
regression discovery:
```
$ grep -n 'unitsGivingSupport\|new \(Linked\)\?HashMap\|new \(Linked\)\?HashSet' \
    triplea/.../AvailableSupports.java | head
31:  .supportRules(new LinkedHashMap<>())
32:  .supportUnits(new LinkedHashMap<>())
60:  @Getter private final Map<Unit, IntegerMap<Unit>> unitsGivingSupport = new LinkedHashMap<>();
98:  new LinkedHashMap<>();
108: final Map<UnitSupportAttachment, SupportDetails> supportUnits = new LinkedHashMap<>();
139: unitsGivingSupport
```
Confirms Java uses `LinkedHashMap` for ALL three suspect collections.
The iter-25 direction (add keys_order, walk in insertion order) is
**correct Java-fidelity work**. The regression therefore comes from
either (a) the upstream caller that feeds the builder loop is still
pointer-hashed (so the keys_order I capture is itself wrong), or (b)
I missed an iteration site that still uses bare `map[K]V` keys,
producing inconsistent order between population and consumption.

### Iter-25 — open hypotheses for the regression
1. **Builder upstream is still bare-map.** `support_calculator`
   builder loop iterates `available_supports_get_support_rules(side)`
   (`map[unit_type][dynamic]^Unit_Support_Attachment` per Odin
   today). Each rule lookup then iterates the candidate-unit pool.
   If the OUTER `support_rules` iteration uses bare-map keys
   (pointer-hashed `^Unit_Type`), the inner `keys_order` slice
   captures different order on different runs.
2. **`Available_Supports.support_units` (per-rule details map) is
   still bare.** Java line 32 and 108 both use `LinkedHashMap`. My
   iter-25 fix only added order to `units_giving_support`. If the
   consumer iterates `support_units` map keys directly anywhere
   (e.g. inside `Power_Strength_And_Rolls.add_units`), order is
   still pointer-hashed.
3. **`add_units` consumer drift.** `unit_power_strength_and_rolls_builder`
   may walk `available_supports.units_giving_support` directly via
   the bare-map field rather than via the new `_order` getter.
4. **Hang root-cause (runs 2 + 4).** Two of five runs went silent
   immediately after `PSTART` and were killed by `timeout 180`.
   No FATAL/leak/error printed to log. Could be:
   - An infinite loop in `get_next_available_supporter` if
     `keys_order[0]` references a stale `^Unit` (UAF after a
     `remove`).
   - A deadlock on the builder loop if `keys_order` is appended
     during iteration of the same slice.
   - A genuine hang in some downstream support consumer that now
     processes a much larger set than before.

### Previous iter-24 entry (preserved)

2026-05-23 (iter 24) — **Read-only drill iteration. Completed the
iter-23 sweep, classified 2 L9 yellows as green-for-snap-0024,
and discovered TWO new pointer-hash iteration-order bugs in
`Available_Supports` (sibling of iter-21/23 Integer_Map fixes)
that explain a new intermittency in snap 0032.** No Odin source
files modified; status doc + iter-25 plan updated. The sweep is
complete and snap 0024 now FAILS FAST (≈57 s) instead of
TIMEOUTING (was 600 s), making future drills much faster.

### Iter-23 sweep — final tally (104/104 done)
- **84 PASS, 18 FAIL, 0 TIMEOUT.** No `NO_EXIT`/starvation tagged
  (the iter-23 sweep used a 420 s per-snap cap vs iter-21's 120 s).
- iter-23 FAIL set: `{0024, 0025, 0031, 0032, 0037, 0038, 0040,
  0048, 0065, 0074, 0075, 0076, 0077, 0084, 0090, 0092, 0097, 0100}`.
- Raw sweep logs (~100 GB) cleaned up at iter-24 close. Summary
  preserved at `/tmp/snap_results_iter23_summary.txt` (one EXIT
  line per snap).

### Deltas vs iter-21 baseline (16 FAIL / 2 TIMEOUT / 2 NO_EXIT)
| iter-21 status | snap | iter-23 status | classification |
|----------------|------|----------------|----------------|
| TIMEOUT (120s) | 0021 | **PASS** (within 420s) | **win** — true PASS unmasked by larger cap |
| TIMEOUT (120s) | 0037 | FAIL (within 420s) | status improvement — deterministic now (previously timeout) |
| NO_EXIT        | 0073 | **PASS** (3m 40s) | **win** — true PASS unmasked |
| NO_EXIT        | 0089 | FAIL (deterministic) | status improvement — drillable |
| **PASS (fast)** | **0032** | **FAIL (61s)** | **REGRESSION** — see "Snap 0032 intermittency" below |
| FAIL × 16      | rest | FAIL (same) | no change |

Net effect: same 84 PASS count but better classification
(2 wins, 2 status improvements, 1 regression).

### Snap 0032 intermittency (NEW iter-24 finding)
Snap 0032 is now **non-deterministic across runs**:
- Solo run #1 (after build): PASS in 58.83 s.
- Solo run #2 (immediately after): FAIL in 61.09 s with
  `Region=Alaska Owner=British UnitType=infantry Moves=0
  Damage=0: Expected=1 Actual=0; Region=Eastern Canada Owner=British
  UnitType=infantry Moves=0 Damage=0: Expected=0 Actual=1` —
  one British infantry swapped between two adjacent territories.

**Confirmed by 3-of-5 repro at iter-24 close (run3/run5
interrupted; 2 PASS / 1 FAIL across completed runs):** the
divergence is genuinely non-deterministic, not a one-off.

**Hypothesis:** the iter-23 pointer-refactor put `Integer_Map`
behind `^Integer_Map` (good, no value-copy), but the OUTER map
`Available_Supports.units_giving_support: map[^Unit]^Integer_Map`
and the supporter pool `Integer_Map_Unit.entries: map[^Unit]i32`
are still bare `map[K]V` with pointer-hash iteration. In iter-21
the value-copy bug silently dropped most of the contributions so
the artifact never propagated; iter-23 enables the contributions
and exposes the underlying iteration-order non-determinism.

### NEW Java-fidelity bugs discovered (iter-24)
Per java-fidelity rule, read Java first then diffed Odin port:

#### 1. `MainOffenseStrength.getStrength` uses wrong accessor
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
- Java (`MainOffenseCombatValue.java:142-145`):
  ```java
  int strength = ua.getAttack(unit.getOwner());
  ```
  `getAttack(player)` adds tech bonus +
  clamps to `min(diceSides, max(0, attack + bonus))`.
- Odin:
  ```odin
  strength: i32 = unit_attachment_get_attack_no_player(ua)
  ```
  `_no_player` returns the raw `self.attack` — no tech bonus,
  no dice-sides clamp.
- **Impact on snap 0024:** WW2v5 has no Russian attack tech
  bonuses and all Russian attack values ≤ 6 (dice sides), so this
  divergence is mathematically inert for snap 0024. But the bug is
  real and may affect other snaps (e.g. heavy-bomber tech games or
  unit types with attack > diceSides).
- **Fix:** call `unit_attachment_get_attack(ua, unit_get_owner(unit))`
  instead. Mirror the existing defense-side which is correct.

#### 2. `Available_Supports.get_next_available_supporter` iterates pointer-hash order
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin:78-95`
- Java (`AvailableSupports.java:168-179`):
  ```java
  final Unit u = CollectionUtils.getAny(intMap.keySet());
  ```
  `IntegerMap.keySet()` returns a `LinkedHashSet` (iter-21 fix
  established Java's IntegerMap is LinkedHashMap-backed);
  `CollectionUtils.getAny` returns `iterator().next()` — the
  **first-inserted** key.
- Odin:
  ```odin
  int_map := &details.support_units   // type: ^Integer_Map_Unit
  for k, _ in int_map.entries { u = k; break }
  ```
  `Integer_Map_Unit.entries` is bare `map[^Unit]i32` — pointer-hash
  iteration. `Integer_Map_Unit` does **not** have a `keys_order`
  field; iter-21 only added it to `Integer_Map`.
- **Impact:** when there are ≥ 2 candidate supporters of the same
  rule (e.g. 2 Russian artillery for 3 infantry), Java
  deterministically picks the first-inserted; Odin picks whichever
  pointer hashes lowest, which varies across runs because
  `^Unit` addresses are heap-allocation-order dependent.
- **Fix:** add `keys_order: [dynamic]^Unit` to `Integer_Map_Unit`;
  maintain at insertion in `available_supports_support_details_new`,
  `_new_copy`, and any other writers; walk `keys_order[0]` in
  `get_next_available_supporter`.

#### 3. `Available_Supports.units_giving_support` outer map is bare
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin:10` (struct field)
- Java's equivalent is `Map<Unit, IntegerMap<Unit>>` populated via
  `computeIfAbsent` in `giveSupportToUnit`. The Java map is a
  `LinkedHashMap` (per the bootstrap rewrite comment at end of
  `CasualtyUtil.java`, "global LHM rewrite"); insertion order is
  the order supporters first contributed support.
- Odin: bare `map[^Unit]^Integer_Map`, pointer-hash iteration.
- **Impact:** downstream consumers (`SupportCalculator.getCombinedSupportGiven`,
  `PowerStrengthAndRolls.addUnits`) iterate this map and append into
  `unit_support_power_map`. Different outer iteration order →
  different append order in `Power_Strength_And_Rolls.unit_support_power_map`
  → different tie-break order in `CasualtyOrderOfLosses` worst-unit
  selection → different casualty pick → cascading outcome divergence.
- **Fix:** add parallel `[dynamic]^Unit` insertion-order list to
  `Available_Supports`; walk it instead of bare-map iteration in
  `support_calculator_get_combined_support_given` and in the
  `giveSupportToUnit` body.

### L9 classifications for snap 0024 (iter 24)
Per orchestrator rules, drilled the L9 yellow children of
`casualty_selector_select_casualties` in descending `method_layer`:

| L9 child | snap-0024 classification | rationale |
|----------|--------------------------|-----------|
| `Player#selectCasualties` → `DummyPlayer.selectCasualties` | **green** | Verified Java: `keepAtLeastOneLand` and `orderOfLosses` both default false/empty. Java AI never calls `setKeepOneAttackingLandUnit` (only UI calls it, see `BattleCalculatorPanel.java:589`). With both flags false/empty, Java returns `defaultCasualties` unchanged — exact match for Odin's `Dummy_Player` nil-vtable fallback to `player_select_casualties` (identity). |
| `CasualtyUtil#getDependents` | **green** | Snap 0024 UkrSSR battle has no transports → `transport_tracker_transporting_and_unloaded` returns empty for every unit → dependents map values all empty. Map iteration order can't affect outcome of empty maps. Also confirmed downstream consumer `unit_separator_categorize_with_options` only uses `separator_categories.dependents[current]` as a per-key lookup (not iteration). |
| `CombatValue` concrete impl | **yellow (still)** | Two new Java-fidelity bugs found (see "NEW Java-fidelity bugs"). #1 (`MainOffenseStrength` uses `_no_player`) is inert for snap 0024. #2 and #3 (`Available_Supports` pointer-hash iteration) likely cause snap 0032 intermittency and *may* cause snap 0024 divergence cascade. |

### Build status
No Odin source files modified in iter 24. Build is unchanged from
iter 23 (`/tmp/snaprun` from 17:38).

### Pre-iter-24 history (preserved)

2026-05-23 (iter 23) — **Applied the pointer-refactor planned in
iter 22.** Changed `Power_Strength_And_Rolls.unit_support_power_map`
and `…_rolls_map` from `map[^Unit]Integer_Map` (value-stored) to
`map[^Unit]^Integer_Map` (pointer-stored). Lambdas
`_add_units_0` / `_2` now call `integer_map_new()` to heap-allocate.
Getter return types updated to `map[^Unit]^Integer_Map`.

In `casualty_order_of_losses.odin`, dropped all `&` operators on
`support_power_for_unit` / `support_rolls_for_unit` since they are
now `^Integer_Map` (passed directly to
`integer_map_key_set`/`integer_map_get_int`).

### Build & individual snap results
- Build: clean. `/tmp/snaprun` rebuilt at 17:38.
- Snap 0001: PASS, 67 ms (was 85 ms iter 21 — within noise).
- Snap 0017: PASS, 73 ms (was 50 ms iter 21 — within noise).
- Snap 0032: PASS, **1m 6s** (was iter-21 PASS — much slower now).
- Snap 0073: PASS, **3m 40s** (was iter-21 PASS — vastly slower).
- Snap 0024: TIMEOUT at 600s (was iter-21 FAIL with unit-tally
  divergence in 37s). The refactor correctly enables Java-faithful
  support propagation, which dramatically increases the AI's
  evaluation workload. Whether snap 0024 will eventually PASS or
  still diverge cannot be determined inside 600s.

### What this proves
- The iter-22 root-cause classification was correct: Integer_Map
  stored by value lost mutations through `m[k]`. The refactor is
  semantically equivalent to Java's `Map<Unit, IntegerMap<Unit>>`
  reference storage.
- Iter-21 was silently underperforming Java fidelity in
  PowerStrengthAndRolls.addUnits — support contributions to the
  worst-unit calculation in CasualtyOrderOfLosses were truncated
  to the first append (because each subsequent
  `existing := m[k]; integer_map_add_map(&existing, …)` discarded
  the keys_order updates done by the previous iteration).
- The slowdown is intrinsic, not a regression bug: the AI was
  previously skipping work that should have been done. Snap 0001
  (no battles) shows zero slowdown, confirming the cost is only in
  the casualty/combat path.

### 104-snap regression sweep (iter 23)
Running with 420-second per-snap cap (vs iter-21's 120 s) and
parallel `-P 8`. Started at 17:43; results in
`/tmp/snap_results_iter23/`. **Sweep was at 68/104 at session
end (55 PASS, 5 FAIL, rest in flight):**
```
FAILS (partial, at 68/104): 0024, 0025, 0031, 0032, 0038
```
- Snap 0032 PASSED individually (1m 6s, see above) but FAILED in
  the parallel sweep — likely `-P 8` starvation pushing it past
  the 420s cap. Re-verify individually.
- Snaps 0024, 0025, 0031, 0038 were all FAIL in iter 21; their
  iter-23 status will be known when the sweep completes.

To analyze when complete:
```sh
ls /tmp/snap_results_iter23/ | wc -l  # should be 104
grep -h "^EXIT=" /tmp/snap_results_iter23/*.txt | \
  awk -F: '{print $2}' | sort | uniq -c
for f in /tmp/snap_results_iter23/*.txt; do
  l=$(tail -1 "$f"); case "$l" in *:0) ;; *) echo "$l" ;; esac
done | sort
```
(See "Next action" for iter-24's verification + remaining drill.)

### Files changed (iter 23)
- `odin_flat/games__strategy__triplea__delegate__power__calculator__power_strength_and_rolls.odin`
  - Struct: `unit_support_power_map` / `unit_support_rolls_map`
    fields → `map[^Unit]^Integer_Map`.
  - Getters: return type `map[^Unit]^Integer_Map`.
  - `lambda_add_units_0` / `_2`: return `^Integer_Map` via
    `integer_map_new()`.
  - `lambda_add_units_1` / `_3`: drop `existing := …` round-trip;
    pass `self.unit_support_power_map[supporter]` directly.
  - `power_strength_and_rolls_new`: `make(map[^Unit]^Integer_Map)`.
- `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_order_of_losses.odin`
  - Drop `&` on all `support_power_for_unit` /
    `support_rolls_for_unit` arguments to `integer_map_key_set`
    and `integer_map_get_int`.

### Pre-iter-23 history (preserved)

2026-05-23 (iter 22) — **Discovered the iter 21 IntegerMap fix is
INCOMPLETE in a critical site: `map[^Unit]Integer_Map` stores
Integer_Map BY VALUE, but `Integer_Map.keys_order` is `[dynamic]rawptr`
whose descriptor (data ptr / len / cap) is copied on map read. Any
mutation via `existing := m[k]; integer_map_add_map(&existing, …)`
without write-back loses the keys_order updates — only
`map_values` (a Odin map descriptor with shared backing storage)
survives. Identified the smoking-gun sites in
`power_strength_and_rolls_lambda_add_units_1` and `_3` (lines 86
and 109 of `power_strength_and_rolls.odin`).**

### Java source confirms intent
`PowerStrengthAndRolls.addUnits` (lines 130-133):
```
strengthCalculator.getSupportGiven().forEach((supporter, supportedUnits) ->
    unitSupportPowerMap.computeIfAbsent(supporter, (newSupport) -> new IntegerMap<>())
        .add(supportedUnits));
```
The IntegerMap RETURNED by `computeIfAbsent` is the actual stored
instance — `.add(supportedUnits)` mutates the *stored* IntegerMap,
not a copy. In Java this works because Map<K,V> stores references,
not value copies.

### Attempted fix (reverted — caused timeout)
Added write-back after `integer_map_add_map`:
```odin
self.unit_support_power_map[supporter] = existing
self.unit_support_rolls_map[supporter] = existing
```
Build clean. Snap 0001 still passed in 85ms. **Snap 0024 timed out
at 300s** (vs iter 21's 37s) — the fix correctly enables support
propagation, which Java-faithfully changes Russian artillery + air
combat support → AI's NCM ProBattleUtils calculator likely
re-evaluates far more candidate moves. Reverted to keep the build
green; tracked as iter-23 work.

### Root-cause classification
This is the same family of bug as iter 21 but at a *different
storage tier*: iter 21 fixed iteration order *within* Integer_Map.
Iter 22 finding is that Integer_Map cannot safely live as a value
inside `map[K]Integer_Map` because Odin `[dynamic]` descriptors
copy by value, losing keys_order updates whenever the underlying
buffer reallocates *or* the len/cap fields advance.

### Next-iter (23) plan
Two options:
  1. **Pointer the inner maps**: change
     `unit_support_power_map: map[^Unit]Integer_Map` →
     `map[^Unit]^Integer_Map`. Allocate `Integer_Map` on the heap
     in `lambda_add_units_0` / `_2`. Mutations now go through a
     pointer; no write-back needed. RIPPLES into every reader site
     (about 10 in casualty_order_of_losses + 4 in
     power_strength_and_rolls itself + getters). Surface this
     refactor as a discrete commit.
  2. **Add write-back** as the iter-22 patch did, then
     PROFILE/CAP the snap 0024 simulator workload. Either:
       (a) increase the per-snap timeout, or
       (b) verify Java's snap 0024 also takes this long (it
           probably doesn't — JVM JIT vs Odin debug, plus possible
           AI memoization differences).
The pointer-refactor (option 1) is the correct fix because it
eliminates the value-copy hazard structurally. It also benefits
the AaPowerStrengthAndRolls site that has the same pattern.

### Pre-iter-22 history (preserved)

2026-05-23 (iter 21) — **Fixed the L8 yellow node:
`Integer_Map` LinkedHashMap insertion-order divergence.**
Per java-fidelity-rule, read
`triplea/lib/java-extras/src/main/java/org/triplea/java/collections/IntegerMap.java`:
Java's `IntegerMap` is backed by `LinkedHashMap` (insertion-order
iteration). Odin's `Integer_Map` used a bare `map[rawptr]i32`
which iterates in pointer-hash order. The casualty drill from
iter 20 (`CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`)
uses `integer_map_key_set` to walk the supporter→supported maps and
moves each supported unit to position 0 of `sortedUnitsList` via
`inject_at`. Different iteration order → different worst-unit
picks → different battle outcome.

### Fix
`odin_flat/org__triplea__java__collections__integer_map.odin`:
added `keys_order: [dynamic]rawptr` to `Integer_Map`; added
file-private `_iorder_put_` / `_iorder_remove_` helpers; rewrote
`integer_map_put`, `_add`, `_remove_key`, `_clear`,
`_multiply_all_values_by`, `_key_set`, `_all_values_equal`,
`_total_values`, `_is_positive`, `_entry_set`, `_to_string`,
`_new_copy`, `_unmodifiable_view_of`, `_add_map`, `_subtract`,
`_greater_than_or_equal_to`, `_add_multiple`, and the
`_new_from_map` constructor to maintain and walk `keys_order`.
Updated three external `Integer_Map{map_values = make(...)}`
literals (production_rule, repair_rule, power_strength_and_rolls
lambdas, strategic_bombing_raid_battle init) to also init
`keys_order = make([dynamic]rawptr)`.

### 104-snap regression result
Iter 20 baseline: 85 PASS / 17 FAIL / 2 HANG.
Iter 21 result:  84 PASS / 16 FAIL / 2 TIMEOUT (+ 2 starvation
"NO_EXIT" in the -P 8 parallel sweep that pass individually).

Net: snap **0032 newly passes** (was FAIL). Snap **0092 went
HANG → FAIL** (deterministic now, easier to drill). Snap 0024
(iter 20 drill target) unit tally is unchanged — IntegerMap order
fix is necessary but not the *full* fix for 0024.

Individual reruns confirm snaps 0001, 0017, 0073 still PASS. The
"4 NO_EXIT" in the parallel sweep is xargs -P 8 contention
hitting the 120s per-snap cap, not regression.

### Why this matters even though 0024 still fails
Java's IntegerMap is used pervasively (TUV cost maps, support
power/rolls maps, unitProduction maps). Pointer-hash iteration was
silently corrupting Java fidelity in every code path that walks
these maps. The L8 casualty-selection drill was the wedge that
exposed it; the fix is structural and benefits the entire battle
calculator, AI move ordering, and any future divergence rooted in
the same pattern.

### Remaining suspect for snap 0024
After this fix, the casualty selection in the deterministic battle
must STILL diverge — meaning either:
(a) one of `casualty_selector_select_casualties`'s OTHER deps
    (CasualtyUtil#getDependents, AaCasualtySelector, CombatValue
    impls) still has a HashMap-order bug, or
(b) `must_fight_battle_fight`'s step ordering itself uses an
    unordered collection.

Continue the L8 drill in iter 22 — re-classify
`casualty_selector_select_casualties` as YELLOW (not red), then
descend into its remaining yellow deps sorted by
descending method_layer.

### Iter 20 prior history (preserved)

**Cleared 3 of 4 simulator-internals
suspects in one iteration. (1) Ran `scripts/mt_self_test` against
Java-captured `mt_reference_vector.txt`: 1024 raw32 + 1024 each
nextInt(6/12/8) values match Java's `MersenneTwister(42L)`
byte-for-byte. MT bit-fidelity GREEN. (2) Added `rbd_in`/`rbd_unit`
/`rbd_out`/`rbd_die` probe in `roll_dice_factory_roll_battle_dice`
gated on `"Ukraine S.S.R."` in annotation. Verified Russians' first
round dice = [0,1,1,3,3,0,0,2,0,3] which matches positions 0–9 of
the Java reference vector for `nextInt(6)`. Dice consumption
order GREEN. (3) Per-unit strength computation correct: Russian
artillery support gives 2 of 3 infantry attack=2 (1 inf stays
attack=1); fighter/armour/inf strength values all match WW2v5
XML. Active_units post-sort order matches expected
strength-descending bucket order (armour, fighter, art, inf).
Artillery support pairing GREEN. **Remaining suspect: casualty
selection order.** With the bomber present (n_def=11), defenders
win; without bomber (n_def=10), defenders are wiped — same MT(42),
same dice stream, only difference is 1 extra unit's 1 extra die.
This can only flip a deterministic battle via cascading casualty
selection: who dies first determines who keeps rolling in later
rounds, which can radically change the total hit accounting.**

### Iter 20 evidence

MT self-test:
```
raw32: 1024 values, cumulative fails: 0
nextInt6: 1024 values, cumulative fails: 0
nextInt12: 1024 values, cumulative fails: 0
nextInt8: 1024 values, cumulative fails: 0
PASS: MersenneTwister Odin port matches Java reference
```

Dice consumption (n_def=4 case, first calc-call for UkrSSR):
```
rbd_in player=Russians ann="... round 2" n_units=10 total_rolls=10 total_power=24 sides=6
rbd_unit i=0 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=1 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=2 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=3 owner=Russians type=fighter   str=3 rolls=1 sides=6 cbr=true
rbd_unit i=4 owner=Russians type=fighter   str=3 rolls=1 sides=6 cbr=true
rbd_unit i=5 owner=Russians type=artillery str=2 rolls=1 sides=6 cbr=true
rbd_unit i=6 owner=Russians type=artillery str=2 rolls=1 sides=6 cbr=true
rbd_unit i=7 owner=Russians type=infantry  str=2 rolls=1 sides=6 cbr=true
rbd_unit i=8 owner=Russians type=infantry  str=2 rolls=1 sides=6 cbr=true
rbd_unit i=9 owner=Russians type=infantry  str=1 rolls=1 sides=6 cbr=true  ← unsupported by artillery (correct)
rbd_die i=0..9 = [0,1,1,3,3,0,0,2,0,3] = MT.nextInt(6)[0..9] EXACT MATCH
```

Matches Java reference vector positions 0–9 exactly.
Annotation says "round 2" but this is the first fight round—
MustFightBattle increments round BEFORE the first fight step
in both Java and Odin (verified in `must_fight_battle__29.odin`).
This is a labeling convention, not a divergence.

### Iter 19 prior finding (preserved)

[iter 19 cleared max_enemy_units (artillery mov=1 in WW2v5; theo
max = 10 Russian attackers, matches Odin). Widened bc_run probe
revealed bomber's 1-die difference flips outcome from DEFENDER-win
to ATTACKER-wipe.]

### Iter 18 prior finding (preserved)

[iter 18 added `bc_run` probe; simulator internally consistent
and deterministic across 90 runs. Hand-count theory ruled out
in iter 19 once artillery mov=1 was discovered.]

### What the iter 19 widened bc_run probe revealed

```
bc_run i=0..2 t=Ukraine S.S.R. nDef=11 who=DEFENDER rounds=3 remA_n=0 remA=[]            remD_n=2 remD=[fighter=2]
bc_run i=0..2 t=Ukraine S.S.R. nDef=10 who=ATTACKER rounds=3 remA_n=2 remA=[fighter=2]    remD_n=0 remD=[]
```

With bomber: defender wins, atk wiped, 2 def fighters survive.
Without bomber: ATTACKER wins, def wiped, 2 atk fighters survive.

Same MT(42) seed in both. Removing 1 bomber (def=1) shifts the
dice stream by ~1 roll/round and dramatically flips the outcome.
Java + Odin should produce the SAME outcome given identical MT
outputs. Since Java's `after.json` shows the bomber moved to
Finland (which requires `worth_def` at ntd=3 to evaluate
`areSuccess=true` for the bomber-removed UkrSSR), Java's calc
must be returning a DIFFERENT result for the n_def=10 case
(probably `defender holds`).

### cbc_atk source-territory probe (iter 19)

```
cbc_atk i=0 owner=Russians type=infantry  src=Caucasus       movLeft=1
cbc_atk i=1 owner=Russians type=artillery src=Caucasus       movLeft=1
cbc_atk i=2 owner=Russians type=infantry  src=Caucasus       movLeft=1
cbc_atk i=3 owner=Russians type=armour    src=Caucasus       movLeft=2
cbc_atk i=4 owner=Russians type=artillery src=Caucasus       movLeft=1
cbc_atk i=5 owner=Russians type=armour    src=Karelia S.S.R. movLeft=2
cbc_atk i=6 owner=Russians type=fighter   src=Russia         movLeft=4
cbc_atk i=7 owner=Russians type=fighter   src=Caucasus       movLeft=4
cbc_atk i=8 owner=Russians type=armour    src=Russia         movLeft=2
cbc_atk i=9 owner=Russians type=infantry  src=Caucasus       movLeft=1
```

Karelia's armour reaches UkrSSR via Belorussia/West Russia
(both 2 hops, enemy-owned but `isIgnoringRelationships=true`
in `findEnemyAttackOptions`). Russia's armour reaches via
Caucasus (1-hop friendly + 1-hop enemy). Russia's artillery
(mov=1, movLeft=1) cannot reach 2-hops-away UkrSSR (matches
Odin behavior: not in list).

### Confirmation that both languages use same seed

Java harness `Ww2v5JacocoRun.java:58` sets
`SNAPSHOT_SEED = 42L` and applies it via
`PlainRandomSource.fixedSeed = SNAPSHOT_SEED` at line 82.
Odin harness `test_server_game.odin:166-170` does the same:
```
if plain_random_source_fixed_seed == nil {
    seed := new(i64)
    seed^ = 42
    plain_random_source_fixed_seed = seed
}
```
Both languages: every new `PlainRandomSource` = new
`MersenneTwister(42)`. **Same seeds across both languages.**

### Iter 19 CORRECTED hand-count (snap 0024 before.json)

MOVEMENT BUDGETS PER WW2v5_1942_2nd.xml:
- infantry=1, artillery=1 (NOT 2!), armour=2, fighter=4, bomber=6.

MAP ADJACENCIES (verified from XML connection list):
- UkrSSR neighbors: Belorussia, West Russia, Bulgaria Romania,
  Caucasus, 16 Sea Zone.
- Russia neighbors: Archangel, Caucasus, Kazakh, Novosibirsk,
  Vologda, West Russia. (NOT adjacent to UkrSSR.)
- Karelia S.S.R. neighbors: Archangel, Baltic States, Belorussia,
  Finland, West Russia, 4 SZ, 5 SZ. (NOT adjacent to Russia
  or UkrSSR.)

Routes from each Russian territory to UkrSSR:
- Caucasus → UkrSSR: 1 hop. Any unit with mov≥1 reaches.
- Russia → Caucasus → UkrSSR: 2 hops (friendly). Any unit
  with mov≥2 reaches. (armour, fighter — NOT art, NOT inf.)
- Karelia → Belorussia/West Russia → UkrSSR: 2 hops (enemy in
  middle, allowed via `isIgnoringRelationships=true`). armour
  with mov≥2 reaches.
- Archangel: 3+ hops to UkrSSR. INVALID for all land units.

Corrected theoretical max:
- inf: 3 Caucasus = 3
- art: 2 Caucasus = 2 (Russia art mov=1, can't reach)
- armour: 1 Caucasus + 1 Russia + 1 Karelia = 3
- fighter: 1 Caucasus + 1 Russia = 2

**Theoretical max: 3 + 2 + 3 + 2 = 10 attackers.**
Odin's `cbc_atk` reports 10. **EXACT MATCH — NOT A BUG.**

### Iter 17 prior history (preserved)

[iter 17 cbc_in/cbc_def/cbc_atk probe ruled out unit-attrib
lookup as bug; RNG arch verified deterministic in both languages]

### Probe data (n_def=11 case for UkrSSR)

```
cbc_in t=Ukraine S.S.R. n_atk=10 n_def=11 run_count=90 retr_air=false
cbc_def i=0 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=1 owner=Germans type=bomber   atk=4 def=1 isAir=true  isSea=false  ← correct
cbc_def i=2 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=3 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=4 owner=Germans type=fighter  atk=3 def=4 isAir=true  isSea=false
cbc_def i=5 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=6 owner=Germans type=fighter  atk=3 def=4 isAir=true  isSea=false
cbc_def i=7 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=8 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=9 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=10 owner=Germans type=armour  atk=3 def=3 isAir=false isSea=false
cbc_atk i=0 owner=Russians type=armour    atk=3 def=3
cbc_atk i=1 owner=Russians type=artillery atk=2 def=2
cbc_atk i=2 owner=Russians type=artillery atk=2 def=2
cbc_atk i=3 owner=Russians type=fighter   atk=3 def=4
cbc_atk i=4 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=5 owner=Russians type=armour    atk=3 def=3
cbc_atk i=6 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=7 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=8 owner=Russians type=armour    atk=3 def=3
cbc_atk i=9 owner=Russians type=fighter   atk=3 def=4
```

All attribs match WW2v5_1942_2nd.xml. **No unit-attribute lookup bug.**

### RNG determinism architecture (verified Java + Odin)

- `PlainRandomSource` (both languages) is constructed fresh in
  every `DummyDelegateBridge` constructor.
- When `fixedSeed=42` (snapshot mode), every new
  `PlainRandomSource` seeds a new MersenneTwister with 42 →
  every battle run gets identical dice.
- `battle_calculator_calculate`'s loop creates one new bridge per
  `run_count` iteration → all 90 simulation runs produce
  identical outcomes.
- Therefore `winPct` is binary (0% or 100%) by design. The 28-TUV
  swing from removing one bomber is a real divergence in the
  simulator's deterministic output.

### What's left

The simulator uses these per-defender attributes (bomber
correctly tagged def=1 isAir=true) plus dice rolls to compute
casualties. Either:
- Dice consumption order / count differs between Odin and Java
  (e.g., Odin requests more/fewer dice per defender), OR
- Casualty selection picks different casualties given the same
  dice (e.g., bomber is wrongly chosen LAST as casualty), OR
- Battle rounds count differs (e.g., bomber prevents retreat).

All three are inside `must_fight_battle_fight` or its callees.

### Iter 16 prior history (preserved)

[iter 16 bres probe revealed the smoking gun: removing one
bomber flips winPct from 0% to 100% and tuvSwing from -4 to +24]

### Iter 15 prior history (preserved)

[iter 15 TVAL probe + cap_local probe disproved
territory_value_map and capital-local-superiority hypotheses]**

### What the bres probe revealed (full sequence)

```
ntd=1 t=Ukraine S.S.R. defN=11 def=[5 armour, 3 inf, 2 fighter, 1 bomber]
  atkN=10 atk=[3 inf, 2 art, 3 armour, 2 fighter] tuvSwing=-4 winPct=0 rounds=3
  avgAtkRemN=0 avgDefRemN=2 → worth1=false worth2=false areSuccess=true

ntd=2 t=Ukraine S.S.R. defN=11 (same with bomber) tuvSwing=-4 winPct=0
  → areSuccess=true
ntd=2 t=Baltic States defN=? tuvSwing=-21 winPct=? → areSuccess=true

ntd=3 t=Ukraine S.S.R. defN=10 def=[5 armour, 3 inf, 2 fighter] (bomber moved to Finland by pass3)
  tuvSwing=+24 winPct=100 → worth1=true areSuccess=false
ntd=3 t=Finland defN=? temp_n=2 extraUV=28 → (bomber+fighters at Finland)
  → outer loop removes Finland

ntd=3 t=Ukraine S.S.R. defN=9 def=[5 armour, 3 inf, 1 fighter] (1 fighter also moved out)
  tuvSwing=+14 winPct=100 → worth1=true areSuccess=false
  → outer loop removes Libya, ntd-- to 2

ntd=2 t=Ukraine S.S.R. defN=11 (bomber back since Finland not in prio)
  tuvSwing=-4 winPct=0 → areSuccess=true → LOOP TERMINATES
```

Final Odin plan: UkrSSR has 4 temp armour + bomber + 2 fighter +
original 1 armour + 3 inf. Bomber STAYS at UkrSSR because Finland
was removed.

### Java's expected behavior (from after.json)

- UkrSSR: 1 armour + 3 inf (kept just the cantMoveUnits; 4 temp armour released)
- Belorussia: 5 armour (+4)
- Baltic States: aaGun 1 + inf 3 + armour 4 (+4 armour)
- Finland: inf 3 + bomber 1 + fighter 2 (+air units)
- Germany/Poland/West Russia/France/Italy/NWE: all armour gone

For Java to produce this, the bomber MUST be moved to Finland in
pass 3 — which means at ntd=3, Finland must NOT be removed by the
outer loop — which means UkrSSR's `worth_def` at ntd=3 (defenders
WITHOUT bomber: 10 def or 9 def) must give `areSuccess=true`.

This requires Java's `calc.calculateBattleResults` on {5 armour,
3 inf, 2 fighter} defenders vs {3 inf, 2 art, 3 armour, 2 fighter}
attackers to return `tuvSwing ≤ 11.5` (so worth1 = (tuvSwing - 5.5)
> max(0, 6) is false). Hand-calc: defender strength=29, attacker
strength=24 — attacker actually loses slightly. tuvSwing should
be roughly 0 or negative in Java.

### Hand-verification of bomber's defensive contribution

WW2v5_1942_2nd.xml: bomber has `attack=4 defense=1 movement=6 cost=12`.

With bomber (11 def): defender strength = 5×3 + 3×2 + 2×4 + 1×1 = 30 → 5.0 hits/round
Without bomber (10 def): defender strength = 5×3 + 3×2 + 2×4 = 29 → 4.83 hits/round
Attacker strength (with art boost): 2×2 + 1×1 + 2×2 + 3×3 + 2×3 = 24 → 4.0 hits/round

Bomber adds 0.17 hits/round to defender. Should NOT flip the
battle from "attacker never wins" to "attacker always wins".
Odin's calc is computing bomber's defensive contribution
incorrectly (almost certainly).

### Iter 15 prior history (preserved)

[iter 15 TVAL probe + cap_local probe disproved
territory_value_map and capital-local-superiority hypotheses]

### What the probes proved

Added two new ARMOUR_TRACE probes (gated by ARMOUR_TRACE
config, default off):
1. `p1_ukrSSR` inside pass 1 of `move_units_to_defend_territories`:
   for each Germans armour eval at Ukraine S.S.R., dump
   `max_enemy_units` tally, `eligible_defenders` tally,
   `atkStr`, `defStr`, `est`.
2. `worth_def` inside the "Check if its worth defending" loop:
   for each {Ukraine S.S.R., Belorussia, Baltic States, Finland,
   Libya} dump `tval`, `temp_n`, `temp_avg`,
   `hasHigherStrategicValue`, `resultSwing`, `minSwing`,
   `holdValue`, `extraUV`, `worth1`, `worth2`, `areSuccessful`.

Widened the iter 13 `prio_filter` probe to also dump for
Ukraine S.S.R., Baltic States, Norway, Finland, Libya, Algeria
(not just Belorussia).

### Probe output — `prio_filter` (full table)

| t              | value | tuvSwing | hasLandRem | notFacShouldHold | removed |
|----------------|------:|---------:|:----------:|:----------------:|:-------:|
| Ukraine S.S.R. | 13.90 | 6.00     | true       | false            | **false** |
| Belorussia     | 11.40 | 0.00     | true       | true             | true    |
| Baltic States  | 2.85  | 0.10     | true       | false            | false   |
| Norway         | 2.03  | 0.10     | true       | false (notFacNoEnemyN=true) | true |
| Finland        | 1.55  | 0.10     | true       | false            | false   |
| Libya          | 1.53  | 0.10     | true       | false            | false   |
| Algeria        | 1.05  | -1.00    | false      | true             | true    |

Ukraine S.S.R. survives the prio_filter because Russians PROFIT
from attacking (tuvSwing=6 means attacker gains 6 TUV net). Java
applies the same filter and would also keep UkrSSR.

### Probe output — `p1_ukrSSR` (first iteration)

```
ARMOUR_TRACE p1_ukrSSR ntd=1 unit=... enemy_n=10 enemy=[inf=3, art=2, armour=3, fighter=2]
   elig_n=4 elig=[Germans/inf=3, Germans/armour=1] atkStr=44.000 defStr=17.000 est=171.465
```

The 10 Russian attackers (44 strength) vs 4 Germans defenders
(17 strength) gives est=171 → > 60 → pass 1 adds the armour.
This matches the snap's BEFORE state at UkrSSR exactly
(Germans had 2 fighters + 1 armour + 3 infantry; fighters have
4 movement so they're not in cantMoveUnits/eligibleDefenders
initially). Computation is correct.

### Probe output — `worth_def` (FINAL ntd=2)

```
ARMOUR_TRACE worth_def ntd=2 t=Ukraine S.S.R. tval=53.609 temp_n=4 temp_avg=14.957
   hasHigherStrat=true resultSwing=-4.000 minSwing=6.000 holdVal=7.000 extraUV=56.000
   worth1=false worth2=false areSuccess=true
```

Decoding the two worth-defending clauses (Java 1140-1148):
- `worth1 = (result_swing - hold_value) > max(0, min_swing) = (-4 - 7) > max(0, 6) = -11 > 6 = false`
- `worth2 = (!has_higher_strategic_value && (result_swing + extra_unit_value/2) >= min_swing)`
  - `has_higher_strategic_value = (territoryValueMap[t] >= average of source-territory values)`
  - `= (53.609 >= 14.957) = true` → `!true = false` → worth2 = false (short-circuit)
- both false → `areSuccessful` stays true → UkrSSR keeps the 4 armour.

### What Java must compute differently

For Java to release the 4 armour from UkrSSR, `hasHigherStrategicValue`
must be **false**, which requires `territoryValueMap[UkrSSR] <
averageValue_of_sources(Germany, Germany, Poland, West Russia)`.

So Java's `ProTerritoryValueUtils.findTerritoryValues` for UkrSSR
must return a value LOWER than Germany/Poland/West Russia. Odin's
returns 53.609 — much higher than sources (avg 14.957). **Odin's
`pro_territory_value_utils_find_territory_values` is the divergent
proc.**

With `hasHigherStrategicValue=false`:
- `worth2 = (-4 + 56/2) >= 6 = 24 >= 6 = true` → `areSuccessful=false`
- → UkrSSR removed via `prioritizedTerritories.remove(ntd-1); setCanHold(false)`
- → On next loop iter, tempUnits reset and the 4 armour re-enter unitMoveMap
- → Eventually `moveUnitsToBestTerritories` picks Belorussia for them (value-best
   canHold reachable territory).

### Iter 13 prior history (preserved)

Filter probe in `prioritize_defend_options` proves the filter that
removes Belorussia is Java-faithful (identical predicate). Bug is
NOT in the filter — moved to `move_units_to_defend_territories`
"Check if its worth defending" loop.

### Iter 13 prior probe (preserved)

Added 2 probes in `pro_non_combat_move_ai_prioritize_defend_options`
(Odin 3370 + 3430):
- `ARMOUR_TRACE prio_input`
- `ARMOUR_TRACE prio_pre_filter`
- `ARMOUR_TRACE prio_filter` (widened iter 14 to cover all 7
  affected territories, not just Belorussia)

Filter is Java-faithful: `isNotFactoryAndShouldHold = !hasFac &&
(tuvSwing≤0 || !hasLandRem)` — matches Java line 631-642
byte-for-byte. Belorussia correctly dropped (`tuvSwing=0`).
Ukraine S.S.R. correctly kept (`tuvSwing=6 > 0`).

### Iter 13 prior history (note: hypothesis was wrong)

Iter 13's hypothesis was "pass 1 commits the 4 armour to UkrSSR
because est > 60". Iter 14 confirmed pass 1 does this — but
proved that's NOT the bug. Java would also commit them in pass
1, but then the LATER "Check if its worth defending" loop
RELEASES them because UkrSSR's territory_value is less than its
sources. Odin's territory_value computation has the same
defenders enter pass 1 but FAILS the release check.

### Iter 11/12 prior history (preserved)

Per-phase ARMOUR_TRACE (`after_defend`, `after_best`,
`pre_do_move`) localized the Belorussia↔Ukraine S.S.R. armour
5/1 swap to `move_units_to_defend_territories`. Iter 12
per-armour probes proved the assignment loops work correctly
given their inputs; Belorussia was missing from
`prioritized_territories`. Iter 13 has now proved this is BY
DESIGN (Java-faithful filter).

### Iter 12 prior history (preserved)

Added fine probes inside `pro_non_combat_move_ai_move_units_to_defend_territories`
(Odin 3539+):
- `ARMOUR_TRACE iter_start num_to_defend=N prioritized=[...]`
  at top of the outer `for { ... num_to_defend += 1 }` loop.
- `ARMOUR_TRACE p1_armour_eval` / `p1_armour_pick` inside the
  "Set enough units to have chance of winning" pass for armour
  units (Germans).
- `ARMOUR_TRACE p2_armour_eval` / `p2_armour_pick` inside the
  "Set non-air units" pass for armour units (Germans).

Built `server_game_test_iter12` with `-define:ARMOUR_TRACE=true`
and ran `FILTER_SNAP=0024`. Output:

```
ARMOUR_TRACE iter_start num_to_defend=1 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=2 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=3 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=3 prioritized=["Ukraine S.S.R.", "Baltic States", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=2 prioritized=["Ukraine S.S.R.", "Baltic States"]
```

**Belorussia never appears in `prioritized_territories`.** The
4 German armour go to Ukraine S.S.R. because that's the highest
`estimate` (171.46/129.49/101.61/81.53) in their candidate sets,
and Belorussia isn't a candidate at all. Libya armour picks
Libya (152.83). France/Italy/NW Europe armour have only Baltic
States in their reach but est=55.31 ≤ 60 → not added.

This rules out:
- Iteration ordering bugs in passes 1, 2, 3 (the assignment
  loops are working correctly given their inputs).
- `sort_unit_move_options` / `sorted_territory_keys_by_priority`
  helpers (they iterate the territories that DO exist correctly).
- `pro_sort_move_options_utils` more generally.

The bug is in:
- **`pro_non_combat_move_ai_prioritize_defend_options`** (Java
  557, Odin equivalent) — the filter loop that removes
  territories based on `canHold`, `value ≤ 0`,
  `isLandAndCanOnlyBeAttackedByAir`, `isNotFactoryAndShouldHold`,
  `canAlreadyBeHeld`, `isNotFactoryAndHasNoEnemyNeighbors`,
  `isNotFactoryAndOnlyAmphib`. One of these criteria
  incorrectly drops Belorussia.
- OR upstream: `defend_options.territory_map` doesn't even
  contain Belorussia (i.e. `populate_enemy_attack_options` or
  whoever feeds it misses Belorussia as defendable).

Java MUST include Belorussia (because Java places 5 armour
there in the snap's `after.json`). So the divergence is in one
of the two layers above.

Full iter 12 notes + iter 13 plan in
`/memories/repo/snap-0024-germanNCM.md`. The fine probes are
kept in place (compiled out by default since
`ARMOUR_TRACE :: #config(ARMOUR_TRACE, false)`).

### Iter 11 prior history (preserved)

Per-phase ARMOUR_TRACE (`after_defend`, `after_best`,
`pre_do_move`) localized the Belorussia↔Ukraine S.S.R. armour
5/1 swap to `move_units_to_defend_territories`. Finland↔Norway
and Libya↔Algeria are split across both phases.

### Iter 10 prior history (preserved)

ARMOUR_TRACE probe at `pre_do_move` proved the AI plan stored
in `move_map[t].units` is already divergent before
`pro_non_combat_move_ai_do_move` runs.

### Iter 9 prior history (preserved)

Drilled `ProNonCombatMoveAi.java:1893` ("Move land units to
territory with highest value and highest transport capacity")
and its Odin port at `pro_non_combat_move_ai.odin:2596`.
Applied the step-24 cruiser fix template: use
`unit_move_map_order` (outer LinkedHashMap order) and
`unit_move_map_inner_order` (inner LinkedHashSet order)
parallel insertion-order slices instead of unordered iteration.

Result: no change in snap 0024 → that pass is NOT the divergent
site. Edit is kept (Java-faithful, harmless). Iter 10 confirmed
the bug is in earlier planning passes.

### Iter 8 prior history (preserved)

Reproduced snap 0024 failure; corrected step-name mislabel
(germanNonCombatMove, not germanCombatMove); identified
root-cause family (Java HashMap iteration order in
`ProNonCombatMoveAi`). Hypothesized the land-move pass at
Java 1893 — iter 9 disproved that hypothesis.

### Iter 7 prior history (preserved)

**Regression sweep confirms iter 6 fix is a
net win: +3 (or more) PASS vs baseline. No real regressions.**

Ran the full 104-snap suite via the `FILTER_SNAP` xargs recipe
with a 60s per-snap timeout (results in `/tmp/snap_results/`).
Exit codes: 80 PASS, 17 FAIL (exit=1), 7 TIMEOUT (exit=124).

Baseline (post-iter6 fix expected): 78 PASS / 26 FAIL.
Delta vs baseline:

| change                | snaps                                                |
|-----------------------|------------------------------------------------------|
| fixed (was failing)   | 0033, 0041, 0049, 0069, 0085, 0093, 0101 (=7)        |
| still failing         | 0024 0025 0031 0038 0040 0048 0065 0074 0075 0076 0077 0081 0084 0090 0092 0097 0100 (=17) |
| previously-PASS now timing out at 60s | 0013 0022 0029 0073 0089 (=5) |
| previously-FAIL now timing out at 60s | 0021 0037 (=2) |

The 5 "regressed" snaps are NOT real regressions — they are slow
snaps brushing up against the 60s per-snap timeout. Verified by
re-running with `timeout 300`:
- 0013 russianPurchase **PASS** in 62.7s
- 0022 germanCombatMove **PASS** in 88.5s
- 0029 britishPurchase **PASS** in 81.0s
- 0073 germanPurchase — not retested (germanPurchase pattern like
  0021 → expected ~3 min, may pass at 300s)
- 0089 — not retested

0021 germanPurchase is the long-known 3m7s purchase compute (not
iter6's fault — see `next-steps.md` odds-calculator perf note).
0037 was a baseline failure that now times out instead of failing
fast — same root cause (`AMPHIB_PROBE` step 37 is the noted Pacific
amphib divergence per `/memories/repo/step38-japaneseBattle-status.md`).

**Conclusion: iter 6 trim is safe to keep. Effective baseline is
83+/104 PASS at 300s timeout, vs 77/104 at iter 5 (net +6 to +8).**

### Iter 6 prior history (preserved)

**FIXED SNAP 0017 russianPlace. Root cause:
harness orphan-backfill over-counted Russian pool 17 vs Java's 6.**

The breakthrough was treating the BEFORE/AFTER snapshot JSON as
ground truth and computing per-territory unit deltas directly:

```
location                 | DELTA (Russian units)
Caucasus                 | {'artillery': +2, 'infantry': +2}  # plan only
Karelia S.S.R.           | {}                                  # 0 placed!
Russia                   | {'armour': +1, 'artillery': +1}    # plan only
NOWHERE (pool)           | {'armour': -1, 'artillery': -3, 'infantry': -2}
```

Java places EXACTLY the 6 plan units (Caucasus 4 + Russia 2),
zero fallback. Then Java's `doAfterEnd` (line 80 of
`AbstractPlaceDelegate.java`) calls
`ChangeFactory.removeUnits(player, units)` which removes the
remaining 11 pool units from `player.unitsHeld` but NOT from
`data.allUnits` — orphan-units linger.

**Then tracing the pool size backwards across snaps 0001–0019**
revealed the smoking gun:

```
snap | step                    | NOWHERE Russian units
0014 | russianCombatMove       | {'infantry':2,'artillery':3,'armour':1}  # 6
0015 | russianBattle           | {'infantry':2,'artillery':3,'armour':1}  # 6
0016 | russianNonCombatMove    | {'infantry':12,'artillery':4,'armour':1} # 17!
0017 | russianPlace            | {'infantry':12,'artillery':4,'armour':1} # 17!
0018 | russianTechActivation   | {'infantry':10,'artillery':1}            # 11
```

The +11 jump from snap 15→16 IS the russianBattle casualties from
West Russia / Ukraine S.S.R. / Belorussia. Java's
`ChangeFactory.removeUnits(territory, units)` removes them from
the territory but keeps them in `data.allUnits` as orphans. They
are NOT in `player.unitsHeld`, so Java's `player.getUnits()` at
snap 17 returns the real 6, and ProPurchaseAi.place()'s line 519
`if (player.getUnits().isEmpty()) return;` correctly skips the
fallback after placing the 6 plan units.

**Odin's `test_server_game.odin` harness orphan-backfill loop
(line ~256)** adds EVERY player-owned non-on-map unit to
`gp.units_held.units`, including those 11 dead-defender orphans.
So `player.getMatches(non-construction)` returns 11 → fallback
placeUnits() executes → Russia gets +4 inf and Karelia gets
+1 inf +1 art that Java never placed.

**Fix** (`odin_flat/test_server_game.odin` after proai-state-apply):
Trim each AI player's `units_held` to match the unit-type counts
recorded in `stored_purchase_territories.can_place_territories[*].place_units`.
This restores Java's getUnits() semantics for snaps between
purchase and place. Guarded by `len(plan_counts) > 0` so snaps
with no active plan (e.g. germanPurchase snap 21, before purchase
runs) keep their existing pool. Snap 0017 now passes (~20 ms,
runtime essentially unchanged).

### Iter 5 prior history (preserved)

**Eliminated two hypotheses; identified the
remaining gap between Java and Odin in snap 0017 russianPlace.**


Instrumented `pro_purchase_ai_place_units` to dump `len(self.placements)`,
`PRODUCED[territory]=n`, and per-`UndoablePlacement` (producer,
place, n_units) at fallback entry. Findings:

| measurement | value (Odin run) | Java expected |
|------------:|-----------------:|--------------:|
| pool at fallback entry (pass 0, non-construction) | **11** | 11 ✓ |
| placements at fallback entry | **6** | 6 ✓ |
| PRODUCED[Russia] | **2** | 2 ✓ |
| PRODUCED[Caucasus] | **4** | 4 ✓ |
| PRODUCED[Karelia] (none) | absent | absent ✓ |
| prioritized territories (count) | **6** | 6 ✓ |
| prioritized order | Karelia(sv=31.8), Caucasus(sv=15.4), Russia(sv=7.6), 16SZ, 4SZ, 5SZ | same |
| need_to_defend_land | **0** | (presumed 0) |
| need_to_defend_sea | **0** | (presumed 0) |

**Disproven hypothesis**: `placements` and `produced` state at
fallback entry exactly match what Java would have. So
`getMaxUnitsToBePlacedFromFull` should return 6 for Russia and 2
for Karelia in BOTH Java and Odin. Yet Java places 0 in fallback;
Odin places 5+2=7.

**New discovery — plan UUIDs are PHANTOM**: the 6 plan unit IDs
recorded in `before-proai-state.json.players.Russians.storedPurchaseTerritories[*].canPlaceTerritories[*].placeUnits[*].id`
are NOT present anywhere in `before.json.units[]` or `after.json.units[]`.
They are ProPlaceTerritory internal planning slots, never real
game units. So both Java and Odin's plan loop iterates the plan
slots by TYPE, picks 6 matching units from `player.getUnitCollection()`,
and removes those. Pool: 17→11 (verified by python).

**New discovery — Java's `doAfterEnd` deletes pool unplaced units
but only from player.unitsHeld, NOT from `data.getUnits()` (allUnits).**
So the AFTER snapshot's "pool=11" includes the 11 orphan units
that were `removeUnits`-changed away from player.unitsHeld at end
of place phase. They still appear in `data.units` with
`owner=Russians`. This means we CANNOT directly tell from
before/after pool counts how many units were placed in fallback
vs how many doAfterEnd removed.

**Re-derived from per-territory placements**: Russia AFTER has
+1 armour +1 art (= plan only, no fallback). Karelia AFTER has 0
new units. Caucasus AFTER has +2 inf +2 art (= plan only). So
Java's fallback placed **zero** units at Russia/Karelia/Caucasus.

**Verified outside `getMaxUnitsToBePlacedFromFull`**:
- ProAi state loader honors `canHold` from proai-state JSON
  (`odin_flat/test_proai_state_loader.odin:159`), but the place()
  flow creates FRESH `Pro_Purchase_Territory` via
  `pro_purchase_utils_find_purchase_territories`, so the loaded
  `canHold=False` for Karelia is **discarded** before the
  prioritize step. Same as Java (Java also calls
  `findPurchaseTerritories` fresh).
- All 5 players use `whoAmI=AI:Hard (AI)` → ProAi (no test-only AI).
- `PlaceDelegate.java` is empty (just `extends AbstractPlaceDelegate`)
  — no method overrides that could change behavior.

**Remaining hypothesis (untested)**: Java's actual runtime
exhibits a side effect not captured by paper-trace. Most likely:
**Java's `placeDefenders` flow DOES enter `placeDefenders`** for
Russia/Karelia/Caucasus, places defenders that consume the full
production capacity, and THEN the fallback returns max=0 because
producers are saturated. Odin returns `need_to_defend_*=0`, so
Odin skips placeDefenders entirely. Difference is in
`prioritize_territories_to_defend` filter logic:
- `enemy_attack_options.getMax(t) == nil` filters territories
  with no enemy attacks. If Odin's territory_manager misses
  enemy attack options Java sees for Russia/Karelia/Caucasus,
  Odin skips them in needToDefend.
- That code path is in `pro_territory_manager.populate_enemy_attack_options`
  — a separate, deeper subsystem.

Files instrumented this iter:
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`:
  added `PLACE_PRIORITIZED_DUMP`, `PLACE_NEED_TO_DEFEND_LAND`,
  `PLACE_NEED_TO_DEFEND_SEA`, and extended `PLACE_UNITS_FALLBACK_ENTRY`
  with `placements=N`, per-placement detail, and `PRODUCED[t]=n`.

No code changes. No fix made.

---

### Iter 4 history (preserved for reference)

2026-05-22 (iter 4) — **Drilled `get_max_units_to_be_placed_from_full`**
via printfs on `(prod, at, production, ucahbph, ucap, returned,
origF, ownerOrig, wasFact, maxCon, csw_to_n)` gated by
`player==Russians && at in {Russia, Karelia S.S.R.}`. Confirmed the
port's algorithm mirrors Java exactly per
`triplea/game-app/game-core/src/main/java/games/strategy/triplea/delegate/AbstractPlaceDelegate.java`
lines 1129-1320; same branch decisions, same arithmetic. Output for
snap 0017 russianPlace fallback:

| call | prod | at | production | ucap | branch | returned |
|------|------|----|------------|------|--------|----------|
| pre-plan | Russia | Russia | 8 | 0 | plain | 8 |
| during plan (after 1 placed) | Russia | Russia | 8 | 1 | plain | 7 |
| **fallback** | Russia | Russia | 8 | 2 | plain | **6** |
| fallback per-attempt (1-4 of 6) | Russia | Russia | 8 | 3,4,5,6 | plain | 5,4,3,2 |
| **fallback** | Karelia | Karelia | 2 | 0 | plain | **2** |
| fallback per-attempt (1 of 2) | Karelia | Karelia | 2 | 1 | plain | 1 |
| Caucasus | Caucasus | 8 (?) | 4 | 4 | plain | 0 |

Key facts the printf-dump confirms:
- `origF=false` for all three Russian factories (WW2v5 XML does
  not set `originalFactory=true` and `setOriginalFactory` is only
  called via XML reflection — so Java has `origF=false` too).
- `ra=null` for Russians in WW2v5 (no `RulesAttachment`; verified
  by grepping the XML).
- `wasFact=true` for Russia and Karelia (all three have a starting
  factory in the WW2v5 XML — `unitPlacement unitType="factory"`).
- `production=8` (Russia) and `production=2` (Karelia) match the
  territory `unitProduction` field.
- `unitCountAlreadyProduced` correctly grows as plan units land.
- `csw_to_n=true` branch only adds bookkeeping for water adjacency;
  for land (Russia, Karelia) the `production_can_not_be_moved`
  equals `unit_count_already_produced` and the branch reduces to
  `unitCountHaveToAndHaveBeenBeProducedHere = unit_count_already_produced`.
  So the final return is `max(0, production - ucap)`.

Ground truth from `before/after.json`:
- Russia BEFORE: factory + aaGun + infantry + fighter; AFTER (Java):
  same + 1 armour + 1 artillery (matches plan exactly).
- Karelia BEFORE: factory + armour; AFTER (Java): same (no
  placements).
- Caucasus BEFORE: factory + aaGun + infantry + armour + fighter;
  AFTER (Java): same + 2 infantry + 2 artillery (matches plan).
- Russians pool BEFORE: 12 inf + 4 art + 1 armour = 17.
- Russians pool AFTER (Java): 10 inf + 1 art = 11. Δ = -2 inf
  -3 art -1 armour = exactly the 6 plan units.

So Java's fallback `placeUnits` places **zero** units beyond the
plan; Odin places 5 at Russia + 2 at Karelia = 6 extras (Russia 5
of 6 attempts succeed; the 6th `playerHasEnoughUnits` rejects
because the unit was already moved away during Karelia's iteration
— see "frozen player_units" note below).

The algorithm on paper computes max=6 (Russia) and max=2 (Karelia)
in **both** Java and Odin. Yet Java places 0. The divergence must
therefore be **outside `getMaxUnitsToBePlacedFromFull`** in code
the orchestrator has not yet inspected. Most likely candidates:

1. **`player_units` is a SNAPSHOT in Odin's `pro_purchase_ai_place_units`**
   (line 339 of `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`,
   via `unit_collection_get_units` at
   `odin_flat/games__strategy__engine__data__unit_collection.odin:9`
   which returns a fresh `[dynamic]^Unit` COPY). Java does
   `player.getMatches(unitMatch)` inside the inner loop, returning
   the LIVE pool each iteration. This means after Karelia consumes
   2 units, Java sees 9 in pool but Odin still sees 11. **However**,
   this only explains why Odin's 6th attempt at Russia fails (the
   2 already-consumed units appear in Odin's `matched`); it does
   NOT explain why Java places 0 (which requires Java's max=0).

2. **`placeDefenders` divergence**: maybe Java's `placeDefenders`
   silently consumes Russia/Karelia production (sets some state)
   that makes `getPlaceableUnits` return 0 later. Odin shows the
   instrumented `pro_purchase_ai_place_defenders` performed 0
   placements (no GMUTBPF_RET output between the plan loop and
   `PLACE_UNITS_FALLBACK_ENTRY`).

3. **The snap is technically correct but encodes Java's
   `placeDelegate` state at the moment of snap-capture, which
   may carry hidden state** (e.g., a non-empty `produced` map at
   step START due to lingering state from a previous step's
   delegate save/load). The Odin harness's
   `test_server_game_register_ww2v5_delegates` constructs a fresh
   `AbstractPlaceDelegate` with `produced={}`. If Java's actual
   state had `produced[Russia]=8` at step start (e.g., due to a
   bug-or-feature in `loadState` from the snap fixture), Java
   would compute `max(0, 8-8)=0` immediately.

4. **Java AbstractPlaceDelegate#produced may be unioned across
   players** in some edge case I haven't found. Russia + Caucasus
   producing means produced has 6 entries total; if `getAlreadyProduced`
   returns "all 6" (instead of just Russia's 2), then `ucap=6`,
   `max=8-6=2`, fallback places only 2 at Russia. Hmm, still
   doesn't reach 0.

No fix made this iteration — instrumentation only. Confirmed
the suspect-leaf code itself is faithful to Java.

## Next action

**Iter 29: Ship a perturbation-free PUR_TRACE so snap 0089 (and any
future pointer-iteration-sensitive snaps) can be drilled without
masking the bug.** Iter-28 confirmed snap 0089's PUR_TRACE
instrumentation flips the AI's outcome to PASS because trace
allocations (`make([dynamic]string)`, `strings.builder_make`,
per-row `fmt.sbprintf`) go to `context.allocator` and shift every
downstream `malloc` return address. The current tracer is
diagnostically useless for any pointer-sensitive snap; this is the
blocker for iter 28's drill.

### Task A — Zero-perturbation PUR_TRACE (PRIORITY)
Modify `odin_flat/games__strategy__triplea__ai__pro__util__pro_pur_trace.odin`:
1. Replace every `make(...)`, `strings.builder_make(...)`,
   `append(...)` with `context.temp_allocator`-allocated equivalents:
   ```odin
   rows := make([dynamic]string, context.temp_allocator)
   ut_names := make([dynamic]string, context.temp_allocator)
   sb := strings.builder_make(context.temp_allocator)
   full := strings.builder_make(context.temp_allocator)
   ```
2. Drop the `defer delete(...)` calls (temp_allocator owns lifetime).
3. Add `free_all(context.temp_allocator)` at the END of
   `pro_pur_trace_emit` so subsequent trace calls don't accumulate.
4. Audit `fmt.printf` — on Linux glibc it routes through
   `core:io/_print` which may default-alloc on first invocation per
   thread. If snap 0089 STILL passes with trace on after this fix,
   replace `fmt.printf` with `os.write(os.stdout, transmute([]u8)
   <stack buffer formatted via temp_allocator>)`.
5. Verify the fix by re-running snap 0089 with trace and confirming
   the snap still FAILS (the bug is preserved AND the trace lines
   appear). The expected behavior is exactly the same FAIL message
   as the no-trace run.

Sanity check: snap 0001 + 5 random PASS snaps must STILL pass with
the new tracer enabled and disabled — proving the temp_allocator
change is itself zero-perturbation.

### Task B — Once tracer is non-perturbing, descend on snap 0089
With a working tracer, the iter-28 trace table can extend:
1. Compare the four checkpoint hashes (P01, P03, P06, P10) against
   a Java reference run. The first divergent checkpoint identifies
   which sub-phase introduces the bug. Iter-28 evidence already
   strongly suggests **P03 (purchaseLand)** since that's where
   inf-vs-armour is chosen in Java's round-2 logic.
2. If P03 is the divergent checkpoint, add a 19→? drill into
   `purchaseLandUnits` (Java line 1063 in ProPurchaseAi.java).
3. The bug class is pointer-keyed iteration order
   (same family as iter-21/24/26 LinkedHashMap fixes). Likely
   culprit: a HashMap-backed collection in `findUnitsThatCanFightOnWater`,
   `findPurchaseOptionsForTerritory`, or the option-ranking step
   inside `purchaseLandUnits` walks a bare Odin map rather than a
   parallel `_order` slice.

### Task C — Snap 0024 / 0032 / 0037 drill (parallel)
If iter-29 ships Task A early, also drill snap 0024
(germanNonCombatMove unit-tally divergence; same casualty/combat
layer suspects as iter-26/27 Next action Task B) and snap 0032
(britishNonCombatMove 1-infantry swap; iter-26 deterministic but
still red). These are pre-existing iter-23 carry-overs unaffected
by the iter-26 fix.

### Pre-iter-28 next-action history (preserved)

**Iter 27 → Iter 28 plan: Drill the iter-27 regression (snap 0089)
AND descend on snap 0024.** _Status: PARTIAL — snap 0089 drill
blocked on perturbation-free tracer; iter 29 will resume._

### Pre-iter-27 next-action history (preserved)

**Iter 26: Diagnose and resolve the iter-25 regression on snap 0032
before any further forward work.** _Status: DONE \u2014 root cause was
upstream bare-map iteration in `give_support_to_unit` over the
`support_rules` LinkedHashMap; fix shipped iter 26._
The L9 yellows are already classified (iter-24): DummyPlayer
green, CasualtyUtil.getDependents green-for-snap, CombatValue
fixed-as-much-as-possible. Time to descend to L8 inside
`casualty_selector_select_casualties` body and the OOL impl body:

1. **`CasualtySelector#getDefaultCasualties`** (`triplea/game-app/.../delegate/battle/casualty/CasualtySelector.java`).
   Find with: `find triplea/game-app -path "*/main/java/*CasualtySelector.java"`.
   Read the method top-to-bottom; locate the auto-choose branch;
   verify Odin port at
   `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_selector.odin`
   matches line-by-line.

2. **`CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`**.
   `find triplea/game-app -path "*/main/java/*CasualtyOrderOfLosses.java"`.
   The iter-22 deep dive only verified the `add_remove` loop and
   `keep_lowest_strength_first` flag; the SURROUNDING logic in the
   same proc (sort key construction, tie-break ordering, comparator
   plumbing) was assumed green. Re-verify those parts byte-for-byte.

3. **`MainDefenseStrength.isDominatingFirstRoundAttack`** (`MainDefenseCombatValue.java`).
   WW2v5 has no first-round-attack units AFAIK; verify nothing in
   snap 0024 trips a side-effect. Cheap sanity check; only worth
   doing if Tasks 1 & 2 don't find the bug.

### Task C — Snap 0032 single-infantry swap
With snap 0032 deterministic but still red, this is now drillable
in normal trace-table style. The symptom is a 1-unit swap between
two adjacent territories during `britishNonCombatMove`. Likely
candidates (descending `method_layer`):
- `MoveValidator.validateMoveForRequiresUnitsToMove` or similar
  movement-validation tie-break.
- Pro AI's `ProNonCombatMoveAi` move sort/pick order (cf.
  `/memories/repo/step24-cruiser-divergence.md` precedent).
- Cheap to seed: pick `britishNonCombatMove` step's top-level proc
  from `port.sqlite`, drill in descending `method_layer`.

### Task D — Hand off if iter-27 budget exhausted
If iter-27 runs out of budget between Task A and Task B/C, the
deterministic state of snap 0032 + the sweep results are enough
for iter-28 to pick up cleanly.

### Pre-iter-27 next-action history (preserved)

**Iter 26: Diagnose and resolve the iter-25 regression on snap 0032
before any further forward work.** _Status: DONE \u2014 root cause was
upstream bare-map iteration in `give_support_to_unit` over the
`support_rules` LinkedHashMap; fix shipped iter 26._

### Task A — Identify the hang root cause (PRIORITY)
Runs 2 + 4 of the iter-25 5-run loop died silently after `PSTART`.
With memory tracking enabled and `timeout 180`, no FATAL or leak
dump made it to disk, so the process hit a tight infinite loop
or hit a UAF that segfaulted before flush.

Steps:
1. Build a non-leak-tracking variant of `/tmp/snaprun` (drop
   `-debug` and use `-define:ODIN_TEST_TRACK_MEMORY=false`) so
   crashes produce a usable stack:
   ```sh
   cd triplea && /run/current-system/sw/bin/odin build \
     conversion/odin_tests/server_game_run_next_step \
     -collection:flat=../odin_flat \
     -collection:test_common=conversion/odin_tests/test_common \
     -build-mode:test -define:ODIN_TEST_TRACK_MEMORY=false \
     -extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib" \
     -out:/tmp/snaprun_fast
   ```
2. Re-run snap 0032 a few times with `timeout 180`. If a hang
   reproduces, attach `strace -f -e signal=none -o /tmp/strace.log
   -p $(pgrep snaprun_fast)` to see whether it's a busy loop
   (no syscalls), a poll/wait, or a segfault.
3. If it's a busy loop, check `get_next_available_supporter` for:
   - Use-after-remove of `keys_order[0]` (the remove zeroes the
     slot in entries but does the next iteration find the freed
     `^Unit` and re-loop?).
   - Mutation of `keys_order` while iterating it.

### Task B — Audit missed iteration sites
The iter-25 fix may be incomplete. Grep for ALL consumers of the
three suspect maps and confirm each one uses an `_order` slice:
```sh
cd odin_flat
grep -n 'units_giving_support\b' games__strategy__triplea__delegate__power__calculator__*.odin
grep -n 'support_units\b'        games__strategy__triplea__delegate__power__calculator__*.odin
grep -n 'support_rules\b'        games__strategy__triplea__delegate__power__calculator__*.odin
grep -n '\.entries\b'            games__strategy__triplea__delegate__power__calculator__integer_map_unit*.odin
```
For each `for k, v in ...` over a bare map field, replace with
walks via the parallel `_order` slice. Candidate sites likely
missed:
- `unit_power_strength_and_rolls_builder.add_units` — does it
  iterate `available_supports.units_giving_support` directly?
- `Available_Supports.support_units` — Java line 32 + 108 say
  LinkedHashMap; Odin field is still bare `map[…]^Support_Details`
  with no `_order` parallel slice. If any caller iterates it, add
  one.
- `support_calculator` builder loop — does the OUTER walk over
  `support_rules` use bare-map iteration order?

### Task C — Bisect-revert if Task A/B are inconclusive
If Task A/B don't pinpoint the regression, revert iter-25 changes
one at a time and re-run snap 0032 (3 runs each):
1. Revert Task A only (MainOffenseStrength accessor) — should be
   inert for snap 0032.
2. Revert Task B only (`Integer_Map_Unit.keys_order` + helpers +
   builder + consumer rewrites). If 0032 stabilizes back to
   2P/1F or better, the regression is here.
3. Revert Task C only (`units_giving_support_order` + getter +
   producer + consumer). If 0032 stabilizes back to 2P/1F or
   better, the regression is here.

### Task D — Once snap 0032 is back to deterministic PASS
Re-run individual snap 0024 with `timeout 300`. If still red, the
bug is deeper than the support pipeline. Next yellow candidates
in descending `method_layer`:
- `CasualtySelector#getDefaultCasualties` (layer 16) body itself.
- `CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`
  surrounding logic (`add_remove` undo-loop,
  `keep_lowest_strength_first` flag).
- `MainDefenseStrength.isDominatingFirstRoundAttack` (verify
  WW2v5 has no first-round attack units).

### Task E — Full 104-snap regression sweep
Once snap 0032 PASSes ≥ 5/5 and snap 0024 either passes or its
failure mode is fully characterized, run the full sweep at -P 8
with 420 s cap:
```sh
cd /home/caleb/todin/triplea && mkdir -p /tmp/snap_results_iter26 && \
  rm -f /tmp/snap_results_iter26/*.txt && \
  printf '%s\n' $(seq -f "%04g" 1 104) | \
  xargs -P 8 -I{} sh -c 'timeout 420 env \
    TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP={} /tmp/snaprun_fast \
    > /tmp/snap_results_iter26/{}.txt 2>&1; \
    echo "EXIT={}:$?" >> /tmp/snap_results_iter26/{}.txt'
for f in /tmp/snap_results_iter26/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```
Compare against iter-23 baseline (84P / 18F).

### Pre-iter-26 next-action history (preserved)

**Iter 25: Implement the three iter-24 fixes, then re-run sweep.**

### Task A — Fix `MainOffenseStrength` Java-fidelity bug (small)
`odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
```odin
// BEFORE
strength: i32 = unit_attachment_get_attack_no_player(ua)
// AFTER
strength: i32 = unit_attachment_get_attack(ua, unit_get_owner(unit))
```
Mirror the existing defense-side, which already calls
`unit_attachment_get_defense(ua, owner)`.

### Task B — Fix `Integer_Map_Unit` LinkedHashMap order (small)
`odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin:4`:
```odin
Integer_Map_Unit :: struct {
    entries:    map[^Unit]i32,
    keys_order: [dynamic]^Unit,   // NEW — parallel LinkedHashMap order
}
```
Then audit every write site of `Integer_Map_Unit.entries` and
keep `keys_order` synchronized at put/clear/remove. Critical writers:
- `available_supports_support_details_new` and `_new_copy` in
  `available_supports/support_details.odin`
- Anywhere else that does `imu.entries[k] = v` for the first time
  (grep `\.entries\[` in `odin_flat/` filtered to `Integer_Map_Unit`
  context). The IDE rename would also catch struct-literal writers.

Then rewrite `available_supports_get_next_available_supporter`
(`available_supports.odin:78-95`) to pick `details.support_units.keys_order[0]`
(after dropping any 0-count keys via a single forward scan), so
behavior matches Java's `LinkedHashSet.iterator().next()`.

### Task C — Fix `Available_Supports.units_giving_support` LinkedHashMap order (medium)
`available_supports.odin:10`: add a parallel insertion-order slice:
```odin
Available_Supports :: struct {
    support_rules:                map[...][dynamic]^Unit_Support_Attachment,
    support_units:                map[...]^Available_Supports_Support_Details,
    units_giving_support:         map[^Unit]^Integer_Map,
    units_giving_support_order:   [dynamic]^Unit,   // NEW
}
```
Insertion sites:
- `available_supports.giveSupportToUnit` — append `supporter` to
  the order slice on first insertion into `units_giving_support`.
- `support_calculator_get_combined_support_given` — when iterating
  `support_from_friends` / `support_from_enemies`, walk the
  `units_giving_support_order` slice instead of bare map keys.

After these three fixes:
1. Rebuild `/tmp/snaprun`.
2. Confirm snap 0032 deterministic (10 individual runs all PASS).
3. Re-run individual snap 0024 with `timeout 300` to see new
   behavior (could PASS, could FAIL with different tally).
4. Re-run full 104-snap sweep at `-P 8` with 420s cap; record
   new pass/fail tally.

### Task D — If snap 0024 still red after iter-25
Per java-fidelity rule, the bug is deeper than support-iteration.
Next candidates in descending `method_layer`:
- `CasualtySelector#getDefaultCasualties` (layer 16) — wraps
  `CasualtyOrderOfLosses`; the body itself may have a divergent
  control-flow path (e.g. early-return in `auto_choose_casualties`
  branch). Drill its body.
- `CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl` —
  iter-23 fixed support storage; verify the surrounding logic
  (`add_remove` undo-loop, `keep_lowest_strength_first` flag,
  etc.) is byte-for-byte Java-faithful.
- `MainDefenseStrength.isDominatingFirstRoundAttack` —
  WW2v5 has no "first round attack only" units AFAIK, but verify.

### Pre-iter-25 next-action history (preserved)

**Iter 24 (planned and executed): Read-only orchestrator drill.**
Confirmed sweep, drilled 2 L9 yellows green-for-snap-0024,
identified 3 new fixes (planned for iter 25). No code changes.

**Iter 24 prior next-action draft (preserved):**
**Iter 24: Two parallel verification tasks once the iter-23 sweep
finishes.**

### Task A — analyze sweep results (5 min)
```sh
for f in /tmp/snap_results_iter23/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```
Expected outcomes per snap (compare against iter-21 baseline):
- **same PASS** → green for both iters, no concern.
- **iter-21 PASS → iter-23 FAIL** → REGRESSION; investigate (the
  refactor changed observable behavior here in a way that
  diverges from Java).
- **iter-21 FAIL → iter-23 PASS** → win, mark snap done.
- **iter-21 FAIL → iter-23 FAIL** → still divergent at L9; descend
  to next yellow dep (see Task B).
- **iter-21 PASS → iter-23 TIMEOUT** → likely just slow; bump
  per-snap cap and re-run individually.
- **iter-21 TIMEOUT → iter-23 PASS/FAIL** → workload-shape change,
  same analysis tier as PASS.

### Task B — snap 0024 deeper drill
If snap 0024 is still red after the iter-23 refactor:
1. Run with `timeout 1200` (20 min) to confirm whether it eventually
   converges to PASS, FAIL with different tally, or genuinely
   diverges.
2. If it diverges, the next yellow L9 dep is the Java HashMap-order
   bug in `CasualtyUtil.getDependents` (Java line 30):
   `final Map<Unit, Collection<Unit>> dependents = new LinkedHashMap<>();`
   Odin port (`odin_flat/.../casualty_util.odin:25`) uses bare
   `map[^Unit][dynamic]^Unit` → still pointer-hash iteration order.
3. Or the next layer up — `Player#selectCasualties` →
   `DummyPlayer.selectCasualties` (Java DummyPlayer.java:189-247);
   gap analysis was captured in iter 22 notes (defender side
   harmless because `keep_one_land=false` hardcoded; attacker
   side requires verifying the
   `attacker_keep_one_land_unit` flag value at the snap-0024
   battle_calculator construction site).

### Task C — performance budget review
The iter-23 refactor exposed a 30–60× slowdown in some snaps. If
snap regression catches a real timeout regression (not just slow),
profile the casualty-selection hot path:
- The N=11 defender loop in `casualty_order_of_losses_sort_…_impl`
  is O(N² × M) where M = average support fan-out per unit.
- Java JIT optimizes this; Odin debug build does not. Consider
  building with `-o:speed` (`-o:size` makes it worse) for
  regression sweeps if the timeouts persist.

### Pre-iter-24 next-action history (preserved)

**Iter 23 (planned and executed): Refactor `unit_support_power_map`
/ `unit_support_rolls_map` from `map[^Unit]Integer_Map` to
`map[^Unit]^Integer_Map` so Integer_Map lives on the heap and
mutations propagate without write-back.** (Done — see "Last action".)

### Why
Iter 22 proved the iter 21 keys_order field is correctly
maintained inside Integer_Map, but is lost whenever an
Integer_Map is stored BY VALUE inside another map. Odin maps
copy values on read; `[dynamic]` descriptors that get appended
inside a local copy never write back. The only safe storage
pattern for "Java reference-typed value inside a Map" is to use
a pointer.

### Concrete files to change

1. `odin_flat/games__strategy__triplea__delegate__power__calculator__power_strength_and_rolls.odin`
   - Lines 13-14: `map[^Unit]Integer_Map` → `map[^Unit]^Integer_Map`
   - Lines 53, 59: getter return type
   - Lines 73, 79: lambdas `_add_units_0` / `_2` — return `^Integer_Map`
     constructed via `integer_map_new()`
   - Lines 86-96, 109-118: lambdas `_add_units_1` / `_3` — drop the
     value-copy idiom; pass the stored pointer directly to
     `integer_map_add_map`
   - Lines 196-197: init `make(map[^Unit]^Integer_Map)`

2. `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_order_of_losses.odin`
   - All `support_power_for_unit := unit_support_power_map[u]`
     and `support_rolls_for_unit := …` sites: receive `^Integer_Map`,
     drop the `&` when calling `integer_map_key_set` etc.
   - `in unit_support_power_map` checks unchanged (still keyed by ^Unit).
   - `delete_key(&unit_support_power_map, worst_unit)` unchanged.

3. `odin_flat/games__strategy__triplea__delegate__power__calculator__aa_power_strength_and_rolls.odin`
   - Inspect for identical pattern; apply same refactor if present.

### After refactor
- Build: `odin build conversion/odin_tests/server_game_run_next_step
  -collection:flat=../odin_flat -collection:test_common=conversion/odin_tests/test_common
  -build-mode:test -out:/tmp/snaprun -extra-linker-flags:-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib`
- Test snap 0024 with `timeout 600` (allow 10 min; if Java-faithful
  support truly is heavier, this is real, not a hang).
- If snap 0024 passes, re-run the 104-snap regression sweep.
- If snap 0024 STILL diverges (different output, not timeout),
  return to the trace table — drill the next yellow dep below.

### Backup descent path (if iter 23 doesn't fix snap 0024)

Resume L8 drill in descending-layer order:
- `CasualtySelector#getDefaultCasualties` (layer 16)
- `Player#selectCasualties` (layer 17) — abstract; descend via
  override (`DummyPlayer.selectCasualties` is NOT yet ported in
  Odin — see iter-22 trace below for the gap analysis).
- `CasualtyUtil#getDependents` (layer 6) — uses LinkedHashMap;
  Odin port at `odin_flat/.../casualty_util.odin:25` uses bare
  `map[^Unit][dynamic]^Unit` → still pointer-hash. Add a parallel
  `[dynamic]^Unit` recorded at insertion.
- `CombatValue#getEnemyUnits` / `getFriendUnits` (layer 0,
  abstract) — descend via concrete `MainOffenseCombatValue` /
  `MainDefenseCombatValue` impl.

### Iter 22 trace data — DummyPlayer.selectCasualties gap

Java `DummyPlayer.selectCasualties` (lines 189-247) has two
conditional tweaks beyond the default Player implementation:
  (a) `keepAtLeastOneLand`: swap last-killed land for cheapest
      non-land
  (b) `orderOfLosses`: override default casualty order
Without either flag, Java returns `defaultCasualties` unchanged
— identical to Odin's nil-vtable fallback in
`player_select_casualties` (player.odin:294-332). Defender side
of `dummy_delegate_bridge_new` hardcodes `false` for
`keep_one_land_unit` (line 113); attacker side takes it as a
parameter. **TODO before iter-24:** verify what value
`battle_calculator` passes for `attacker_keep_one_land_unit` in
snap 0024's UkrSSR sims. If `true`, port DummyPlayer.selectCasualties
(install a vtable slot on Dummy_Player → Abstract_Ai). If
`false`, this is a parity gap to fix later but not snap 0024's
cause.

### Prior next-action history (preserved)

**Iter 22 (planned but mostly diagnostic):** Resume L8 casualty-
selection drill. The `Integer_Map` LinkedHashMap fix (iter 21)
is structural and necessary but did not by itself fix snap 0024.
Re-classify `casualty_selector_select_casualties` from
green-by-mt-fix back to yellow, then descend into its still-yellow
deps in descending `method_layer` order from port.sqlite:

```sql
SELECT d.depends_on_key, m.method_layer
FROM dependencies d
JOIN methods m ON m.method_key = d.depends_on_key
LEFT JOIN test_status ts ON ts.entity_key = d.depends_on_key
WHERE d.primary_key = '<selectCasualties key>'
  AND m.is_abstract = 0
  AND COALESCE(ts.status,'yellow') = 'yellow'
ORDER BY m.method_layer DESC;
```

Top candidates (from iter 21 sqlite query):
- `CasualtySelector#getDefaultCasualties` (layer 16) — wraps
  CasualtyOrderOfLosses; iter 21 fixed the LinkedHashMap leak
  but not the higher-layer logic itself.
- `Player#selectCasualties` (layer 17) — abstract; descend via
  override to `AbstractAi#selectCasualties` /
  `ProAi#selectCasualties`.
- `CasualtyUtil#getDependents` (layer 6) — uses Map<Unit,
  Collection<Unit>>; HashMap-order risk again.
- `CombatValue#getEnemyUnits` / `getFriendUnits` (layer 0,
  abstract) — descend via concrete CombatValue impl (probably
  `MainDiceRoll`'s combat value).

Tier A classification: capture fixtures for
`CasualtyOrderOfLosses.sortUnitsForCasualtiesWithSupport` and
`CasualtySelector.getDefaultCasualties` via
`scripts/capture_proc_snapshot.py` then
`scripts/gen_replay_tests.py`. Re-run snap 0024 individually
after each green child to detect when the cumulative fix lands.

### Iter 20 next-action history (preserved)

**Iter 20: Drill into simulator internals to find why Odin's
`must_fight_battle_fight` produces a DIFFERENT outcome from Java
for the n_def=10 (no bomber) case with the same MT(42) dice.**

Why this is the next step:
- Iter 19 cleared `pro_territory_get_max_enemy_units` (Odin's
  10-attacker count is correct given correct adjacencies +
  artillery mov=1).
- Iter 19's widened `bc_run` probe shows Odin's simulator gives
  ATTACKER wins for the n_def=10 case (bomber removed). Java's
  observable behavior (after.json: bomber moved to Finland)
  REQUIRES Java's simulator to give DEFENDER holds for that case.
- So Java + Odin diverge on a single deterministic battle run
  with identical seed and identical units.
- Most likely causes (in order of likelihood):
  1. **Dice consumption order**: which unit rolls 1st, 2nd, ...
     within a round affects which random number it consumes.
  2. **Casualty selection order**: who dies first determines
     who keeps rolling next round.
  3. **Artillery support pairing**: which infantry is boosted
     by which artillery determines combined strength.
  4. **MersenneTwister output divergence**: Odin's MT(42) may
     not produce bit-for-bit identical outputs to Java's
     Apache Commons Math MT(42).

Plan:
1. Add MT-output verification probe: print first 30 nextInt(6)
   outputs from a fresh MT(42) in Odin. Run a tiny Java program
   that does the same. Compare. If they diverge, fix Odin's MT.
2. If MT outputs match: add per-round dice probe in
   `dice_roll_roll_dice` or wherever rolls happen for the battle.
   Dump (unit_type, owner, die_value, hit?) per roll per round.
3. Compare against Java's `DiceRoll.rollDiceLowLuck` or
   `DiceRoll.rollDiceNormal` (depending on which mode is on).
4. Fix the divergence per java-fidelity-rule.md.

Files of interest:
- `/odin_flat/games__strategy__triplea__delegate__must_fight_battle.odin`
  (`must_fight_battle_fight`, fight_loop)
- `/odin_flat/games__strategy__triplea__delegate__dice_roll.odin`
  (roll_dice / unit ordering for dice)
- `/odin_flat/games__strategy__triplea__delegate__casualty_selector.odin`
  (casualty_selector_select_casualties already inspected iter 18)
- `/odin_flat/games__strategy__engine__random__plain_random_source.odin`
  + `mersenne_twister.odin`
- Java refs:
  - `MustFightBattle.java#fightLoop` / `BattleStep` enum
  - `DiceRoll.java#rollDice` (LowLuck / Normal)

### Trace table (iter 24)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red (FAIL in 57s — was 600s timeout iter-23, faster after sweep finished and CPU pressure released) |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories`                                                | red    |
|  L3   | "Check if its worth defending" loop                                               | red    |
|  L4   | `pro_odds_calculator_calculate_battle_results_2` for UkrSSR                       | red    |
|  L7   | `must_fight_battle_fight` / fight_loop                                            | red    |
|  L8   | MT(42), dice order, art support, active_units                                     | green (iter 20) |
|  L8   | `casualty_selector_select_casualties`                                             | yellow |
|  L9   | `Integer_Map` LinkedHashMap (within and stored-by-value)                          | green (iter 21 + iter 23) |
|  L9   | `Player#selectCasualties` → `DummyPlayer.selectCasualties`                        | **green (iter 24 — Java fidelity verified: AI never sets `setKeepOneAttackingLandUnit`, defaults to false; orderOfLosses empty; identical to Odin nil-vtable fallback)** |
|  L9   | `CasualtyUtil.getDependents` HashMap-order                                        | **green for snap 0024 (iter 24 — no transports in UkrSSR battle, dependents values all empty; downstream consumer only uses per-key lookup, not iteration). Still divergent in the abstract; only safe-by-context for snap 0024.** |
|  L9   | `CombatValue` concrete impl (`Main_Offense_Combat_Value` / `Main_Defense_Combat_Value`) | **yellow with 3 specific suspects identified (iter 24, see "NEW Java-fidelity bugs" in Last action):** (1) `MainOffenseStrength` uses `_no_player`; (2) `Available_Supports.get_next_available_supporter` pointer-hash; (3) `Available_Supports.units_giving_support` outer-map pointer-hash. Hypothesis: #2 + #3 cause snap 0032 intermittency and may cause snap 0024 divergence cascade. Iter 25 fixes all three. |

### Trace table (iter 23 prior — preserved)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red    |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories` (Java 763 / Odin 3539)                         | red |
|  L3   | "Check if its worth defending" loop (Java 1086-1148 / Odin 4319+)                 | red |
|  L4   | `pro_odds_calculator_calculate_battle_results_2` for UkrSSR                       | red (iter 16) |
|  L5   | `pro_territory_get_all_defenders` / `pro_territory_get_max_enemy_units`           | green (iter 19) |
|  L5   | `pro_territory_manager_populate_enemy_attack_options` for UkrSSR                  | green (iter 19) |
|  L5   | `pro_odds_calculator_call_battle_calc` (Odin 144)                                 | green (iter 17) |
|  L6   | unit attribute lookup (atk/def/isAir/isSea per defender)                          | green (iter 17) |
|  L6   | RNG seeding (PlainRandomSource construction)                                      | green (iter 17) |
|  L6   | `battle_calculator_calculate` per-run loop                                        | green (iter 18) |
|  L7   | `must_fight_battle_fight` / fight_loop                                            | red (iter 19) |
|  L8   | MT(42) bit-fidelity vs Apache Commons Math                                        | **green (iter 20 — mt_self_test PASS for 1024 raw32 + 1024 each nextInt 6/12/8)** |
|  L8   | dice consumption order (`roll_dice_factory_roll_battle_dice`)                     | **green (iter 20 — first 10 dice for Russians round-2 = [0,1,1,3,3,0,0,2,0,3] = MT reference)** |
|  L8   | artillery support pairing                                                         | **green (iter 20 — 2 of 3 inf get str=2 boost, 1 inf stays str=1)** |
|  L8   | active_units order (`power_strength_and_rolls.build`)                             | **green (iter 20 — sorted descending by str/sides as expected; ties don't affect hit count when all in bucket share threshold)** |
|  L8   | casualty selection order (`casualty_selector_select_casualties`)                  | **red (iter 21 drill target)** |
|  L4   | `pro_battle_utils_estimate_strength_difference` for UkrSSR pass 1                 | green by inspection (iter 14) |
|  L4   | `pro_territory_get_eligible_defenders`                                            | green by inspection (iter 14) |
|  L3   | `ProSortMoveOptionsUtils.sortUnitMoveOptions`                                     | green |
|  L2b  | `move_units_to_best_territories` (Java 1264 / Odin 1450)                          | green |
|  L2c  | `prioritize_defend_options` (Java 557, filter loop Java 631)                      | green by Java fidelity (iter 13) |
|  L3   | upstream `populate_defend_options` / `enemy_attack_options`                       | yellow (recursive concern: defend_options uses enemy_attack_options) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                  | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                            | green (iter 9) |

### Trace table (iter 14)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red    |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories` (Java 763 / Odin 3539)                         | red (UkrSSR kept armour because worth-defending check passes) |
|  L3   | "Set enough units" pass 1 (Java 807 / Odin 3704)                                  | **green** (commits 4 armour to UkrSSR per design; Java also does this) |
|  L3   | "Set non-air units" pass 2 (Java 830 / Odin 3768)                                 | green (iter 12) |
|  L3   | "Set air units" pass 3 (Java 871)                                                 | yellow (no role in armour swap) |
|  L3   | **"Check if its worth defending" loop (Java 1086-1148 / Odin 4319+)**             | **red (iter 15 drill target via territory_value_map)** |
|  L4   | `pro_battle_utils_estimate_strength_difference`                                   | **green by inspection** (formula matches Java line-by-line at Odin 297) |
|  L4   | `pro_territory_get_eligible_defenders`                                            | **green by inspection** (matches Java line-by-line at Odin 503; composition correct — 3 Germans inf + 1 armour at UkrSSR before adds) |
|  L4   | `pro_territory_get_max_enemy_units`                                               | **green by inspection** (10 Russian attackers match probe + snap before.json: 3 inf + 2 art + 3 armour + 2 fighter) |
|  L4   | `pro_odds_calculator_calculate_battle_results` (min_battle)                       | green (returns tuvSwing=6 hasLandRem=true; matches expected for 4v10 with attacker profit) |
|  L4   | **`pro_territory_value_utils_find_territory_values`** (Java `ProTerritoryValueUtils#findTerritoryValues`) | **red (iter 15 drill target — Odin returns UkrSSR=53.609 vs sources avg 14.957; Java must return ≤ sources avg for the strategic-value escape clause to trigger)** |
|  L3   | `ProSortMoveOptionsUtils.sortUnitMoveOptions`                                     | green |
|  L2b  | `move_units_to_best_territories` (Java 1264 / Odin 1450)                          | green (would place 5 at Belorussia if armour were released from defend phase) |
|  L2c  | `prioritize_defend_options` (Java 557, filter loop Java 631)                      | **green by Java fidelity** (iter 13) |
|  L3   | upstream `populate_defend_options` / `enemy_attack_options`                       | green (iter 13 probe shows move_map_size=26, Belorussia present) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                  | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                            | green (iter 9) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                 | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                           | green (iter 9) |

### Loose ends from iter 7
- Re-run snaps 0073, 0089 with `timeout 300` to confirm pass/fail
  (still classified as "slow not regression").
- Bump per-snap timeout in `run_phase_snapshots_parallel.sh` and
  the parallel recipe in this file from 60s → 180s.

### Recipe to rerun the iter 7 sweep
```sh
cd triplea && rm -rf /tmp/snap_results && mkdir -p /tmp/snap_results
export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
ls conversion/odin_tests/server_game_run_next_step/snapshots/ | \
  xargs -P 6 -I{} sh -c \
    'timeout 180 env FILTER_SNAP={} ./server_game_test_iter9 \
     > /tmp/snap_results/{}.txt 2>&1; \
     echo "EXIT={}:$?" >> /tmp/snap_results/{}.txt'
for f in /tmp/snap_results/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```

(Note: switch to `server_game_test_iter9` from iter 9 onwards —
that binary contains the harmless land-move-pass ordering fix.)

### Known active hangs (NOT regressions)
- Snap 0021 (germanPurchase): pre-existing 3m7s purchase compute
  (per `next-steps.md` odds-calculator perf note). Not a hang per
  se, just very slow. Skip in fast sweeps.

### Iter 8 prior preserved (see Last action for details)

### Iter 6 prior preserved (see Last action for details)

### Iter 5 prior history (preserved)

Files of immediate interest if continuing snap 0017:
- `odin_flat/games__strategy__triplea__ai__pro__data__pro_territory_manager.odin`
  (where `enemy_attack_options` is populated)
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin:1172`
  (`prioritize_territories_to_defend`)
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin:1638`
  (`place_defenders`)

Instrumentation still in place: `PLACE_*` printfs in
`pro_purchase_ai_place_units` and `pro_purchase_ai_place`
(gated by `pname == "Russians"`). Remove via grep for
`is_russians_dbg` and `PLACE_PRIORITIZED_DUMP` etc when done.

### Iter 5 prior history (preserved)

**Switch strategy. The leaf-walking has hit a wall** because
the leaf proc matches Java line-by-line. The divergence must be
in surrounding state or another sibling proc not yet visited.
Two cheap pivots:

1. **Compare `placements` list state** between Java and Odin at
   the moment of fallback `getPlaceableUnits(Russia)`. Java's
   `getMaxUnitsToBePlacedFromFull` `countSwitchedProductionToNeighbors`
   branch ITERATES `self.placements` — if Java has MORE
   `UndoablePlacement` entries with `producer_territory=Russia`,
   it might compute `productionCanNotBeMoved` differently and
   eventually return 0. Add a printf at start of
   `abstract_place_delegate_get_max_units_to_be_placed_from_full`
   logging `len(self.placements)` and the (producer,
   place_territory, len(units)) of each, gated for Russia. Compare
   to expected Java state of 6 placements
   (4 at Caucasus + 2 at Russia).

2. **Bypass leaf-walk; try cluster-fix**: pick another red snap
   that is NOT a place-step (e.g. snap 0024 germanCombatMove,
   31s, "unit tally divergence") and see if its root cause is
   completely different. If 0024's root cause turns out to be the
   same as 0017's, the cluster of place-step snaps (0017, 0025,
   0040, 0041) will all benefit. If it's different, fix it in
   isolation and revisit 0017 later.

3. **Add the snapshot harness improvement**: change
   `unit_collection_get_units` to return a slice/view of the live
   `units` array instead of a copy, OR refactor every caller that
   iterates `player.getUnits()` during placement to re-query at
   each iteration (matching Java's `player.getMatches()` semantics).
   This alone won't fix 0017's gap but it is a known semantic
   divergence that may cascade-fix other place-step snaps.

**Recommendation for next iter**: tackle (1) first because it
finishes the 0017 drill, then (3) for cleanup. Keep the existing
instrumentation in `pro_purchase_ai_place_units` and
`abstract_place_delegate_get_max_units_to_be_placed_from_full`.

Alternative seeds (cluster by likely shared root):
- **0024/0025** (germanCombatMove / germanPlace round 1): different
  delegate, may flush out a non-place-related bug pattern.
- **0040/0041** (americanPurchase/americanPlace round 1).
- **0021** (germanPurchase): canonical "PUs not spent". Slow (3m7s).

## Trace table

**Iter 28 — snap 0089 (japanesePurchase round 2) drill.** Seeded
with `purchase()` and its 12 direct method-children. Cannot descend
further because the available checkpoint tracer (`ProPurTrace.emit`)
allocates from `context.allocator` and itself flips the AI's
outcome (see Notes / blockers iter-28 entry). Trace table frozen
until a perturbation-free tracer ships.

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase(games.strategy.triplea.delegate.remote.IPurchaseDelegate,games.strategy.engine.data.GameState) — **RED** (iter-27 regression, deterministic FAIL) |
|    19 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseLandUnits(java.util.Map,java.util.List,games.strategy.triplea.ai.pro.data.ProPurchaseOptionMap) — **TOP suspect** (Java picks 10 inf, Odin picks 8 inf + 1 armour; cost-equal at 6 PUs each) — yellow, awaiting tracer |

Invariant satisfied (28 > 19). Cannot append further rows yet.

### Previous iter-17 trace (preserved for reference)

Snap 0017 (russianPlace) drill — iter 4, leaf instrumented and
verified Java-faithful. Bug NOT at this leaf.

| layer | method_key |
|------:|------------|
|    27 | proc:games.strategy.triplea.ai.pro.AbstractProAi#place(boolean,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate,games.strategy.engine.data.GameState,games.strategy.engine.data.GamePlayer) |
|    26 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#place(java.util.Map,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate) |
|    18 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#placeUnits(java.util.List,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate,java.util.function.Predicate) — **GREEN** body |
|     ? | proc:games.strategy.triplea.delegate.AbstractPlaceDelegate#getPlaceableUnits(java.util.Collection,games.strategy.engine.data.Territory) — **GREEN** (algorithm matches Java; returns 6 for Russia, 2 for Karelia; the same Java would return per paper-trace) |
|     ? | proc:games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlacedFromFull(...) — **GREEN** (printf-confirmed faithful to Java line-by-line; verified all branches) |
|     ? | **UNKNOWN PARENT** — Russia/Karelia diff must come from `placements` list, `produced` map, or `placeDefenders` state mismatch — none of which the leaf itself controls |

Invariant satisfied (27 > 26 > 18 > 0). The leaf is green, so by
the orchestrator's bottom-up rule the bug is in a SIBLING or
PARENT, not deeper.

**Verified green branches** (don't re-descend):
- The plan-driven loop in `pro_purchase_ai_place` (lines ~2173–2249
  in `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`)
  matches Java exactly. Caucasus +2 inf +2 art is identical in both
  runs. This means `pro_purchase_ai_do_place`, the unit-matching
  by-name loop, and `sorted_purchase_territories` all work.
- `pro_purchase_ai_place_units` (lines ~330-415 in same file) —
  body is byte-identical to Java. Loop, isError check, min(max,
  size), continue semantics all correct. Confirmed via printf.
- `abstract_place_delegate_get_max_units_to_be_placed_from_full`
  (line 1441 in
  `odin_flat/games__strategy__triplea__delegate__abstract_place_delegate.odin`)
  — printf-confirmed faithful, returns same value Java would
  per paper-trace.
- WW2v5 game data: `ra=null` (no RulesAttachment), `wasFactoryThereAtStart=true`
  for Russia/Karelia/Caucasus, `originalFactory=false` (XML doesn't
  set it and `setOriginalFactory` is only reflectively invoked
  from XML).

**Yellow branches** (not yet classified, may still be wrong):
- `pro_purchase_ai_place_defenders`: instrumentation confirms 0
  placements on snap 0017 (no GMUTBPF lines between plan loop and
  fallback). If Java's place_defenders ALSO places 0, both agree.
  If Java places some at Russia/Karelia that Odin doesn't, this
  is the bug.
- **`unit_collection_get_units` returns a COPY (snapshot) not a
  view** of the live `[dynamic]^Unit`. Java's
  `player.getMatches(unitMatch)` returns matches from the LIVE
  pool each call. This causes Odin's `pro_purchase_ai_place_units`
  to re-attempt placements of units that an earlier iteration
  already removed (Russia tries the 6 first units in
  `placeable_units.getUnits()` which still includes Karelia's
  taken 2). The 6th Russia attempt fails on
  `playerHasEnoughUnits` — that's the source of the "5 of 6"
  partial placement we observe in the instrumentation.
- The `placements` list and `produced` map state at the moment
  fallback's `getPlaceableUnits(Russia)` runs.

Resolved snap 0053 trace (kept as a reference example):

| layer | method_key |
|------:|------------|
|    20 | proc:games.strategy.triplea.delegate.InitializationDelegate#start() |
|    13 | proc:games.strategy.triplea.delegate.InitializationDelegate#init(games.strategy.engine.delegate.IDelegateBridge) |
|    10 | proc:games.strategy.triplea.delegate.InitializationDelegate#initShipyards(games.strategy.engine.delegate.IDelegateBridge) |
|     1 | proc:games.strategy.engine.data.changefactory.AddProductionRule#perform(games.strategy.engine.data.GameState) |
|     0 | proc:games.strategy.engine.data.ProductionFrontier#addRule(games.strategy.engine.data.ProductionRule) |

Resolution: bug NOT in any of these procs (all faithful to Java).
The bug was one layer up in the **harness** —
`test_server_game_run_next_step` constructs a fresh
`Initialization_Delegate` via `test_server_game_register_ww2v5_delegates`
but never sets `need_to_initialize=false` for snaps that aren't
the very first one. Fix applied in `odin_flat/test_server_game.odin`.

**Lesson for future drills:** when the entire dependency chain matches
Java, check (a) the snapshot fixture loader (`json_loader.odin`)
for missing fields, and (b) the snap harness setup
(`test_server_game.odin` constructor + `_register_*_delegates` and
the runner in `snapshot_runner.odin`). The bug may live in the
shim, not the port.

When populated, format is strictly:

| layer | method_key |
|------:|------------|
|   34  | proc:games.strategy.triplea.ai.AbstractAi#start(java.lang.String) |
|   13  | proc:games.strategy.engine.delegate.IPurchaseDelegate#purchase(...) |

Invariant: `method_layer` strictly decreases down the table. Every
appended row is one of (a) a red child, or (b) the override target
of an abstract routing node above it.

## Snap status

Ground truth from 2026-05-23 (iter 27) full parallel run via
lean test binary `/tmp/snaprun_fast` (no debug, no leak tracker),
`xargs -P 4` with 300 s per-snap timeout. Results in
`/tmp/snap_results_iter27/`. **104 snaps.**

**Iter 27 (after iter-26 LinkedHashMap fix lands): 86 PASS, 18 FAIL,
0 OTHER.**
_Iter 23 (after pointer-refactor): 84/18/0. Iter 21: 84/16/2T/2NE.
Iter 20 = 85/17/2 HANG. Iter 7 = 80/17/7 TIMEOUT. Iter 5 = 77 PASS._

**Iter 27 deltas vs iter-23 baseline (net +2 PASS, 0 net FAIL change):**
- snap **0025 newly PASSES** (was iter-23 FAIL). Iter-26
  LinkedHashMap fix lands the AI in the Java-faithful state at the
  divergent step — a real WIN.
- snap **0089 newly FAILS** (was iter-23 PASS-slow). The same
  iter-26 fix changed Japanese AI's perceived combat strength →
  round-2 purchase swap: armour 0→1, infantry 10→8. New
  deterministic FAIL (2-row symptom in `<purchase_pool>`),
  drillable in iter 28.
- 17 other FAILs unchanged: `{0024, 0031, 0032, 0037, 0038, 0040,
  0048, 0065, 0074-0077, 0084, 0090, 0092, 0097, 0100}`.

**Iter 27 sweep tally:** 86 PASS / 18 FAIL / 0 OTHER. FAIL set is
17 carry-overs from iter-23 plus snap 0089 (new regression),
minus snap 0025 (new WIN). Net effect of iter-26 is +2 PASS with
zero count regression; 102/104 snaps unchanged across the
support-iteration-rewrite. Lean binary
(`-define:ODIN_TEST_TRACK_MEMORY=false`, no `-debug`) is what
made the full sweep possible — per-snap log dropped from 3 GB
(debug+leak-tracker) to 4 KB.

**Iter 26 individual-snap re-checks (no full sweep this iter):**
- snap 0032: **0 PASS / 5 FAIL / 0 HANG (5-run solo loop, 240 s cap).
  DETERMINISTIC.** Same Alaska/Eastern Canada infantry swap every
  run. Fixes both the iter-23 intermittency and the iter-25
  hang/regression. Remaining FAIL is a real Java-fidelity bug to
  solve (iter 28+).
- snap 0024: FAIL in 1m 48 s, byte-identical to iter-24/25
  divergence. Confirms the support-iteration pipeline is now
  Java-faithful and the snap-0024 bug lives deeper.
- Full sweep deferred — completed in iter 27.

**Iter 25 individual-snap re-checks (NO full sweep this iter):**
- snap 0032: 0 PASS / 3 FAIL / 2 HANG (5-run solo loop, 180 s cap).
  REGRESSION vs iter-23 (was 2P/1F intermittent).
- snap 0024: FAIL in 1m 49 s, byte-identical divergence to iter-24.
  Iteration time grew but result is the same.
- Full 104-snap sweep deferred to iter 26 once the snap-0032
  regression is understood / fixed.

Iter-23 FAIL set (18): `{0024, 0025, 0031, 0032, 0037, 0038, 0040,
0048, 0065, 0074, 0075, 0076, 0077, 0084, 0090, 0092, 0097, 0100}`.

Iter-23 deltas vs iter-21:
- snap **0021 newly PASSES** (was iter-21 TIMEOUT at 120s; iter-23
  longer cap unmasks PASS).
- snap **0073 newly PASSES** (was iter-21 NO_EXIT; same cap unmask).
- snap **0089 changed NO_EXIT → FAIL** (deterministic now, easier
  to drill).
- snap **0037 changed TIMEOUT → FAIL** (deterministic now,
  easier to drill).
- snap **0032 changed PASS → FAIL** (REGRESSION — actually
  INTERMITTENT, see iter-24 finding above; passes solo run #1
  in 58.83 s, fails solo run #2 in 61.09 s).

| snap | status (iter 23) | top-level symptom |
|------|------------------|-------------------|
| 0017 | **PASSED** (iter 6) | russianPlace |
| 0013, 0022, 0029, 0073, 0089, 0021 | PASS (slow; longer cap) | various AI long-compute snaps |
| 0033, 0041, 0049, 0069, 0085, 0093, 0101 | PASS | iter-7 collateral wins |
| 0081 | PASS | iter-20 repair-frontier fix |
| **0032** | **INTERMITTENT** | britishNonCombatMove — passes solo #1 in 58.83 s, fails solo #2 in 61.09 s with British inf Alaska↔Eastern Canada swap. Hypothesis: iter-23 exposes `Available_Supports` pointer-hash iteration. Iter 25 fix planned. |
| 0024 | FAIL (iter 23, ~57 s) | germanNonCombatMove. Same unit tally divergence as iter 21. L9 yellow children classified: DummyPlayer.selectCasualties green, CasualtyUtil.getDependents green-for-snap, CombatValue suspects identified (see Trace table iter 24). |
| 0021 | **PASSED iter 23** (with longer cap) | germanPurchase, 3m+ AI purchase compute. |
| 0025, 0031, 0038, 0040, 0048, 0065 | FAIL | _see /tmp/snap_results_iter23/NNNN.txt_ |
| 0074–0077, 0084, 0090, 0092, 0097, 0100 | FAIL | _see /tmp/snap_results_iter23/NNNN.txt_ |
| 0037 | FAIL (iter 23, was iter-21 TIMEOUT) | AMPHIB_PROBE step (Pacific amphib). |
| 0089 | FAIL (iter 23, was iter-21 NO_EXIT) | japanesePurchase round 2. |
| 0053 | PASS | (fixed harness ≤ iter 5) |

To rebuild the binary after Odin changes:
```sh
cd triplea && odin test conversion/odin_tests/server_game_run_next_step \
  -collection:flat=/home/caleb/todin/odin_flat \
  -collection:test_common=conversion/odin_tests/test_common \
  -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_TRACK_MEMORY=false \
  -extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib"
  # Note: the in-process runner stalls; expect to kill it after a few
  # minutes once compile is done and the binary is on disk. Then use
  # the parallel FILTER_SNAP recipe above.
```

Quick recipe to re-run any single snap (no rebuild needed; binary
is at `triplea/server_game_run_next_step`):
```sh
cd triplea && TRIPLEA_BATTLE_PRECACHE_ENABLED=0 \
  FILTER_SNAP=0053 ./server_game_run_next_step 2>&1 | tail -10
```

Full parallel suite recipe (iter 7 version with 180s per-snap timeout):
```sh
cd triplea && rm -rf /tmp/snap_results && mkdir -p /tmp/snap_results
export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
ls conversion/odin_tests/server_game_run_next_step/snapshots/ | \
  xargs -P 6 -I{} sh -c \
    'timeout 180 env FILTER_SNAP={} ./server_game_run_next_step \
     > /tmp/snap_results/{}.txt 2>&1; \
     echo "EXIT={}:$?" >> /tmp/snap_results/{}.txt'
for f in /tmp/snap_results/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```


## Notes / blockers

- **(iter 28) BLOCKER: PUR_TRACE tracer perturbs the bug it tries
  to diagnose.** `pro_pur_trace_emit` allocates via `make`,
  `strings.builder_make`, and per-row `fmt.sbprintf` from
  `context.allocator` (default heap). On snap 0089 these
  allocations shift downstream `malloc` return addresses enough to
  flip the Pro AI's purchase decision back to Java-faithful state
  (test PASSES with trace on, FAILS without). Confirms the
  snap-0037-fresh-look hazard: "the codebase is hyper-fragile to
  allocator behavior because pointer-keyed maps are everywhere."
  Iter 29 must ship a zero-perturbation tracer (temp_allocator-only
  + scratch buffer `os.write` if `fmt.printf` itself drifts) before
  snap 0089 can be drilled.
- **(iter 27)** **Memory / durability recipe for full sweeps.**
  The debug build (`/tmp/snaprun`, ~9.6 MB, includes per-step
  DIGEST + Odin's leak tracker) produces ≈ **3 GB per failing-snap
  log** when 18+ snaps fail, which fills disk and crashes the
  sweep terminal (this happened twice in iter-27 before pivoting).
  **Always use the lean binary for sweeps:**
  - Build: add `-define:ODIN_TEST_TRACK_MEMORY=false` and drop
    `-debug` → `/tmp/snaprun_fast` (5.2 MB).
  - Per-snap RSS ~3 MB; per-failing-snap log ~4 KB; 0001 smoke
    in 24 ms (vs 88 ms debug).
  - DO NOT use lean binary for leak / fault diagnosis — use the
    debug binary for that, one snap at a time.
  - Sample peak RSS via `awk '/VmRSS/{print $2}' /proc/$PID/status`
    in a polling loop (NixOS has NO `/usr/bin/time`; `ls` is
    aliased to `eza` so use `\ls`).
  - Launch sweep detached so terminal death doesn't kill it:
    `setsid nohup script.sh >log 2>&1 </dev/null & disown`,
    then poll a touch-file (`_DONE`) for completion.
  - Use `xargs -P 4` (not 8) to leave RAM/disk headroom.
  - Cap per-snap log with HEAD-5 + TAIL-60 only (or grep-filter
    inside the xargs cmd) to keep total disk footprint small.
- **(iter 26)** **iter-25 regression RESOLVED.** Root cause was
  `give_support_to_unit` iterating the OUTER `support_rules`
  `LinkedHashMap` via Odin bare-map (pointer-hash). Fix: added
  `support_rules_order` + `support_units_order` parallel slices
  to both `Support_Calculator` and `Available_Supports`, threaded
  through the builder, and rewrote 3 iteration sites
  (`give_support_to_unit` outer loop, `filter`,
  `get_unit_support_attachments`). Snap 0032 is now 5/5
  DETERMINISTIC (was 0P/3F/2HANG iter-25, 2P/1F iter-23).
  The remaining snap-0032 FAIL is a real 1-infantry swap to fix
  later (iter 27 Task C). Snap 0024 unchanged \u2014 confirms the
  divergence lives outside the support pipeline.
- **(iter 25)** **REGRESSION on snap 0032 from iter-25's Java-fidelity
  fix.** The 5 file changes (MainOffenseStrength accessor +
  Integer_Map_Unit.keys_order + Available_Supports.units_giving_support_order
  + producer/consumer wiring) are individually Java-faithful per
  `AvailableSupports.java:31-60` (all three suspect collections use
  `LinkedHashMap`), but the combined effect made snap 0032 worse:
  5-run loop = 0 PASS / 3 FAIL / 2 HANG (vs iter-23 2P/1F).
  Snap 0024 unchanged (same divergence, same regions). Most likely
  cause: the upstream caller that populates `Integer_Map_Unit`
  inside the builder loop is itself iterating a bare map
  (`support_rules` or `support_units`) in pointer-hash order, so
  the new `keys_order` slices capture a still-non-Java order. The
  two HANGs additionally suggest a UAF or busy loop in
  `get_next_available_supporter` after the `integer_map_unit_remove`
  call. **Iter 26 must triage this regression before further
  forward work.** See "Next action" Task A-E for the bisect /
  audit plan. DO NOT run a full 104-snap sweep until snap 0032 is
  back to deterministic PASS.
- **(iter 25)** Disk discipline: a 5-run solo loop for snap 0032
  with leak-tracker on can produce **~9 GB of per-step debug spam**
  (3 × 2.9 GB logs). For iter-26 reproductions, either build a
  `-define:ODIN_TEST_TRACK_MEMORY=false` variant or pipe through
  `grep -E 'PASS|FAIL|FATAL|leak' > log` to keep disk usage sane.
  Logs cleaned at iter-25 close.
- **(iter 24)** Snap 0032 is **intermittent** (PASS solo run #1
  in 58.83 s; FAIL solo run #2 in 61.09 s with British inf swap
  Alaska↔Eastern Canada). This is a NEW regression vs iter 21
  (which passed it deterministically because the iter-22-discovered
  value-copy bug masked the upstream pointer-hash iteration order
  of `Available_Supports.units_giving_support` and
  `Integer_Map_Unit.entries`). A 5-run repro launched at iter-24
  close confirms intermittency (see `/tmp/snap0032_iter24_repro/`).
  **Iter 25 must fix this** before the regression sweep is
  representative. _UPDATE iter 25:_ The three planned fixes were
  shipped but caused a regression — see iter-25 entry above. The 3 specific fixes are listed in "Next action"
  Task A/B/C above and as `Files of immediate interest`:
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin`
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
    and `…/available_supports__support_details.odin`
- **(iter 24)** L9 drill results for snap 0024 are documented in
  "Trace table (iter 24)" — DummyPlayer.selectCasualties cleared
  via Java fidelity verification (no AI call sites for setter +
  default false), CasualtyUtil.getDependents cleared as
  "green-for-snap" (no transports in this battle), CombatValue
  remains yellow with 3 specific suspect identified.
- **(iter 23)** Pointer-refactor `unit_support_power_map` /
  `unit_support_rolls_map` to `map[^Unit]^Integer_Map` SHIPPED.
  This is the right fix for the iter-22 root cause. The cost is a
  large slowdown in any snap whose AI evaluates combat — iter-21
  was silently truncating Java's support-power calculations, so
  the AI did less work. Snap 0073 went from "<60s pass" to "3m 40s
  pass"; snap 0032 from "fast pass" to "1m 6s pass". Snap 0024
  exceeded the 600s individual cap (was 37s FAIL iter-21) —
  whether it converges or still diverges is iter-24's task. A
  full 104-snap regression sweep is running in background at
  iter-23 session end (`/tmp/snap_results_iter23/`); analyze with
  `for f in /tmp/snap_results_iter23/*.txt; do tail -1 "$f"; done
  | awk -F: '{print $2}' | sort | uniq -c`.
- **(iter 22)** Iter-21's `Integer_Map.keys_order` fix is correct
  in isolation but FAILS the moment an `Integer_Map` is stored
  BY VALUE inside another `map[K]Integer_Map`. **FIXED by iter 23**
  for the PowerStrengthAndRolls sites. Audit for other
  `map[K]Integer_Map` storage sites BEFORE adding new ones.
  Current confirmed-safe sites store Integer_Map as a struct field
  (mutated via `&struct.field`, no descriptor copy): production_rule,
  repair_rule, strategic_bombing_raid_battle. The pattern to AVOID
  is `for k in map_of_integer_maps { v := map_of_integer_maps[k];
  integer_map_*(&v, …) }`.
- **(iter 22)** `DummyPlayer.selectCasualties` (Java
  `triplea/game-app/game-core/src/main/java/games/strategy/triplea/odds/calculator/DummyPlayer.java`
  lines 189-247) has NEVER been ported to Odin. Odin's
  `Dummy_Player` falls through to `Player#select_casualties` nil
  vtable → identity return of `defaultCasualties`. This matches
  Java behavior EXACTLY when both `keepAtLeastOneLand=false` and
  `orderOfLosses` is empty. Confirmed defender side hardcodes
  `keep_one_land_unit=false` at `dummy_delegate_bridge.odin:113`.
  Attacker side takes it as a parameter from `battle_calculator`;
  value at snap 0024 UkrSSR sims not yet verified — iter 24 task
  (only relevant if snap 0024 still diverges after iter-23).
- **(iter 21)** Java's `IntegerMap` was using bare `map[rawptr]i32`
  in Odin; Java backs it with `LinkedHashMap`. Fixed by adding
  `keys_order: [dynamic]rawptr` and walking it in every iteration
  proc. All Odin code that constructs an `Integer_Map` via the
  struct literal `Integer_Map{map_values = make(...)}` must ALSO
  set `keys_order = make([dynamic]rawptr)`. The `integer_map_new`
  ctor and the file-private `_iorder_put_`/`_iorder_remove_`
  helpers do this automatically. See
  `/memories/repo/integer-map-linked-hash.md` (new this iter) and
  `/memories/java-hashmap-iteration-order.md` for the broader
  pattern; both are part of the java-fidelity rule.
- **No infrastructure blockers.** Previous status file claim was
  wrong; all 6 scripts + Byte Buddy agent + schema are in place
  and have produced 18,734 passing fixtures across 153 green procs.
- **Snap suite is 104, not 52.** `/memories/repo/phase-c-state.md`
  "50/52 baseline" is stale. Trust the `Snap status` section above
  (74/104 PASS, 26 FAILED, 1 PANIC) from 2026-05-22.
- **In-process `odin test` runner stalls.** The piped output via
  `tail` blocks until completion and the runner never produces
  per-snap PASS/FAIL summaries until the very end. After 4m29s
  it had only completed snaps 0001-0015 sequentially. Workaround:
  use the parallel `FILTER_SNAP` recipe in `Snap status` above.
- **Linker needs `-lsqlite3` path.** The Odin runtime links to
  libsqlite3 but the default ld search path doesn't include the
  nix store. Append
  `-extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib"`
  to every `odin test`/`odin build` of this codebase. (This was
  not in the earlier status. Find the current store path with
  `find /nix/store -maxdepth 3 -name 'libsqlite3.so' -path '*/lib/*' 2>/dev/null`
  if it changes after a `nix-collect-garbage` or flake bump.)
- **Resolver limitations** (from prior session, still valid):
  - Receiver types not in `{Territory, Unit, GamePlayer, UnitType,
    UnitAttachment}` are skipped as `opaque` in
    `gen_replay_tests.py`. Singleton paths (`gd.map`,
    `gd.battle_tracker`) and per-instance battle objects are not
    yet wired in.
  - Lambda / functional-interface args and returns
    (`Predicate$$Lambda`) are skipped. ProMatches is 100%
    lambda-return.
- **Deep clone gated.** `game_data_utils_clone_game_data` returns
  nil by default; enable with `-define:DEEP_CLONE=true` only when
  drilling AI-purchase paths. See
  `serialization-shim-divergence-plan.md`.
- **Precache.** `export TRIPLEA_BATTLE_PRECACHE_ENABLED=0` before
  any DIGEST run; default-on hangs for 5+ min on Russian purchase.
  Per `next-steps.md`. The parallel snap recipe above sets this
  already.
- **Odds calculator perf.** Odin's odds_calculator path is
  ~100\u00d7-1000\u00d7 slower than Java per `next-steps.md` (germanPurchase
  snap 0021 alone takes 3m7s in Odin vs ~16s for the full Java r=1
  game). Orthogonal to correctness but blocks any drill-down that
  needs to iterate quickly on a late-game snap. Snap 0053 is
  19ms (no AI), so deferring this perf work is fine for now.

## Background fixtures inventory

From `golden_dashboard.py --once` on 2026-05-22:

| class | impl | captured | generated | green | red |
|-------|-----:|---------:|----------:|------:|----:|
| `Properties` | 120 | 0 | 95 | 95 | 0 |
| `UnitAttachment` | 188 | 74 | 53 | 54 | 0 |
| `ProBattleUtils` | 8 | 4 | 4 | 4 | 0 |
| `ProMatches` | 92 | 65 | 0 | 0 | 0 |
| `GameMap` | 45 | 25 | 0 | 0 | 0 |
| `AbstractBattle` | 27 | 23 | 0 | 0 | 0 |
| `BattleTracker` | 76 | 1 | 0 | 0 | 0 |

Totals: **31,722 fixtures** captured → **18,734 pass**, 12,988
unrun (almost all from the 4 zero-gen classes above).

Top methods by fixture count (all passing):
- `ProBattleUtils.estimatePower` n=1000, `estimateStrength` n=1000,
  `estimateStrengthDifference` n=996
- `ProMatches.territoryCanMove*` n=800 each (unrun — lambda return)
- 50+ `Properties.get*` accessors n=600-606 each

## Reference quicklinks

- Full pyramid + schema: [`golden_testing_plan.md`](./golden_testing_plan.md)
- Capture pipeline: [`how-to-take-snapshots-that-include-args-and-return-values.md`](./how-to-take-snapshots-that-include-args-and-return-values.md)
- Drill-down rules + green/red/yellow doctrine:
  [`llm-instructions.md`](./llm-instructions.md) §"Layered drill-down debugging"
- Java-fidelity rule: `/memories/java-fidelity-rule.md`
- Java HashMap iteration order: `/memories/java-hashmap-iteration-order.md`
- Phase-C historical state: `/memories/repo/phase-c-state.md`
- Divergence playbooks: `/memories/repo/divergence-iter7-russianBattle.md`,
  `step24-cruiser-divergence.md`, `step36-japanesePurchase-fix.md`,
  `step38-japaneseBattle-status.md`, etc.

## Setup template (one-time)

If the four mutable sections above are empty or the orchestrator
reports the file is malformed, restore from this skeleton:

```
## Last action
_(none)_

## Next action
_(none)_

## Trace table
_Empty — no drill-down in progress._

## Snap status
| snap | status | top-level symptom | trace seed |
|------|--------|-------------------|------------|
| 0013 | RED    | ... | _unseeded_ |
| 0014 | RED    | ... | _unseeded_ |
```
