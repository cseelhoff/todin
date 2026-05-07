# Resume prompt — TripleA Java→Odin port

> **Copy the entire "PROMPT" block below and paste it into a fresh chat
> any time the context window fills up. It is idempotent: it always
> queries `port.sqlite` for the next unfinished work and dispatches a
> batch of subagents (one subagent per Odin file). Re-run until both
> `structs` and `methods` are 100% `is_implemented = 1`.**

> **Granularity:** Phase A still uses one subagent per struct (one row
> per file). Phase B groups by `odin_file_path` — a single subagent is
> assigned **every** unimplemented method belonging to the same Odin
> file, ported in one shot, and the orchestrator marks all of those
> `method_key`s `is_implemented = 1` together on success.

---

## PROMPT (copy from here to end of file)

You are the **orchestrator** for the TripleA Java→Odin port. The
authoritative tracker is `port.sqlite` at the workspace root
(`/home/caleb/todin`). The full rules live in
[`llm-instructions.md`](./llm-instructions.md) — read that file once
at the start of the session, then proceed.

### Your loop (run until done, then call `task_complete`)

1. **Sanity check** the workspace and load progress notes:
   - View `/memories/session/triplea-port-progress.md` (create it if
     missing — see template at the bottom of this file).
   - **If Phase A is done (`s_done == s_total`), run the missing-proc
     scanner FIRST** (see "Missing-proc augmentation" section below
     for full rationale):
     ```sh
     python3 scripts/scan_missing_procs.py --commit
     ```
     This parses `odin check` `Undeclared name:` diagnostics and
     INSERTs any genuinely-missing methods into `port.sqlite` so the
     Phase B query below picks them up. Read
     `missing_procs_report.json` afterward and triage:
     `unresolved_constants` (add as Odin top-level `const :: "..."`
     decls, NOT methods table rows), `unresolved_lambdas` (no-op
     stubs in the calling file), `unresolved_unknown_owner` /
     `unresolved_no_java_match` (real Odin call-site bugs — fix the
     caller). Skip this step while Phase A is still running.
   - Run:
     ```sh
     sqlite3 port.sqlite "SELECT \
       (SELECT COUNT(*) FROM structs) AS s_total, \
       (SELECT COUNT(*) FROM structs WHERE is_implemented=1) AS s_done, \
       (SELECT COUNT(*) FROM methods) AS m_total, \
       (SELECT COUNT(*) FROM methods WHERE is_implemented=1) AS m_done;"
     ```
   - Print one line: `phase A: s_done/s_total, phase B: m_done/m_total`.

2. **Pick the active phase**:
   - If `s_done < s_total` → **Phase A** (structs).
   - Else if `m_done < m_total` → **Phase B** (methods).
   - Else if there are unresolved `vtable_wiring` rows → **Phase B-2**
     (constructor proc-field wiring) — see below.
   - Else → **Phase C** (snapshot validation): compile + run the
     snapshot tests per `llm-instructions.md` §Phase C, then
     `task_complete`.

   **Phase B-2 detection.** Once `m_done == m_total`, run:
   ```sh
   python3 scripts/scan_vtable_wiring.py --commit
   sqlite3 port.sqlite "SELECT status, known_broken, COUNT(*) \
     FROM vtable_wiring GROUP BY status, known_broken;"
   ```
   If any row has `status != 'ok' AND known_broken = 0` (the
   scanner prints this as `effective_missing=N`), advance to
   Phase B-2; otherwise Phase B is fully done. Re-run the scanner
   after every Phase B-2 batch to refresh statuses.

3. **Pull the next batch from the DB.**

   Phase A query — one row = one struct = one subagent (12 per batch):
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT struct_key, java_file_path, odin_file_path, struct_layer
     FROM structs WHERE is_implemented = 0
     ORDER BY struct_layer, scc_id, struct_key
     LIMIT 12;"
   ```

   **Phase B query — single combined query, file-grouped at the
   current layer.** The current layer `L` is the minimum
   `method_layer` that still has at least one unimplemented method.
   The query below computes `L` in a CTE, picks up to 8 distinct
   `odin_file_path`s that have any unimplemented method at layer
   `L`, and returns every unimplemented layer-`L` method whose
   `odin_file_path` is in that batch — all in one round-trip.

   Methods at higher layers in the same file are NOT included; they
   wait for their own layer's pass. This is by design (cross-layer
   dependency safety) and avoids the back-and-forth of computing
   `L` in a separate step.

   ```sh
   sqlite3 -separator '|' port.sqlite "
     WITH cur_layer AS (
       SELECT MIN(method_layer) AS L
       FROM methods WHERE is_implemented = 0
     ),
     batch_files AS (
       SELECT DISTINCT m.odin_file_path
       FROM methods m, cur_layer
       WHERE m.is_implemented = 0
         AND m.method_layer = cur_layer.L
       ORDER BY m.odin_file_path
       LIMIT 8
     )
     SELECT cur_layer.L AS layer,
            m.odin_file_path,
            m.method_key,
            m.owner_struct_key,
            m.java_file_path
     FROM methods m, cur_layer
     WHERE m.is_implemented = 0
       AND m.method_layer = cur_layer.L
       AND m.odin_file_path IN (SELECT odin_file_path FROM batch_files)
     ORDER BY m.odin_file_path, m.method_key;"
   ```

   - If the result set is empty, Phase B is complete — run the
     missing-proc scanner one more time, then advance to **Phase
     B-2** (vtable wiring) per `phase-b.md` §"Phase B-2: Vtable
     wiring pass". Phase B-2 closes the gap between method bodies
     (which Phase B ports) and the constructor-side proc-field
     assignments needed for Java polymorphism to actually dispatch
     at runtime. Without B-2, `^I_Delegate.start(d)` and similar
     polymorphic calls silently no-op and the snapshot harness will
     plateau in Phase C.
   - Otherwise the first column of every row is the layer `L` (the
     same value on every row, by construction). Read it from the
     first row and record it in session memory under
     `Current method_layer:` so progress notes stay accurate.
   - The orchestrator groups the rows by `odin_file_path`
     client-side: each unique file becomes ONE subagent dispatch
     carrying the full list of layer-`L` `method_key`s for that
     file.

4. **Dispatch one subagent per group, in parallel**, using `runSubagent`
   with `agentName` omitted (the default coding subagent — `Explore`
   cannot write files). Use the prompt templates in the next section.
   All calls in the batch go in a single tool-call block.

   - Phase A: one subagent per struct row (≤12 per batch).
   - Phase B: one subagent per `odin_file_path` (≤8 per batch),
     handling every unimplemented method in that file at the
     current `method_layer`.

5. **Collect results.**
   - Phase A subagents return one line:
     `done: <referenced types>` or `blocked: <reason>`.
   - Phase B subagents return one line:
     `done: <space-separated method_keys that succeeded> | <comma-separated procs/types referenced>`,
     or
     `partial: <done method_keys> | blocked: <method_key> <reason>`,
     or
     `blocked: <reason>` (whole-file blocker, e.g. file header
     conflict; nothing in the file got ported).

6. **Update the database.**
   - Phase A: for every `done:` row, run a single
     `UPDATE structs SET is_implemented=1 WHERE struct_key IN (...)`.
   - Phase B: collect all `method_key`s reported as done across
     every subagent in the batch (including the done portion of any
     `partial:` reply) and run a single
     `UPDATE methods SET is_implemented=1 WHERE method_key IN (...)`.
   - Remember to backslash-escape `$` in inner-class keys
     (e.g. `'struct:foo.Bar\$Baz'`, `'proc:foo.Bar\$Baz#thing()'`).
   - For `blocked:` rows / blocked method_keys inside a `partial:`
     reply, do NOT mark them implemented — proceed to step 6a.

6a. **Triage every `blocked:` row before the next batch.** Do not
    silently re-queue blocked entries; they will likely block again.
    For each `blocked:` row:

    1. **Analyze the root cause** from the subagent's reason. Cross-
       check by reading the Java source, the target Odin file, and
       any referenced Odin files in `odin_flat/` (use `grep_search` /
       `read_file`). Typical root causes:
       - A **JDK boundary type** is referenced (e.g.
         `java.util.concurrent.CountDownLatch`, `java.lang.Thread`,
         `java.util.concurrent.ExecutorService`,
         `java.util.concurrent.ScheduledFuture`, `java.net.URI`,
         `java.time.Instant`, …). The bootstrap intentionally
         excludes JDK classes from `port.sqlite`, so they will
         never appear as struct rows — but Java fields legitimately
         hold them. **Resolve by provisioning a JDK shim file in
         `odin_flat/`.** See "JDK shim policy" below.
       - A referenced type/proc is genuinely absent from `odin_flat/`
         (provisioning gap — most often an inner class without its
         own file).
       - **Cross-layer dependency** — most often in Phase B, where
         a layer-N method calls a helper that lives at layer M > N.
         The bootstrap layering should normally prevent this, but
         Lombok-generated helpers, varargs forwarders, and a few
         genuine SCC edges occasionally end up at a higher layer
         than their callers. This is a **benign skip**: see step
         6a.2 below — leave the method unimplemented and continue.
       - Name collision between a map-data XML element class and an
         engine class of the same simple name.
       - Odin file already contains content that conflicts with the
         expected `package game` header.
       - Subagent misread the rules (e.g. tried to define an inner
         class inline).

    2. **Decide: skip, trivial auto-fix, or stop.**
       - **Benign skip — cross-layer dependency.** If the blocker
         is "depends on `<other_method_key>` at method_layer M
         (not yet ported)" and that other method genuinely lives
         at a higher layer in `port.sqlite`, **do nothing**: leave
         the blocked `method_key` marked `is_implemented = 0` and
         move on with the rest of the batch. The higher layer's
         own pass will pick it up. Record the skip in session
         memory under "Skipped (cross-layer dependency)" so the
         pattern is visible across runs, but **do not stop the
         loop and do not auto-fix**. Treat partial-batch successes
         the same way: mark the done method_keys, leave the
         blocked one as `is_implemented = 0`, and continue.
       - **Trivial & obvious** → fix it inline and re-dispatch ONE
         subagent for that single entity in the next batch. Examples
         of trivial fixes the orchestrator MAY perform directly:
         - **Provisioning a JDK shim file** for a missing JDK
           boundary type (per "JDK shim policy" below). Once the
           shim exists in `odin_flat/`, every future reference to
           that JDK type resolves automatically — the orchestrator
           does the work once and the whole codebase benefits.
         - Creating an empty provisioned `.odin` file with `package
           game` for a missing inner-class file that the DB already
           expects (verify against the `structs` table first).
         - Renaming the target Odin type to disambiguate a name
           collision when the harness does NOT require the colliding
           name (e.g. map-data `Resource_List` → `Map_Data_Resource_
           List`); update the subagent prompt accordingly on retry.
         - Removing leftover scaffolding/TODO content in the target
           file when it prevents the subagent from writing a clean
           `package game` header.
         - Re-dispatching with a clearer hint when the subagent's
           confusion is purely about rules interpretation.
- **Anything else** → fix it directly and continue. The
         orchestrator has full authority to:
         - Port missing Java methods/structs to Odin directly
           (read the Java source, write the Odin proc/struct).
           This is the same work a subagent would do; doing it
           inline avoids dispatch overhead when the fix is
           localized.
         - Correct caller/callee signature mismatches by editing
           either side to match the Java source of truth.
         - Edit the snapshot harness under
           `triplea/conversion/odin_tests/test_common/` and the
           generated `test_*.odin` files when the harness's
           expected types don't match the ported Odin shapes.
           Mirror the change into
           `templates/odin_test_common/` and
           `scripts/patch_triplea.py` afterward so the next
           bootstrap re-run preserves the fix.
         - Update `port.sqlite` directly to reconcile drift
           (e.g. flip `is_implemented = 0` on rows whose target
           proc is actually missing from `odin_flat/`, add
           missing rows that the bootstrap closure missed,
           re-run `scripts/build_called_layered_tables.py` if a
           full re-layer is needed).
         - Apply any other fix necessary to make Phase C compile
           and pass.
         Record the action in session memory under "Direct fixes
         applied this session" so future runs see what's already
         on disk.

    3. **Never** mark a blocked entity `is_implemented = 1`, and
       never bypass the rule against editing the harness. A
       blocked method that is left `is_implemented = 0` is fine
       — it will be revisited automatically on a later batch (its
       own layer's pass, or after the dependency is filled in).

7. **Update session memory** (`/memories/session/triplea-port-progress.md`)
   with the new counters and any blockers (including auto-fixes
   applied this iteration, so future runs can see what the
   orchestrator changed on its own).

8. **Loop back to step 1** until the phase changes, a non-trivial
   blocker forces a stop, or the context feels tight (~70%+ used).
   When stopping mid-port:
   - Save final counters into session memory.
   - Print: `Stopping at <s_done>/<s_total> structs, <m_done>/<m_total>
     methods. Re-run resume-prompt.md to continue.`
   - Call `task_complete`.

### Missing-proc augmentation (orchestrator-owned, run at the top of every loop iteration once Phase A is done)

The bootstrap pipeline (extract_entities + JaCoCo + static call graph)
systematically under-reports procs in four cases:

  1. javac-synthetic lambdas / anonymous inner classes
  2. Reflective factories (`Class.forName(...).getDeclaredConstructor()`)
  3. JIT-inlined or short-circuit-skipped lines that JaCoCo records
     as "uncovered" even though a covered caller depends on them
  4. Lombok `@Getter`/`@Setter`/`@Builder` synthesized accessors
     whose source-line range no AST extractor traverses

The compiler is the source of truth: every `Undeclared name: X` that
`odin check odin_flat/` emits is a row missing from `methods`.
**Run `scripts/scan_missing_procs.py --commit` at the top of every
orchestrator iteration once Phase A is complete** (and any time a
Phase B subagent reports `blocked: missing <proc>` whose proc is on
the AI path). The script:

  - parses `odin check` output for `Undeclared name`
  - greedy-prefix-matches each undeclared name against the snake_case
    of every `structs.struct_key` to identify the owner class
  - resolves the Java method via direct match → Lombok synthesis →
    walk-extends/implements chain
  - INSERTs each match as a new `methods` row (`is_implemented = 0`,
    `method_layer = MAX(method_layer)+1`) so it gets queued at the
    end of the next Phase B batch
  - emits `missing_procs_report.json` listing:
      * `inserted` (queued for Phase B),
      * `unresolved_constants` (uppercase identifiers — handle as
        `package game` const decls or as struct fields, not methods),
      * `unresolved_lambdas` (synthetic — orchestrator stubs no-ops),
      * `unresolved_unknown_owner` (snake-prefix didn't match —
        usually a real Odin call-site bug, not a missing port),
      * `unresolved_no_java_match` (owner found but no Java method —
        often the porting agent invented a non-existent method, or
        Lombok synthesis the script can't yet model)

After the script commits, re-read `m_done`/`m_total` for the new totals
and resume the regular Phase B loop. Triage `unresolved_no_java_match`
and `unresolved_unknown_owner` cases as Odin call-site bugs (edit the
caller to use a real method, or add a trivial coercion proc).

### JDK shim policy (orchestrator-owned)

The Java code legitimately references JDK types that the bootstrap
does NOT add to `port.sqlite` (only TripleA classes are tracked).
When a subagent reports `blocked: missing JDK <fq.name>` (or any
blocked-for-missing-type whose root cause is a JDK class), the
orchestrator MUST provision a shim file in `odin_flat/` and then
re-dispatch the subagent. Do NOT leave dangling references like
`^Count_Down_Latch` in any file: every type used in `odin_flat/`
must be defined somewhere in `odin_flat/`.

**Shim location and naming.**

- File path: `odin_flat/<dotted-package-as-double-underscores>__
  <snake_case_simple_name>.odin`. Examples:
  - `java.util.concurrent.CountDownLatch` →
    `odin_flat/java__util__concurrent__count_down_latch.odin`
  - `java.lang.Thread` → `odin_flat/java__lang__thread.odin`
  - `java.util.concurrent.ExecutorService` →
    `odin_flat/java__util__concurrent__executor_service.odin`
- Type name: PascalCase_with_underscores of the simple name
  (`Count_Down_Latch`, `Thread`, `Executor_Service`, …). Just like
  TripleA structs, JDK shim type names MUST be derived from the
  simple class name only — never prefixed with the package path.
- File header: `package game` (all of `odin_flat/` is one package).
- Before writing, `grep -l "<Type_Name> ::"
  /home/caleb/todin/odin_flat/` to confirm no shim already exists.
  If one exists, just re-dispatch — the subagent's earlier
  `blocked` was a false negative.

**Shim content.**

Write a real, minimal Odin implementation — not an empty stub —
so every TripleA struct/method that references the JDK type gets
consistent, working semantics. The shim is the single source of
truth across the whole port. Guidelines per category:

- **Concurrency primitives** (`CountDownLatch`, `Semaphore`,
  `ReentrantLock`, …): emit a struct with the state fields the
  Java class actually uses (e.g. `Count_Down_Latch :: struct {
  count: i32 }`) plus the small set of procs the TripleA code
  actually calls (`count_down_latch_new`, `count_down_latch_count_
  down`, `count_down_latch_await`, `count_down_latch_get_count`).
  These are single-process AI-snapshot runs, not real multi-
  threading — implement the semantics needed to satisfy the
  callers, not full JVM thread safety.
- **Threading / executors** (`Thread`, `ExecutorService`,
  `ScheduledExecutorService`, `ScheduledFuture`,
  `CompletableFuture`): the snapshot harness pins
  `PlainRandomSource.fixedSeed = 42L` and runs single-threaded.
  Implement these as direct/synchronous: `Executor_Service ::
  struct {}` with `executor_service_submit :: proc(self:
  ^Executor_Service, task: proc()) { task() }`, etc. Document
  this with a single one-line comment at the top of the shim
  (e.g. `// JDK shim: synchronous in-process implementation;
  the AI snapshot harness is single-threaded.`).
- **Value types** (`java.time.Instant`, `java.net.URI`,
  `java.util.UUID`, `java.math.BigDecimal`, `java.awt.Point`,
  `java.awt.Color`): port to a struct of plain primitive fields
  (`Instant :: struct { seconds: i64, nanos: i32 }`,
  `Uri :: struct { value: string }`, …). Note `BigDecimal` is
  already mapped to `f64` per `llm-instructions.md` and does not
  need a shim.
- **Collections beyond what `llm-instructions.md` covers**
  (`Optional<T>`, `Queue<T>`, `Deque<T>`, `Iterator<T>`): emit a
  small generic-ish wrapper using existing Odin primitives
  (`Optional :: struct($T: typeid) { has: bool, value: T }`,
  `Iterator :: struct { ... }`). Only add the procs the callers
  actually use.
- **I/O, networking, GUI** (`java.io.*`, `java.net.Socket`,
  `javax.swing.*`, `java.awt.*` beyond `Point`/`Color`): these
  should NOT appear under `actually_called_in_ai_test = 1` in the
  general case — they're typically a JaCoCo filter regression.
  However, **NIO socket plumbing is a known exception**: the AI
  snapshot harness wires up a Messengers / Test_Server_Game
  object whose constructor instantiates `NioReader` /
  `NioWriter` for compile-/setup-time reasons, but no real
  socket I/O happens during the snapshot run. For these JDK
  NIO/concurrency-queue types, provision **opaque marker
  shims** (no real semantics) so referencing structs compile:
  - `java.nio.channels.SocketChannel` → `Socket_Channel :: struct {}`
  - `java.nio.channels.Selector` → `Selector :: struct {}`
  - `java.nio.channels.SelectionKey` → `Selection_Key :: struct {}`
  - `java.nio.ByteBuffer` → `Byte_Buffer :: struct { data: [dynamic]u8, position: i32, limit: i32, capacity: i32 }`
  - `java.util.concurrent.BlockingQueue` →
    `Blocking_Queue :: struct { items: [dynamic]rawptr }`
    plus `blocking_queue_take`, `blocking_queue_offer`,
    `blocking_queue_poll` procs that do single-threaded
    in-order push/pop on `items`.
  All other I/O (Swing, AWT widgets, real `Socket`,
  `FileInputStream`, ...) still triggers a STOP — those should
  not appear in the structs table at all.

**Workflow (orchestrator):**

1. Identify the JDK type from the subagent's `blocked` reason
   (or by reading the Java source if the message is vague).
2. Compute the shim path and type name per the rules above.
3. `grep` to confirm no shim exists; create the file with
   `package game` + the struct + the small set of procs needed.
   (You may write this code yourself — JDK shims are
   orchestrator-owned infrastructure, not TripleA entity ports,
   so the "never write Odin yourself" rule does NOT apply here.)
4. Record the shim in session memory under a "JDK shims
provisioned this session" section so future runs see what's
   already on disk.
5. Re-dispatch ONE subagent for the originally blocked entity
   in the next batch, with a hint: `JDK shim for <fq.name> has
   been provisioned at <path> as Odin type <Type_Name>; use it.`
6. Do NOT add the JDK shim to `port.sqlite`. The DB tracks only
   TripleA classes; JDK shims are provisioning, not work items.

If the requested JDK type does not fit any category above (rare,
e.g. a reflective or dynamic-proxy type), STOP per step 6a and
document it for manual review.

### Subagent dispatch templates

Every subagent prompt MUST tell the subagent:

- It is doing a single **unit of work**: in Phase A that's one
  struct (one Odin file); in Phase B that's **one Odin file's worth
  of methods** — every unimplemented `method_key` whose
  `odin_file_path` matches the assigned file, at the current
  `method_layer`. The orchestrator owns the DB; the subagent must
  NOT update `port.sqlite`.
- All previously-needed Odin dependencies are **already implemented**
  in `odin_flat/` (Phase A finishes before Phase B; methods are
  ordered by `method_layer`). The subagent should **reference
  existing types/procs**, not re-define them. If the subagent thinks
  a referenced type is missing, it should:
  1. Check `grep -l "<Type_Name> ::" /home/caleb/todin/odin_flat/`.
  2. If found, use it.
  3. Only if genuinely absent, return `blocked: missing <Type_Name>`.
  This protects against re-implementation drift.
- Forward references to types defined later in `odin_flat/` are fine
  — Odin resolves them at the package level.
- Read `/home/caleb/todin/llm-instructions.md` at the start of the
  subagent's work for the rules summary.
- Return exactly one line. Phase A: `done: <types>` /
  `blocked: <reason>`. Phase B: see the per-method status format
  in the Phase B template (`done:` / `partial:` / `blocked:`).

#### Phase A subagent prompt template (struct)

```
Port one Java struct/interface/enum to Odin per
/home/caleb/todin/llm-instructions.md (read it first; obey all rules).

Entity: <STRUCT_KEY>
Java source: <JAVA_FILE_PATH>
Odin target: <ODIN_FILE_PATH>

Phase A: TYPE only — fields + nested types. NO method bodies.

Rules:
- Replace the existing TODO header with `package game`.
- Type name: PascalCase_with_underscores derived from the file name,
  EXCEPT for the disambiguation table below — three Java classes
  share a simple name with a harness-authoritative engine type and
  must use a prefixed Odin name to avoid duplicate-symbol errors:

  | struct_key                                                                                   | Odin type name                  |
  |----------------------------------------------------------------------------------------------|---------------------------------|
  | struct:org.triplea.map.data.elements.PlayerList                                              | `Xml_Player_List`               |
  | struct:org.triplea.map.data.elements.PlayerList$Player                                       | `Xml_Player_List_Player`        |
  | struct:org.triplea.map.data.elements.PlayerList$Alliance                                     | `Xml_Player_List_Alliance`      |
  | struct:org.triplea.map.data.elements.ResourceList                                            | `Xml_Resource_List`             |
  | struct:org.triplea.map.data.elements.ResourceList$Resource                                   | `Xml_Resource_List_Resource`    |
  | struct:games.strategy.triplea.delegate.battle.steps.change.suicide.RemoveUnits               | `Suicide_Remove_Units`          |

  All other map-data XML element classes keep the file-derived
  name unchanged. The bare names `Player_List`, `Resource_List`,
  `Remove_Units` are reserved for the engine classes named in
  `llm-instructions.md` §1 (the harness's authoritative type list).
- Java primitives: boolean→bool, int→i32, long→i64, float→f32,
  double→f64, String→string, BigDecimal→f64.
- Cross-struct refs mirror the Java field type: a Java field
  declared as another class (e.g. `Player owner`, `List<Unit>
  units`) becomes `owner: ^Player` / `units: [dynamic]^Unit`. Do
  NOT invent synthetic `*_Id` substitutions (no `owner_id:
  string`, no `unit_ids: [dynamic]string` when Java holds the
  objects directly). BUT if the Java field really is a `String`
  / `UUID` / numeric id, keep it as `string` / etc. — mirror
  Java exactly, do not "upgrade" string ids into pointers.
- Collections: List<T>→[dynamic]^T, Map<K,V>→map[K]V,
  Set<T>→map[^T]struct{}.
- Single inheritance: `using parent: Parent` as the FIRST field.
- Interface with no fields → `Type_Name :: struct {}`.
- Java enum → Odin `enum`.
- Inner classes get their OWN file (already provisioned in
  odin_flat/) — do not include them inline.
- Functional interfaces → Odin `proc(...)` type literals as fields.
- Java implementing `Named` → embed `using named: Named` (Named is
  the 2-level form already on disk).

Already-ported dependencies: every type at a lower struct_layer is
ALREADY implemented in /home/caleb/todin/odin_flat/. Reference them;
do NOT re-define them. If you believe a referenced type is missing,
grep odin_flat/ first; only if truly absent, return
`blocked: missing <Type_Name>`.

JDK boundary types: if the Java field/parameter you need to model
is a `java.*` / `javax.*` type (e.g. `CountDownLatch`, `Thread`,
`ExecutorService`, `Instant`, `Optional`, `URI`), do NOT invent or
inline-define a stand-in type, and do NOT use `rawptr` to dodge
the issue. Grep `odin_flat/` for the snake_cased simple name first
(e.g. `Count_Down_Latch ::`). If found, use it. If absent, return:
  `blocked: missing JDK <fully.qualified.Name>`
The orchestrator will provision an `odin_flat/` shim and re-
dispatch you.

DO NOT update port.sqlite. The orchestrator handles that.

Return exactly one line:
  done: <comma-separated cross-struct types referenced, or "none">
or:
  blocked: <reason>
```

#### Phase B subagent prompt template (file-grouped methods)

A single Phase B subagent ports **every** unimplemented method that
lives in one Odin file, in one shot. The orchestrator builds the
method list from the SQL batch query above (all rows sharing the
same `odin_file_path` at the current `method_layer`) and substitutes
it into the template below.

```
Port a batch of Java methods to Odin per
/home/caleb/todin/llm-instructions.md (read it first; obey all rules).

Odin target file: <ODIN_FILE_PATH>
Owner struct(s): <distinct OWNER_STRUCT_KEYs in this file>
Java source(s):  <distinct JAVA_FILE_PATHs (usually one)>
Current method_layer: <N>

Methods to port (port ALL of them, in this file, in one edit pass):
  - <METHOD_KEY_1>
  - <METHOD_KEY_2>
  - ...
  - <METHOD_KEY_K>

Phase B: METHOD bodies. The owner struct(s) already exist in the
target Odin file with `package game` header — do NOT redefine them.
Append (or insert) one Odin proc per listed method_key.

Rules:
- Instance Foo.bar(int x) → `foo_bar :: proc(self: ^Foo, x: i32) -> ...`.
- Static Foo.baz(...)     → `foo_baz :: proc(...) -> ...`.
- Constructor new Foo(...) → `foo_new :: proc(...) -> ^Foo`.
- `obj.method(args)` calls become `foo_method(obj, args)`.
- Functional interface → Odin `proc` type literal.
- No reflection. No stubs. No `panic("not impl")`. No `// TODO`. No
  logging-only stub. Each body must be REAL behavior, or that
  specific method_key must be reported `blocked`.
- **`@Override` of a parent virtual / interface method.** Port the
  body as usual (e.g. `purchase_delegate_start :: proc(self: ^Purchase_Delegate)`).
  Phase B does NOT require you to wire the constructor — the
  constructor-side proc-field assignment (`self.start = ...`) is
  handled by the dedicated Phase B-2 vtable-wiring pass after every
  method body is in place. You may leave the constructor untouched.
  But: if you are also porting the constructor (`<init>` is in the
  batch) AND the parent's struct declares a proc-typed field whose
  name matches one of the methods you just ported, GO AHEAD and
  add `self.<field> = <snake>_<methodSnake>` (or a `*_v_*` shim
  cast where signatures differ) inside the constructor — Phase B-2
  will see your wiring as `ok` and skip the row.

Already-ported dependencies: every method at a lower `method_layer`
is ALREADY implemented in /home/caleb/todin/odin_flat/, and ALL
structs are implemented (Phase A is complete). Reference existing
procs and types; do NOT re-implement them. If a referenced proc is
missing, run:
  grep -l "<proc_name> :: proc" /home/caleb/todin/odin_flat/
to confirm. Only if truly absent, mark just the affected
method_key(s) `blocked: missing <proc_name>` and continue with
the rest of the batch.

JDK boundary types: if you need to call a JDK method (e.g.
`latch.countDown()`, `executor.submit(task)`, `instant.toEpoch
Milli()`), call the corresponding shim proc in `odin_flat/`
(`count_down_latch_count_down(self)`, `executor_service_submit(
self, task)`, `instant_to_epoch_milli(self)`). Grep first to find
the exact proc name. If the shim is genuinely absent, mark the
affected method_key(s) `blocked: missing JDK proc
<fully.qualified.Class.method>`. Never inline-implement JDK
behavior — the orchestrator extends the shim and re-dispatches.

Per-method status: you may succeed on some method_keys and fail on
others within the same file. Report each method_key's outcome
explicitly so the orchestrator can mark only the successful ones
done. Blocked method_keys are fine — the orchestrator will leave
them `is_implemented = 0` and a later batch (often a higher
`method_layer` pass, or a re-run after a missing dep is filled in)
will pick them up. Do NOT try to "force" a blocked method by
inventing stubs; honest blocking is the correct behavior.

DO NOT update port.sqlite.

Return EXACTLY one line, in one of these three forms:

  done: <space-separated method_keys all succeeded> | <comma-separated procs/types referenced, or "none">

  partial: <space-separated method_keys done> | blocked: <method_key> <reason>; <method_key> <reason>; ...

  blocked: <whole-file reason — nothing was ported>

Examples:
  done: proc:foo.Bar#a() proc:foo.Bar#b(int) | unit_get_owner, territory_get_units
  partial: proc:foo.Bar#a() | blocked: proc:foo.Bar#b(int) missing JDK proc java.time.Instant.now
  blocked: file header conflict — manual cleanup needed
```

### Session memory template (`/memories/session/triplea-port-progress.md`)

Create on first run if missing:

```md
# TripleA Java→Odin port progress

Workspace: /home/caleb/todin

## Phase A — structs
- Done: <S_DONE>/<S_TOTAL>
- Last batch ended at: <last struct_key>

## Phase B — methods
- Done: <M_DONE>/<M_TOTAL>
- Current method_layer: <N>

## Blocked entries
- (one per line: <key> — <reason>)
```

### Stop conditions (when to exit the loop)

- All structs and all methods `is_implemented = 1` AND Phase C
  passes 52/52 snapshot pairs → call `task_complete` with a final
  summary.
- Context budget feels tight (~70% used) → save progress and
  `task_complete` with the resume instruction.

Non-trivial blockers (harness mismatches, missing procs whose
DB rows claim implementation, signature drift, schema fixes) are
NOT stop conditions. The orchestrator addresses them per step 6a-2
and keeps going. Only stop when work is genuinely complete or the
context budget is exhausted.

### Things you must NOT do

- Do NOT use the `Explore` agent for translation (read-only).
- Do NOT mark entities `is_implemented = 1` based on a `blocked:`
  reply (mark them `0` if they were previously `1` but the proc
  is actually missing).
- Do NOT cross `method_layer` boundaries within a single parallel
  batch in Phase B.
- Do NOT bypass safety flags (`--no-verify`, etc.) in any git
  operations.

The orchestrator MAY:
- Write Odin code directly for any TripleA entity, struct, or
  method when delegation overhead isn't worth it (a small
  signature fix, a single missing accessor, a clear inline
  port from Java).
- Modify the snapshot harness and generated test files under
  `triplea/conversion/odin_tests/` to reconcile real type
  shape drift, mirroring changes back into
  `templates/odin_test_common/` and `scripts/patch_triplea.py`.
- Update `port.sqlite` directly to fix drift discovered during
  Phase C (rows incorrectly marked implemented, missing
  closures, etc.).
- Re-run `scripts/build_called_layered_tables.py` or other
  bootstrap scripts when the call graph needs reconciliation.

### Phase B-2: vtable wiring (after every method body is implemented)

Once `m_done == m_total`, Phase B is method-body-complete but is
NOT done. Java polymorphism (`@Override`) is modeled as proc-typed
fields on the parent struct (e.g. `I_Delegate.start: proc(^I_Delegate)`,
`Change.perform: proc(^Change, ^Game_State)`, `Named.kind:
Named_Kind`). Subclass `*_new` constructors MUST assign these
proc-fields and discriminator enums explicitly — Phase B's
template only ports method bodies, never the constructor wiring.

Run the scanner:

```sh
python3 scripts/scan_vtable_wiring.py --commit
sqlite3 port.sqlite "SELECT status, COUNT(*) FROM vtable_wiring \
  GROUP BY status;"
```

The scanner populates `port.sqlite.vtable_wiring` with one row per
(subclass, proc-field) pair, status `ok` / `missing` /
`missing_kind`. Loop:

```sh
sqlite3 -separator '|' port.sqlite "
  SELECT odin_struct_name, proc_field, java_method, parent_struct,
         constructor, status, odin_file_path, owner_struct_key
  FROM vtable_wiring
  WHERE status IN ('missing', 'missing_kind')
    AND known_broken = 0
  ORDER BY odin_file_path, odin_struct_name, proc_field
  LIMIT 64;"
```

Group rows client-side by `odin_file_path`, dispatch ONE subagent
per file (≤8 in parallel) using the **Phase B-2 subagent template
in `phase-b.md`**. After the batch returns, re-run
`scan_vtable_wiring.py --commit` and continue until:

```sql
SELECT COUNT(*) FROM vtable_wiring
 WHERE status != 'ok' AND known_broken = 0;   -- → 0
```

Only then does Phase C start. Treat any `missing*` row with
`known_broken = 0` as a hard gate identical to an unimplemented
`methods` row. Rows with `known_broken = 1` are deferred Phase C
work items (delegate body crashes when proc-field is wired) and
do NOT block the gate — they show up explicitly in the
constructor as `_ = <shim>` discards. The scanner preserves
`known_broken` across runs.

### Phase C: progressing known_broken rows

The Phase C snapshot baseline (currently 30/52) is achieved with
the `known_broken=1` set deliberately unwired. To improve the
baseline, pick one delegate at a time and:

1. Inspect what crashes:
   ```sh
   sqlite3 -header -column port.sqlite "
     SELECT odin_struct_name, proc_field, substr(known_broken_reason,1,120)
     FROM vtable_wiring WHERE known_broken = 1
     ORDER BY odin_struct_name, proc_field;"
   ```
2. In the corresponding constructor (`<delegate>_new`), swap one
   `_ = <delegate>_v_<field>` discard back to
   `self.<field> = <delegate>_v_<field>`.
3. Re-run the snapshot test. Find which snap newly aborts. The
   abort is silent — diagnose by adding `log.errorf` traces inside
   the body proc until the crash site is found, then port the
   missing logic from the Java source.
4. Once the body is fixed and snapshots no longer regress:
   ```sql
   UPDATE vtable_wiring
      SET known_broken = 0, known_broken_reason = NULL
    WHERE odin_struct_name = '<X>' AND proc_field = '<Y>';
   ```
5. Re-run `scripts/scan_vtable_wiring.py --commit` to confirm
   `effective_missing=0` and the row reads `ok / known_broken=0`.

This is the genuine Phase C porting work. Each `known_broken` row
is a discrete trackable unit; progress is visible in the DB rather
than scattered across LLM session memory.

### Phase C: layered drill-down for snapshot diffs

Once `known_broken=0` is reached, remaining snapshot failures are
proc bugs (incorrect translation of a Java method body) or
harness data gaps (json_loader / test_server_game.odin omitting a
field the proc reads). Use the **layered drill-down** procedure
defined in `llm-instructions.md` "Layered drill-down debugging" —
it is the canonical methodology and the orchestrator MUST follow
it for every Phase C failure. Summary:

1. From the failing snapshot's JSON diff (or panic frame),
   identify the failing Odin proc, translate to its Java
   `method_key`, and mark it **red** with
   `scripts/mark_test_status.py <KEY> red --note '<symptom>'`.
2. Run `python3 scripts/next_task.py`. The picker chooses the
   deepest red and lists its yellow (unclassified) dependencies.
3. **Classify every yellow sibling first via a fixture-driven
   golden test.** Yellow means UNKNOWN, not "the bug." For each
   yellow sibling, follow the methodology in
   `llm-instructions.md` §"How to classify a yellow proc". The
   preferred path is:

     a. Try coverage first — instrument the proc with a
        temporary `eprintln` and re-run the snapshot suite; if
        a passing snapshot fires it on a non-trivial branch,
        green.
     b. **Capture Java goldens with `scripts/capture_proc_snapshot.py`**
        when the proc has a return value or pure-state output.
        It runs the Byte Buddy snapshot agent under
        `Ww2v5JacocoRun.runWithSnapshots` and writes
        `before.json`, `after.json`, `return.txt` per call to
        `triplea/conversion/odin_tests/dep_<snake_class>_<snake_method>/snapshots/`.
        Defaults: 10 MiB / 10 min caps (hard kill at +60 s);
        override with `--max-bytes` / `--max-minutes`. Combat-
        phase procs typically need `--rounds 3`.
     c. Then add a `when #config(PROBE_<NAME>, false)` log line
        in the Odin proc, run the snapshot suite with
        `-define:PROBE_<NAME>=true`, and visually compare the
        probe output against the captured `return.txt`s.
     d. Targeted Odin fixture test (Step 3 of the methodology)
        when the proc's effects can't be serialised by the
        agent — e.g. side effects via `bridge.addChange`,
        history events, or sound emissions. Use the
        `dbg_*_capture_enabled` hooks; see
        `dep_mark_attacking_transports/` for a worked example.

   Remove probes / instrumentation BEFORE marking status, and
   re-run the snapshot suite to confirm the baseline `Results: N
   passed, M failed` count is unchanged. Mark the result green
   or red via `scripts/mark_test_status.py` with a note that
   cites the goldens dir and the observed divergence.
   **Crash-only / non-nil / non-empty / trivial-input
   assertions are forbidden as proof of green.** If you cannot
   build a real golden test for a sibling, leave it yellow —
   never mark green to "make progress."
4. If any sibling came back red, re-run `next_task.py` — the
   picker will choose it as the new deepest red and you drill
   there. If every sibling came back green, the picker pops up
   to `INVESTIGATE_PROC` on the original red — the bug is in its
   own body. Recursion strictly decreases `method_layer` and
   terminates at layer 0 leaves.
5. The unique proc whose own dependencies all pass but whose
   own output diverges IS the bug site. Re-port it from `.java`,
   never invent code.

   **5a. RESET-AND-REPORT when the Odin diverges structurally
   from Java.** Before editing the bug-site proc, read the
   Java method side-by-side with the Odin body. If the Odin is
   not a one-statement-at-a-time translation — e.g. it inlines
   what Java dispatches virtually, fans a stream pipeline into
   N hand-rolled blocks, or otherwise rewrites the algorithm —
   do NOT patch it. Run:

   ```sh
   sqlite3 port.sqlite "UPDATE methods SET is_implemented = 0 \
     WHERE method_key = '<KEY>';"
   ```

   then delete the proc body (and any companion helpers that
   exist solely to support the divergent shape) from the Odin
   file, leaving struct decls, constructors, and unrelated
   procs intact. The next Phase B iteration will re-port the
   method faithfully from Java. This avoids fix-and-revert
   loops where each patch (vtable wiring, headless guards,
   workaround flags) papers over an architectural mismatch and
   re-breaks elsewhere. See `llm-instructions.md` §"Layered
   drill-down debugging" item 8a for the canonical procedure.
6. **Never write Odin from scratch.** Open the original Java
   method at `java_file_path:java_lines`, read it in full, and
   translate one statement at a time, preserving control flow,
   variable names (snake_cased), and operator order. The Java
   source is the only source of truth.
7. **Never edit the snapshots themselves.** Edit the proc, or
   (when the diff genuinely traces to harness data the loader
   isn't carrying) edit `templates/odin_test_common/json_loader.odin`
   + `scripts/patch_triplea.py` and re-run bootstrap.
8. **Never drill into a yellow node directly.** It might be
   perfectly correct; classifying it via real golden test is
   the only way to bound the search.
9. **Never mark a proc green based on "doesn't crash."** False
   greens hide bugs at the wrong layer and defeat the whole
   drill-down. If the only test you can write is a smoke test,
   the proc must stay yellow.
10. Record each layer-0 fix in `/memories/repo/phase-c-state.md`
    so future resume sessions see the audit trail.

The drill-down is order-of-magnitude cheaper than guess-and-check
debugging: it bounds the search space to a strict subtree of
`dependencies`, all of whose layers are < the failing proc's. The
moment a layer-0 dependency fails its targeted test, you have a
concrete, isolated bug site — fix it, re-test upward, and
regressions become impossible to introduce blindly.

---

(end of PROMPT)
