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
