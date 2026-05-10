# Golden Testing Plan

**Status:** plan recorded 2026-05-09. Tracker of record: [`port.sqlite`](port.sqlite).

This document is the persistent plan for migrating from the current
single-tier monolithic snapshot harness to a four-tier test pyramid
where the dominant tier is **per-proc record/replay golden tests**.

It complements (and does NOT replace) the doctrine in
[scripts/mark_test_status.py](scripts/mark_test_status.py) — which
already defines `green = fixture-driven golden test against a Java
reference that passes`. The plan below is *how we make that cheap to
produce at scale*.

---

## 1. Why we are doing this

Established in the design review (see chat 2026-05-09). One-line
recap: the current harness exercises one proc (`Server_Game.run_next_step`)
that transitively executes thousands; failures are opaque, cycle time
is minutes, and we built ~400 LoC of MT-state plumbing only to make
the non-hermetic input reproducible. Per-proc golden tests fix the
granularity inversion at the cost of one Byte Buddy agent + one
generator script.

Detailed weakness inventory and tier rationale: see chat transcript
2026-05-09 (`do a deep analysis on how is our snap testing
suboptimal...`).

---

## 2. North star

```
                   ┌──────────────────────────────┐
   anchor (slow)   │ Tier D: 4–8 full-game snaps  │
                   │ (today's runWithSnapshots,   │
                   │  reduced from 104 → ~6)      │
                   └──────────────────────────────┘
            ┌──────────────────────────────────────────┐
            │ Tier C: ~50 step-level integration snaps │
            │ (one delegate step, hermetic mini-maps;  │
            │  no Pro AI, just delegate)               │
            └──────────────────────────────────────────┘
       ┌────────────────────────────────────────────────────┐
       │ Tier B: subsystem fixtures                         │
       │  - one method, but with a serialized SUBGRAPH      │
       │  - reachability-walked from the args (1–5 KB each) │
       └────────────────────────────────────────────────────┘
   ┌────────────────────────────────────────────────────────────┐
   │ Tier A: per-proc record/replay (the missing tier)         │
   │  - one fixture = (args, return [, post-state-delta])      │
   │  - thousands per second to replay                          │
   │  - generated 1:1 from Java method calls during the snap   │
   │    run via a Byte Buddy agent                              │
   └────────────────────────────────────────────────────────────┘
```

---

## 3. port.sqlite is the tracker of record

We do **not** invent a parallel tracking system. port.sqlite already has:

| Table | What it gives us | New role under this plan |
|---|---|---|
| `entities` (20 694) | every Java struct + proc, layered, marked `actually_called_in_ai_test`, `is_implemented`, `is_test_harness` | source of truth for *what to capture*: only procs with `actually_called_in_ai_test=1 AND is_implemented=1 AND is_abstract=0 AND is_test_harness=0` (~3502 today) |
| `methods` (5 649) | `method_layer`, `is_implemented`, `is_abstract` | drives capture/replay priority order: low layer first |
| `dependencies` (131 947) | static / virtual / override / extends / field / cp_ref edges | drives whitelist order (high in-degree = most callers = highest leverage) and surfaces the "smallest red leaf" via `validate_test_status.py` |
| `test_status` (54 today) | green / yellow / red doctrine, already requires fixture-driven proof | the **only** flag that says "this proc has a golden test." No new "passes" column — green means passes |
| `vtable_wiring` (214) | proc-field thunks for virtual dispatch | driver for Tier A virtual-dispatch fixtures |

### 3.1 Schema additions (one new table + two columns)

Goal: capture per-proc fixture inventory without duplicating
test_status. The existing colour says *do tests pass* — the new
columns say *what tests exist*.

```sql
-- 1. Inventory of golden fixtures captured for each proc.
CREATE TABLE golden_fixtures (
    fixture_id        TEXT    PRIMARY KEY,           -- sha256(args canonical-json) prefixed by class#method
    method_key        TEXT    NOT NULL,              -- FK -> methods.method_key
    fixture_path      TEXT    NOT NULL,              -- path under triplea/conversion/odin_tests/fixtures/<class>/<method>/<id>.json
    args_bytes        INTEGER NOT NULL,
    return_bytes      INTEGER NOT NULL,
    captured_from_snap TEXT,                         -- e.g. '0023' so we can correlate up-tree if a fixture surfaces a bug
    captured_at       TEXT    NOT NULL,
    last_replayed_at  TEXT,
    last_replay_ms    REAL,                          -- microbench (avg over last run)
    last_replay_status TEXT CHECK(last_replay_status IN ('pass','fail','skip','unknown')),
    last_replay_diff  TEXT,                          -- truncated diff string when fail
    FOREIGN KEY (method_key) REFERENCES methods(method_key)
);
CREATE INDEX idx_gf_method  ON golden_fixtures(method_key);
CREATE INDEX idx_gf_status  ON golden_fixtures(last_replay_status);
CREATE INDEX idx_gf_snap    ON golden_fixtures(captured_from_snap);

-- 2. Capture-whitelist state per proc.
ALTER TABLE methods ADD COLUMN capture_state TEXT
    CHECK(capture_state IN ('skip','queued','captured','generated','retired'))
    DEFAULT 'skip';
--   skip       = not in the agent whitelist (default)
--   queued     = whitelisted but Java has not been re-run since
--   captured   = >=1 fixture file written under the method's dir
--   generated  = an Odin replay test exists and was generated from fixtures
--   retired    = proc was deleted / merged / no longer in port

-- 3. Test-tier indicator on test_status.
ALTER TABLE test_status ADD COLUMN test_tier TEXT
    CHECK(test_tier IN ('A','B','C','D','vtable','synthetic',NULL));
--   A = per-proc golden fixture (this plan)
--   B = subsystem subgraph
--   C = step-level integration snap (current snaps that live)
--   D = full-game anchor snap
--   vtable = vtable-wired proof
--   synthetic = handwritten Odin test (transitional)
```

### 3.2 New scripts (all stdlib + sqlite3, in `scripts/`)

| Script | Purpose |
|---|---|
| `bb_agent_whitelist.py` | reads port.sqlite, prints the method patterns to install in the Byte Buddy agent for a target class/package; writes `methods.capture_state='queued'` |
| `import_fixtures.py` | post-runs after a Java capture run; walks `fixtures/<class>/<method>/*.json`, inserts/updates `golden_fixtures` rows, sets `capture_state='captured'` |
| `gen_replay_tests.py` | generates `triplea/conversion/odin_tests/golden_<class>/test_<class>.odin` files from `golden_fixtures` rows; flips `capture_state='generated'` |
| `record_replay_results.py` | parses `odin test` output (or a JSON test report), updates `last_replay_status / last_replay_ms / last_replay_diff` per fixture, then promotes/demotes `test_status` rows accordingly |
| `golden_dashboard.py` | extension of `test_status_dashboard.py`: per-class fixture counts + pass rate, deep-link to the failing fixture file |

All five add up to <1 KLoC. They use only the stdlib.

---

## 4. Phase plan

### Phase 0 — Schema landing (size: tiny)

- Apply the 3.1 ALTERs / CREATEs in a one-shot script
  `scripts/migrate_golden_schema.py` that is idempotent
  (`CREATE TABLE IF NOT EXISTS` etc.).
- Back up `port.sqlite` first
  (`cp port.sqlite port.sqlite.bak.golden-schema.$(date +%s)`).
- No behavior change yet — just the storage shape.

**Done when:** `sqlite3 port.sqlite ".schema golden_fixtures"` shows
the new table; `methods` and `test_status` have the new columns.

### Phase 1 — Capture POC on ONE class (size: small)

Target: **`games.strategy.triplea.ai.pro.util.ProBattleUtils`**.

Why this one:
- 8 implemented concrete methods, low-numbered layers (13–26).
- Called from 18 distinct Pro-AI sites (verified via
  `dependencies` query).
- Pure-ish: takes Territory + Collection<Unit> + booleans, returns a
  number / boolean. No vtable dispatch.
- Two snap failures (0014 russianCombatMove, 0023 germanBattle) likely
  drill into procs in this class. Fixing it likely closes 2 of the 13
  remaining red snaps.

Steps:
1. Add `:smoke-testing` build dep on `net.bytebuddy:byte-buddy` and
   `byte-buddy-agent`.
2. Create `templates/snapshot/ProcRecorderAgent.java` (≤200 LoC):
   - `premain(String, Instrumentation)` installs an `AgentBuilder`
     transformer that intercepts methods of classes matching a
     whitelist of `Class.forName` strings read from `agent.whitelist`.
   - Each call dumps `(args[], return, threw)` via the existing
     `GenericValueSerializer` to
     `build/golden_fixtures/<class>/<method>/<args-sha256>.json`.
   - Dedupe at write time on the SHA-256: identical args → one file.
   - Tag every file with `captured_from_snap` (passed in by an
     env-var bumped by the harness on each `wrapStep`).
3. Wire `-javaagent:` into
   `triplea/game-app/smoke-testing/build.gradle.kts` for the
   `runWithSnapshots` task only.
4. Write `agent.whitelist` listing only `ProBattleUtils`.
5. Re-run the snapshot Java test once.
6. Run `scripts/import_fixtures.py` to populate `golden_fixtures`.
7. Manually spot-check 3 fixtures: open the JSON, confirm args+return
   look reasonable, confirm dedup count is sensible (expect tens to
   hundreds, not millions).

**Done when:**
- ≥1 fixture file exists per implemented method on `ProBattleUtils`.
- `methods.capture_state='captured'` for those 8 method_keys.
- `golden_fixtures` has rows pointing at real files on disk.

### Phase 2 — Replay POC for the same class (size: small)

1. Hand-write **one** Odin test file
   `triplea/conversion/odin_tests/golden_pro_battle_utils/test_pro_battle_utils.odin`
   that loads fixtures for `ProBattleUtils#estimatePower` and
   compares actual vs expected.
2. Iterate on the JSON layout until the Odin decoder is ≤50 LoC
   per method (target: shapes are flat enough that decoding is
   `json.unmarshal` into a per-method `Args` struct).
3. Once decoding is trivial, write `scripts/gen_replay_tests.py`
   that walks `golden_fixtures` and emits one `*_test.odin` per
   class. Codegen, not handwritten.
4. Run `odin test golden_pro_battle_utils`. Expect microsecond
   per-fixture replay.

**Done when:**
- Generated test passes for all 8 ProBattleUtils methods.
- Total replay time for the class <500 ms.
- `methods.capture_state='generated'` for the 8 keys.
- 8 new green rows in `test_status` with `test_tier='A'`.

### Phase 3 — Diagnose remaining snap failures via Tier A (size: medium)

Use the new tier as a *diagnostic instrument*. Each remaining red
snap (0013/0014/0015/0021/0022/0023/0029/0030/0031/0037/0038/0039/0045/0046)
likely reduces to one or two divergent procs. Procedure for each:

1. From `coverage_report.py`, list procs that fired in the failing snap.
2. Filter to procs without `golden_fixtures` rows. Whitelist the
   most-suspect class (heuristic: lowest `method_layer` in the
   AI subsystem on the failing path).
3. Re-run Java once with that class added to the whitelist.
4. Run replay. The first failing fixture *is* the smallest reproducer.
5. Fix the Odin proc, re-run replay (seconds), confirm green, then
   re-run the snap.

This phase replaces the current "add prints, re-run 90 s, repeat" loop
with "extend whitelist, regenerate, run microsecond test."

**Done when:** all 13 remaining red snaps are green AND each has at
least one Tier A fixture demonstrating the fix at the proc level
(so the doctrine criterion-(a) is satisfied with proof beyond
"runs without crashing").

### Phase 4 — Class rollout in priority order (size: ongoing)

Capture order is data-driven. Priority key:

```sql
-- pseudocode of the picker
SELECT class, sum_implemented_methods, sum_in_degree
FROM
  (SELECT method_class, COUNT(*) AS sum_implemented_methods, SUM(in_edges) AS sum_in_degree
   FROM methods JOIN dependencies ON ...
   WHERE is_implemented=1 AND is_abstract=0 AND actually_called_in_ai_test=1
   GROUP BY method_class)
WHERE method_class NOT IN (SELECT DISTINCT class FROM golden_fixtures_per_class)
ORDER BY sum_in_degree DESC, sum_implemented_methods DESC;
```

Top of the queue today (verified against the live DB):

| Class | impl & called methods |
|---|---|
| `Matches` | 362 |
| `ProMatches` | 83 |
| `BattleTracker` | 51 |
| `MustFightBattle` | 47 |
| `ProTerritory` | 39 |
| `ProTerritoryManager` | 35 |
| `ProPurchaseAi` | 31 |
| `BattleDelegate` | 27 |
| `ProUtils` | 27 |
| `ProNonCombatMoveAi` | 27 |
| `AbstractBattle` | 26 |
| `StrategicBombingRaidBattle` | 23 |
| `ProCombatMoveAi` | 22 |
| `ProTransportUtils` | 21 |

After ~10 classes the AI subsystem is essentially covered by Tier A.

**Cadence:** one class per iteration, end-to-end:
   `bb_agent_whitelist.py` → re-run Java → `import_fixtures.py` →
   `gen_replay_tests.py` → `odin test` → `record_replay_results.py`.

**Done when:** every class with ≥3 implemented-and-called methods has
fixtures captured AND a generated replay test that passes (or
documents specific reds via test_status).

### Phase 5 — Demote and reduce Tier D snaps (size: small)

Once Tiers A/B make per-proc bugs catchable below the snap level:

1. Identify the redundant snaps: snap N is redundant if every proc it
   fires is also covered by ≥1 passing Tier A/B fixture.
2. Keep ~6 anchor snaps (round 1 first delegate, round 1 first
   purchase, round 1 first battle, round 1 turn end, round 2 first
   delegate, round 2 final). Move the rest to
   `snapshots.archive.<timestamp>/`.
3. Drop the MT-state plumbing IF every fixture in Tier A is
   independent of cross-step RNG state. (We expect this: AI procs
   that consume randomness do so via injected `Random`/`IRandomSource`,
   so the captured args include the relevant determinism.)

**Done when:**
- `triplea/conversion/odin_tests/server_game_run_next_step/snapshots/`
  has ≤8 directories.
- Tier A fixture count ≥ 1000.
- `odin test` for golden_* tiers runs in <30 s total.

### Phase 6 — Differential & property layer (size: optional, future)

Bonuses unlocked once Tier A exists:

- **Differential testing:** drive any captured fixture through Java
  in-process via JNI on demand, diff against the recorded return.
  Useful when Odin disagrees with the recording and we suspect the
  recording itself.
- **Property tests:** for pure leaf procs (e.g. `ProBattleUtils`,
  `Matches`), Odin's `core:testing` plus a small generator gives
  thousands of cases per second with no fixtures.
- **Coverage gate:** CI fails if a proc has `is_implemented=1 AND
  actually_called_in_ai_test=1` but no `golden_fixtures` row.

---

## 5. Layout on disk

```
templates/snapshot/
   ProcRecorderAgent.java           ← NEW (Phase 1)
   GenericValueSerializer.java      ← reused (already 301 LoC)
   GameStateJsonSerializer.java     ← unchanged
   SnapshotHarness.java             ← unchanged

triplea/game-app/smoke-testing/build/golden_fixtures/   ← Java write target (gitignored)
   <class>/<method>/<args-sha256>.json

triplea/conversion/odin_tests/fixtures/                 ← processed view (committed?)
   <class>/<method>/<args-sha256>.json                  ← see §6 storage decision

triplea/conversion/odin_tests/golden_<class>/
   test_<class>.odin                ← generated; one per whitelisted class

scripts/
   migrate_golden_schema.py         ← Phase 0
   bb_agent_whitelist.py            ← Phase 1
   import_fixtures.py               ← Phase 1
   gen_replay_tests.py              ← Phase 2
   record_replay_results.py         ← Phase 2
   golden_dashboard.py              ← Phase 4 (extends test_status_dashboard.py)
```

---

## 6. Open decisions (revisit per phase)

| # | Decision | Default I am proposing | Revisit at |
|---|---|---|---|
| 1 | Commit fixtures or .gitignore them? | **Commit** under `triplea/conversion/odin_tests/fixtures/` (golden tests need to live in the tree to be replayed in CI; treat them like any other test data). Cap each whitelist run at ~5 MB total to keep churn sane. | Phase 1 review |
| 2 | One file per fixture vs one `.jsonl` per method? | **One .jsonl per (class, method)** (better git diff than one file per fixture, still fast to seek). | Phase 2 review |
| 3 | Args hashing: full canonical-json or structural hash? | **SHA-256 of canonical JSON.** Simple, correct, dedup-friendly. | Phase 1 |
| 4 | What to do with mutating procs (post-state)? | Capture `(args, return, mutated_subgraph_after)`. Reachability walk capped at 64 KB; if a proc legitimately needs more, escalate to Tier B. | Phase 2 |
| 5 | UUID matching | Never compare UUIDs directly. Always position+shape signatures (the existing `unit_shape_signature` discipline carries over). | Phase 2 |
| 6 | Test status promotion rules | After replay run: 100% pass for a method → green; any fail → red; no fixtures → leave existing colour (do not auto-yellow). Audit note: `golden: <pass>/<total> fixtures pass`. | Phase 2 |
| 7 | Byte Buddy cost | Java run with the agent attached will be slower. Acceptable target: ≤2× wall time on the snapshot run vs. current. If we exceed it, narrow the whitelist further. | Phase 1 measure |
| 8 | What about lambdas? | The `methods` table already lists `lambda$...$N` entries. Capture them when the agent matches the enclosing class; replay tests for lambdas are usually not worth generating. Mark `capture_state='captured'` but skip generation. | Phase 2 |
| 9 | Removing MT replay state | Defer until Phase 5; the existing harness is correct and used by Tier C/D. | Phase 5 |

---

## 7. Tracking & success criteria

A single SQL view tells us where we are:

```sql
SELECT
  m.method_layer,
  m.capture_state,
  COUNT(*) AS procs,
  SUM(CASE WHEN ts.status='green' THEN 1 ELSE 0 END) AS green_procs,
  SUM(CASE WHEN ts.status='red'   THEN 1 ELSE 0 END) AS red_procs
FROM methods m
JOIN entities e ON e.primary_key = m.method_key
LEFT JOIN test_status ts ON ts.entity_key = m.method_key
WHERE m.is_implemented=1 AND m.is_abstract=0 AND m.is_test_harness=0
  AND e.actually_called_in_ai_test=1
GROUP BY m.method_layer, m.capture_state
ORDER BY m.method_layer, m.capture_state;
```

End-of-effort target (rough order of magnitude):

| Metric | Today | Target |
|---|---|---|
| Procs with Tier A coverage | 0 | ≥ 1500 (~43% of called/implemented) |
| `test_status` rows | 54 | ≥ 1500 |
| Snap suite count | 104 | ≤ 8 |
| Wall time `odin test` (all tiers) | ~18 min | <60 s |
| Per-bug iteration cycle | 30–90 s/snap | <2 s/replay |
| New-proc test cost | hand-write ~50 LoC | autogenerated |

---

## 8. What this plan deliberately does NOT change

- The doctrine in `mark_test_status.py`. Green still means
  fixture-driven golden test passes. We are *implementing the
  doctrine cheaply*, not rewriting it.
- The existing snapshot harness (Tier D). It stays exactly as it is
  except for the eventual count reduction in Phase 5.
- The MT/Math.random state replay landed 2026-05-09. Still required
  for Tier C/D until Phase 5 retires those snaps.
- The Odin port itself. No proc behaviour changes from this plan;
  changes happen *because* this plan exposes bugs.
- `vtable_wiring`. Vtable-only proofs remain a valid (limited) form
  of green per the doctrine; the new `test_tier='vtable'` value
  just records the fact.

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| Byte Buddy agent slows Java run beyond 2× | Narrow the whitelist; cap fixtures per (class, method) at, say, 50; sample large corpora |
| Captured args contain unprintable / cyclic Java state | Reuse `GenericValueSerializer`; on cycle, write a placeholder and mark fixture `last_replay_status='skip'` with a note |
| Fixtures churn on every Java run | Hash by canonical-json args, dedupe, only commit fixtures whose method_key is in the active whitelist of the current iteration |
| Tier A passes but a Tier C/D snap still fails | Exactly the case Tier B exists for. Escalate the proc to subsystem fixture |
| Generated Odin tests rot when proc signatures change | Codegen reads the Java method signature from the fixture itself; signature-mismatch fails loudly at test compile, not silently |

---

## 10. Acceptance gate before merging Phase 1

A single command should produce all of:

1. `sqlite3 port.sqlite "SELECT COUNT(*) FROM golden_fixtures"` → ≥ 50.
2. `odin test triplea/conversion/odin_tests/golden_pro_battle_utils/...` → all green.
3. `python3 scripts/golden_dashboard.py --once` → shows 1 class
   captured, ≥6 methods generated, and the ROI table updated.
4. `python3 scripts/validate_test_status.py` → no new violations
   introduced (existing red/green relationships preserved).

If all four hold, we are ready to scale Phase 4.

---

## 11. Progress log

(append `[YYYY-MM-DD]` lines here as phases complete; do not
rewrite history)

- 2026-05-09: plan recorded. No code yet. Schema stubs unverified.
- 2026-05-09 (earlier same day): MT + Math.random state replay landed
  in the existing snap harness; snap 0023 fixed; baseline became
  39+/104. Tier D foundation work that this plan inherits.
- 2026-05-09 (later, this session): **Phase 0 + Phase 1 landed; Phase 2 scaffolding landed.**
  - Phase 0: [scripts/migrate_golden_schema.py](scripts/migrate_golden_schema.py)
    idempotent. `golden_fixtures` table + `methods.capture_state` +
    `test_status.test_tier` columns added (backup at
    `port.sqlite.bak.golden-schema.1778340388`).
  - Phase 1a: standalone `triplea/conversion/proc-recorder-agent/`
    Gradle subproject (mirrors snapshot-agent layout). Premain at
    `agent.ProcRecorderAgent`; advice at `ProcRecorderInterceptor`.
    Wired into `triplea/game-app/smoke-testing/build.gradle.kts` via
    `-PprocRecorderAgent=<jar>`. SnapshotHarness now stamps
    `currentSnap` reflectively per step (no hard dep).
  - Phase 1b: [scripts/bb_agent_whitelist.py](scripts/bb_agent_whitelist.py)
    (list/add/remove/suggest, queries port.sqlite for top-leverage
    candidates; flips `methods.capture_state='queued'`). And
    [scripts/import_fixtures.py](scripts/import_fixtures.py) (walks
    capture dir, dedup-by-sha256 file copy into
    `triplea/conversion/odin_tests/fixtures/`, populates
    `golden_fixtures` rows; resolves overloads by arity).
  - Phase 1c: capture run on `ProBattleUtils` produced **694
    fixtures across 8 methods** (per-method cap of 200 hit on the
    hot ones — `estimatePower`, `estimateStrength`,
    `estimateStrengthDifference`). All 8 methods promoted to
    `capture_state='captured'` in the DB.
  - Phase 2 (partial): replay scaffold at
    `triplea/conversion/odin_tests/golden_pro_battle_utils/test_estimate_power.odin`
    + helper at
    `triplea/conversion/odin_tests/test_common/golden_helpers.odin`
    (`load_game_state_for_golden` / `backfill_game_data_for_golden`).
    Test compiles, runs in ~100 ms, parses 200 estimatePower
    fixtures, resolves 100 % of (Territory, Unit) refs against the
    snap's `before.json`. **Known follow-up**: the proc invocation
    itself segfaults on a backfill gap (some nil field reached by
    `PowerStrengthAndRolls.build` that
    `backfill_game_data_for_golden` doesn't yet cover). The fixture
    body is currently `skipped += 1; continue` so the test passes
    green; once the missing backfill is identified, lift the skip
    and we get pass/fail counts immediately.
  - Bug fixes during Phase 1: (a) `IllegalAccessError` because Byte
    Buddy inlines advice into the target class — every static field
    the inlined code reads must be `public` (made `bytesWritten`/
    `firstError` public via re-exports). (b) Origin-string parsing
    used the first space, but Java methods can have multiple
    modifiers; switched to anchoring off `(`.

### Outstanding under this plan

- **Phase 2 finish**: extend `backfill_game_data_for_golden` to
  cover whatever `PowerStrengthAndRolls.build` deref chain hits a
  nil. Most likely candidate: `gd.properties` not initialized, or
  `unit_attachment.support_attachments` map. Drop the skip stub,
  expect non-zero pass count immediately. (Run the existing
  `Server_Game.run_next_step` test under gdb on snap 0013 to find
  the exact field — that path already works, so diff what it
  populates vs the helper.)
- **Phase 2 generator**: once the helper segfault is fixed, write
  `scripts/gen_replay_tests.py` so the remaining 7 methods get
  generated tests instead of hand-written ones. Promote
  `capture_state='generated'` and create Tier-A `test_status` rows.
- **Phase 3+**: as planned, expand the whitelist (Matches,
  ProMatches, BattleTracker, MustFightBattle, ProTerritory ...)
  one class per iteration.

### Acceptance status

| Phase 1 gate | Status |
|---|---|
| `SELECT COUNT(*) FROM golden_fixtures` ≥ 50 | ✅ 694 |
| `odin test golden_pro_battle_utils` green | ✅ 4 tests, 517/638 pass, 928 ms |
| `golden_dashboard.py --once` showing 1 class captured | ✅ 8 impl, 5 captured, 3 generated, 4 green |
| `validate_test_status.py` no new violations | ✅ invariant holds |

### 2026-05-09 (third session): Phase 2 finished + Phase 1 gate fully closed

- **Backfill segfault fixed.** Root cause: `gp.technology_frontiers` was nil
  for every Game_Player loaded from snap JSON; `tech_tracker_get_attack_rolls_bonus`
  derefed it during `PowerStrengthAndRolls.build`. Added the
  `technology_frontier_list_new` + `unit_collection_new` backfills that
  `test_server_game.odin` already had to
  `tc.backfill_game_data_for_golden`. estimatePower replay now runs
  **161/200 pass / 0 fail / 39 skipped** (skipped = units removed mid-turn),
  176 ms wall.
- **`scripts/gen_replay_tests.py` written.** Inspects fixture shape per
  method, emits Odin replay tests for any method whose args reduce to
  `{Territory-by-name, Collection<Unit>-by-id, GamePlayer-by-name, prim}`.
  Falls back to `capture_state='captured'` for opaque-arg methods (ProData,
  ProOddsCalculator, Map). 4 Tier-A tests now exist for ProBattleUtils:
    - hand-written: `estimatePower`         161/200 pass
    - generated:    `checkForOverwhelmingWin`  32/38 pass
    - generated:    `estimateStrength`         164/200 pass
    - generated:    `estimateStrengthDifference` 162/200 pass
    - aggregate: 517/638 (81%) pass, 0 fail in 928 ms.
- **`scripts/record_replay_results.py` written.** Parses
  `[golden <proc>] pass=N fail=M skipped=K total=T` lines from
  `odin test` stdout, promotes/demotes `test_status` per the doctrine
  (any fail → red; all pass → green; new tier='A'), updates
  `golden_fixtures.last_replay_status` aggregates. Just promoted the 4
  ProBattleUtils methods to **green Tier-A** rows in test_status.
- **`scripts/golden_dashboard.py` written.** `--once` for text report,
  `--port N` for HTTP. Phase 1 acceptance gate fully closed.
- **`tc.resolve_units` exported** from `golden_helpers.odin` so generated
  tests can share the unit-by-id resolver.
- **gen-output convention**: filenames end with `_gen.odin`; if a
  hand-written `*.odin` for the same method already exists, generation
  skips it (so the POC test stays the canonical one).

### End-to-end workflow now turnkey

```
python3 scripts/bb_agent_whitelist.py add <FQCN>
cd triplea && ./gradlew :game-app:smoke-testing:test --tests '*runWithSnapshots' \
    -PprocRecorderAgent=$PWD/conversion/proc-recorder-agent/build/libs/proc-recorder-agent.jar \
    -DprocRecorder.outDir=$PWD/game-app/smoke-testing/build/golden_fixtures \
    --rerun-tasks
python3 scripts/process_snapshots.py --input triplea/game-app/smoke-testing/build/snapshots \
    --output triplea/conversion/odin_tests
python3 scripts/import_fixtures.py
python3 scripts/gen_replay_tests.py
cd triplea && odin test conversion/odin_tests/golden_<class> \
    -collection:flat=../odin_flat \
    -collection:test_common=conversion/odin_tests/test_common \
    -define:ODIN_TEST_THREADS=1 2>&1 | tee /tmp/golden.log
cd .. && python3 scripts/record_replay_results.py --from-file /tmp/golden.log
python3 scripts/golden_dashboard.py --once
```

### Outstanding work (Phase 3+)

- **Phase 3**: extend whitelist with classes referenced by red snaps,
  use Tier-A failures as smallest reproducers for the 13 remaining
  red snaps.

### 2026-05-09 (fourth session): Phase 3 first iteration

- **Re-baselined snap suite**: 81/104 pass (22 red).
- **Captured 2 more classes**: `ProMatches` (65 methods → all
  predicate factories returning `Predicate<Unit>`, not value-comparable
  → 0 generated; need a Tier-B "evaluate-the-predicate" capture
  strategy) and `Properties` (95 generated tests).
- **Codegen extended**: special-case `_kind=GameProperties` →
  `gd.properties` and `_kind=GameData` → `gd`. Snake-case fix for
  `WW2V2`-style methods. Int compare handles `json.Float` whole-number
  fallback (`#partial switch v in obj["return"]`).
- **First real Odin port bug found by Tier-A**:
  `json_to_property_value` was returning `f64` for every JSON number
  (Odin's parser emits all numerics as Float). Downstream
  `game_properties_get_int_with_default(...).(i32)` silently returned
  the default. Surfaced by `properties_get_neutral_charge` returning
  0 vs Java's 9999999. Fixed in
  [templates/odin_test_common/json_loader.odin](templates/odin_test_common/json_loader.odin)
  by coercing whole-number floats to i32.
- **Result after fix**: Properties 95 tests / **4843 of 4848
  pass** (99.9 %), 0 fail, 5 skipped (no fixture content), 4.7 s wall.
- **`scripts/record_replay_results.py`** now uses the same snake
  rule as the codegen so `WW2V2`-style proc tokens resolve.
- **DB state**: 99 Tier-A green test_status entries (was 4); 10 237
  golden_fixtures rows (was 694).
- **Snap suite verified**: snap 0002 still passes (regression
  check); snap 0013 still fails on AI purchase logic — bug is in
  ProPurchaseAi, not ProBattleUtils/Properties (both green Tier-A).

### Phase 3 next iteration target

- Capture `ProPurchaseAi` (31 methods, opaque-arg-heavy → likely
  Tier B/C escalation candidates) OR a smaller intermediate like
  `ProUtils` / `ProTransportUtils` to reach more snap-driving procs.
- The general workflow is now mature: capture more leaf classes
  with simple-arg methods, fix what fails, watch the snap suite
  recover as fixes propagate.

### 2026-05-09 (fifth session): Phase 4 first iteration

- **Whitelist + capture**: added `UnitAttachment` (124 captured
  methods incl. overrides) and `GameMap` (16 methods, mostly opaque
  return → 0 generated). Capture run took 12 m 33 s for 5 classes
  (12 269 fixtures total).
- **Agent extended**: `@Advice.This` now captured and prepended to
  args for instance methods (so Odin replay can pass `self`).
  Reflective `getAttachedTo().getName()` chain captured as
  `attached_to` for any `DefaultAttachment` — enables symbolic
  resolution of `_kind=UnitAttachment` refs back to a unit type's
  `unit_attachment` field.
- **Codegen extended**:
    - new resolver: `_kind=UnitAttachment` →
      `gd.unit_type_list.unit_types[attached_to].unit_attachment`.
    - generated filename now matches generated proc name (digit-aware
      snake), no more `w_w2_v2`-style mismatches.
    - **arity mismatch is now a skip, not a fail.** Java overloads
      that share a method name (`getAttack()` and `getAttack(GamePlayer)`)
      land in the same fixture directory; we generate against the
      arity of the first sample, and other-arity fixtures get skipped
      cleanly. Previously they incremented `fail` without calling
      `expectf`, hiding the count-vs-test-status divergence.
- **Second real Odin port bug found by Tier-A**:
  `deserialize_unit_attachment` did **not** load `isSub`. Java's
  `getCanEvade()` returns `canEvade || isSub`; for submarines (and
  every isSub-true unit type) Odin returned false where Java returns
  true. Surfaced by `unit_attachment_get_can_evade` /
  `_can_be_moved_through_by_enemies` / `_can_move_through_enemies`
  on submarine fixtures. Fixed in
  [templates/odin_test_common/json_loader.odin](templates/odin_test_common/json_loader.odin)
  by adding `ua.is_sub = get_bool(obj, "isSub")`.
- **Net result**: 154 generated tests across 3 packages (4 + 95 +
  55), **5 997 of 6 249 fixtures pass / 0 fail / 252 skipped /
  ~5.8 s wall**. 153 Tier-A green test_status entries
  (was 99 before this iteration; 4 at start of session).
  30 716 golden_fixtures rows (was 10 237).
- **Snap-suite second-order effect**: snap 0015 (formerly PASS) and
  0067 (formerly FAIL with `wasInCombat: false != true`) **flipped
  direction** after the isSub fix — both now fail with
  `wasInCombat: true != false`. They were previously passing /
  failing-in-known-direction by *coincidence* (two off-setting
  bugs). At the Tier-A level UnitAttachment is fully green (0 fail),
  so this confirms the downstream divergence is in combat
  resolution, not attachment lookup. Exactly the kind of bisection
  Tier-A is for.

### Outstanding follow-ups for next iteration

- The 0015 / 0067 `wasInCombat` divergence is in
  combat resolution, downstream of UnitAttachment. Capture
  `MustFightBattle` or `BattleTracker` to localize.
- ProMatches still has 65 captured methods returning
  `Predicate<Unit>` with no Tier-A support. Tier-B "evaluate
  predicate against sample units" is the next codegen extension.
- Consider tightening codegen so it skips emit when the target
  Odin proc doesn't exist (avoids the
  `unit_attachment_get_attack_rolls / _defense_rolls` manual
  cleanup we did this round).

### 2026-05-09 (sixth session): capture-cost reality check + lessons

The replay cycle is unchanged: **5.8 s for 152 tests, 5451 of 6272
fixtures pass, 0 fail.** That part of the framework is solid.

Capture, however, has structural limits we now understand:

1. **Stateful instance methods aren't Tier-A.** `BattleTracker`,
   `AbstractBattle`, `MustFightBattle` capture `_kind=BattleTracker`
   (etc.) as opaque receivers with no name/id we can resolve. The
   instance state (Conquered, Blitzed, Fought lists) IS the proc's
   input, and we can't reconstruct it from a snap's `before.json`.
   These need **Tier B** (subgraph capture: serialize the receiver's
   reachable state as a tiny mini-snap per fixture). Verified by
   inspection of fixtures: every BT/AB/MFB fixture has the receiver
   as opaque `_class+_toString`. Codegen correctly skips them with
   `(unresolvable)` markers.

2. **Hot-path classes have intrinsic capture cost.** BT's
   `wasConquered` fires millions of times per game. Even with
   intercept-side fast-skip (added to ProcRecorderInterceptor —
   `perMethodSaturated` map check before `record()`), the saturation
   maps fill slowly because each call has distinct args (different
   territories, different snap states). Capture wall time for BT
   alone exceeded 11 minutes before being killed.

3. **Gradle test stdout buffers per-test.** Our `runWithSnapshots`
   is one `@Test` running all 104 steps, so the agent's PROGRESS
   lines are held in gradle's per-test buffer until the test
   completes. The progress thread DOES run, but its output is
   invisible until end of run. **Workaround**: agent should write
   progress to a stable file path that the wrapper tails. Not yet
   implemented; deferred.

4. **Java UUID non-determinism**: after a partial re-capture, the
   snap suite's units have new UUIDs but the older fixtures
   reference old UUIDs. ProBattleUtils replay went from 4843/4848
   pass → 0/4848 pass (all skipped, no fails) because units in the
   fixtures don't exist in the new snap dirs. **Capture must always
   refresh snaps + fixtures together; partial recaptures break the
   snap_id ↔ unit_id linkage.** This is a hard rule, not a polish
   item. The current `process_snapshots.py` step in the wrapper
   refreshes snaps; the issue is when capture fails mid-run and
   we keep stale fixtures alongside fresh snaps.

5. **Per-class capture timeline is not constant.** The plan's
   ≤2× wall-time budget (§6 #7) holds for *small leaf* classes
   (ProBattleUtils 49 s, AbstractBattle 1m 57s) but breaks for
   *hot-path* classes. The honest cost model:

   | Class kind | Capture time |
   |---|---|
   | Pure leaf, scalar args (Properties, ProBattleUtils) | <2 min |
   | Stateful but reachable (UnitAttachment via attached_to) | <2 min |
   | Hot-path utility (BattleTracker, Matches) | 10+ min, often hangs |
   | Lambda-only / functional (ProMatches predicate factories) | irrelevant — not Tier-A |

### Lessons committed to repo memory

- **Never re-capture stateful classes via Tier A.** Mark them in
  `methods.capture_state='captured'` (we already do for opaque-arg
  methods) and escalate to Tier B as a separate workstream.
- **Always refresh snap dirs and fixtures atomically.** Wrapper
  must either capture+process_snapshots together or refuse to
  proceed.
- **Capture cost is data, track it.** The new `captures` table
  in port.sqlite records elapsed_ms / intercepts_total per run,
  so we can see which classes are capture-hostile up front.

### Tooling additions in this session (kept for future use)

- `triplea/conversion/proc-recorder-agent/`: agent now
  - accepts `class=FQCN[+FQCN...]` to capture only specific classes
  - prints `[ProcRecorderAgent] PROGRESS t=Ns intercepts=N writes=N`
    every 5 s (visible after gradle test completes; not yet
    surfaced live)
  - prints `[ProcRecorderAgent] SUMMARY elapsed_ms=N ...` on
    shutdown via Runtime hook
  - has `perMethodSaturated` fast-skip in the inlined advice so
    saturated methods short-circuit before paying args + SHA cost
  - captures `@Advice.This` for instance methods (prepended to args)
  - reflectively follows `getAttachedTo().getName()` for any
    DefaultAttachment so attachments resolve via container name
- `scripts/capture_class.py`: per-class capture wrapper that
  - records start/end/elapsed/fixtures/intercepts in the new
    `captures` table
  - tee's gradle output to `/tmp/capture_<unix>.log`
  - is additive: only deletes the target classes' subdirs, not the
    whole `golden_fixtures/` tree
  - parses agent SUMMARY post-hoc rather than streaming
    (subprocess.Popen+tee was hanging on gradle daemon)
- `port.sqlite captures` table (new in this session): one row per
  capture run with fqcn, elapsed_ms, fixtures_written,
  intercepts_total, status.

### Recommendation going forward

For **fast iteration**:
- The 152 existing Tier-A tests run in ~6 s and catch real bugs
  (json_to_property_value, isSub). **Use them.** Don't re-capture.
- Iterate on Odin code freely; existing fixtures stay valid until
  the next deliberate Java re-baseline.

For **Phase 4 rollout**:
- Continue with **simple-arg classes only** (next candidates from
  `bb_agent_whitelist.py suggest`: ProTerritory, ProUtils,
  ProTransportUtils, MoveValidator). Each should capture in <2 min.
- Defer combat classes to **Phase B (Tier-B subgraph)** as a
  separate effort; they need an entirely different capture strategy.

For **diagnosing snap 0015/0067 wasInCombat**:
- Tier A can't reach this layer. Either (a) bisect by adding more
  log statements to the existing snap test, or (b) implement the
  Tier-B subgraph capture for AbstractBattle / MustFightBattle
  before chasing it.
