# Golden-testing resume prompt — TripleA Java→Odin port (Phase C)

> **The single thing to paste.** Open a fresh chat and paste the
> "PROMPT" block below. It is idempotent: it always reads the status
> file, queries `port.sqlite` for the next leaf, runs one drill-down
> step, updates the status file, and stops or loops.
>
> **Companion files (do not paste — the prompt reads them):**
> - [`golden-testing-status.md`](./golden-testing-status.md) — living
>   work tracker; updated every iteration.
> - [`golden_testing_plan.md`](./golden_testing_plan.md) — design,
>   tiers, schema additions.
> - [`how-to-take-snapshots-that-include-args-and-return-values.md`](./how-to-take-snapshots-that-include-args-and-return-values.md)
>   — Byte Buddy + replay mechanics.
> - [`llm-instructions.md`](./llm-instructions.md) — drill-down rules,
>   green/yellow/red doctrine, mandatory trace table.

---

## PROMPT (copy from here to end of file)

You are the **golden-testing orchestrator** for Phase C of the
TripleA Java→Odin port. Workspace root: `/home/caleb/todin`.
Tracker: `port.sqlite`. Living status: `golden-testing-status.md`.

### Boot sequence (always run, in order, every fresh session)

1. **Read `golden-testing-status.md` end-to-end.** It tells you the
   current red snap, the current trace-table position, the last
   green/red classification, and the next action. If it does not
   exist, STOP and tell the user to run this prompt's setup once.

2. **Read the rule files once.** Re-load if unsure:
   - `llm-instructions.md` §"Layered drill-down debugging" — the
     mandatory trace-table format and the three states
     (green/red/yellow) with their proof requirements.
   - `golden_testing_plan.md` §3 + §4 — what tables/scripts exist
     and the per-class capture/replay workflow.
   - `how-to-take-snapshots-that-include-args-and-return-values.md`
     — `scripts/capture_proc_snapshot.py` invocation, the Jackson
     shape, the Odin marshaller/comparator location.

3. **Re-print the current trace table** from
   `golden-testing-status.md` so the user sees the descent path
   before any tool call.

### Iteration loop (one pass = one drill-down step)

Repeat until the user stops you OR all snaps are green OR you hit a
blocker that requires user input. Each pass MUST end with a status
file update (step 8) so the next session can resume.

1. **Pick the current bottom row of the trace table** — that is the
   proc under analysis. If the table is empty, pick the deepest red
   snap from the status file's "Failing snaps" section and seed the
   table with its top-level failing proc (look up its `method_layer`
   in `port.sqlite`).

2. **List its dependencies, sorted by descending `method_layer`:**
   ```sql
   SELECT d.depends_on_key,
          m.method_layer,
          m.is_abstract,
          COALESCE(ts.status, 'yellow') AS status
   FROM dependencies d
   JOIN methods m ON m.method_key = d.depends_on_key
   LEFT JOIN test_status ts ON ts.entity_key = d.depends_on_key
   WHERE d.method_key = '<current_bottom_row>'
   ORDER BY m.method_layer DESC;
   ```
   Skip rows where `is_abstract = 1` — those are routing nodes;
   descend into the `override` edge to the concrete impl instead.

3. **Decide the next move** using these rules in order:
   - If ANY child is `red`: that child is the new bottom row. Append
     it to the trace table. Go to step 8.
   - If ANY child is `yellow`: pick the one with the highest
     `method_layer` (closest to the parent). Classify it via Tier A
     (step 4). Go to step 8.
   - If ALL children are `green`: the bug is in the current proc's
     own body. Go to step 5.

4. **Tier A classification of a yellow child** (no guessing allowed):
   - Check `golden_fixtures` for existing fixtures for this proc.
     If none, capture them:
     ```sh
     python3 scripts/capture_proc_snapshot.py \
       --class <FQCN> --method <NAME> \
       --max-snapshots 200
     python3 scripts/import_fixtures.py
     ```
   - Generate (or regenerate) the replay test:
     ```sh
     python3 scripts/gen_replay_tests.py --class <FQCN>
     ```
   - Run it:
     ```sh
     cd triplea && odin test conversion/odin_tests/golden_<snake_class> \
       -collection:flat=../odin_flat \
       -collection:test_common=conversion/odin_tests/test_common
     ```
   - Run `scripts/record_replay_results.py` to update
     `golden_fixtures.last_replay_status` and promote/demote the
     `test_status` row.
   - Outcome:
     - All fixtures pass + no red descendants → mark child **green**
       in `test_status` with `test_tier='A'`, pop nothing yet; loop
       to step 1 to pick the next yellow sibling or descend.
     - Any fixture fails → mark child **red**; append to trace
       table; go to step 8.
     - Cannot build a real Java-derived golden (e.g. heavy I/O,
       reflection) → leave child **yellow** with a `note`
       explaining why; skip it; pick the next sibling.

   **Forbidden as proof of green:** crash-only asserts, `expect(x !=
   nil)`, `expect(len(out) > 0)`, trivial early-return paths. Per
   `llm-instructions.md`.

5. **Fix the current proc** (all children green, bug is here):
   - `find triplea/game-app -path "*/main/java/*<ClassName>.java"`
   - Read the Java method top-to-bottom. Diff against the Odin port
     line-by-line. Fix the divergence — do NOT invent logic
     (`/memories/java-fidelity-rule.md`).
   - Re-run the proc's Tier A fixtures. If green, mark **green**.
     If still red, the trace was wrong — re-examine and append the
     real divergent callee.

6. **Walk back up.** If the current row turned green, pop it. Re-run
   the parent's Tier A test (or the parent snap if the parent is
   the snap-level row). If parent is now green, pop again. Continue
   until the table has one row OR a parent is still red.

7. **If the trace table is empty AND the snap passes:** mark the
   snap done in the status file. Pick the next failing snap; seed a
   new trace table. If no snaps fail, all done.

8. **Update `golden-testing-status.md`** before returning to the
   user. Replace these sections:
   - "Trace table" — the current stack
   - "Last action" — one sentence (e.g. `Classified
     ProBattleUtils#estimatePower green via 42 fixtures, popping`)
   - "Next action" — what step 1 of the next iteration will do
   - "Snap status" — `0013 RED ... 0023 RED ...`
   - "Notes" — append any blocker the user needs to resolve

### Stop conditions

- All snaps green → tell the user, suggest tier-D reduction per
  `golden_testing_plan.md` §"Phase 5".
- Blocked on capture infrastructure (e.g. Byte Buddy agent missing,
  `scripts/*` not yet written per `golden_testing_plan.md` §3.2) →
  STOP, record the missing piece in status "Notes", ask the user
  to build it or grant permission for the orchestrator to build it.
- Context window feels tight (~70%+) → run step 8, then stop and
  tell the user to paste this prompt into a fresh chat.

### Setup (one-time)

If `golden-testing-status.md` does not exist, the user should run
this once: ask them to confirm, then create it from the template
at the end of that file (the file ships with the template inline).

### Hard rules (recap from `llm-instructions.md`)

- Never edit a snapshot. Snapshots are Java-derived ground truth.
- Never write Odin logic from scratch — every fix is a port from
  the original `.java`.
- Never mark green on "didn't crash."
- Never descend into a row with `is_abstract = 1` — use its
  `override` edge.
- Every appended trace row MUST have strictly lower `method_layer`
  than the row above. If not, you descended wrong.
- Always update `golden-testing-status.md` before stopping.
