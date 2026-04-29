# Resume prompt — TripleA Java→Odin port

> **Copy the entire "PROMPT" block below and paste it into a fresh chat
> any time the context window fills up. It is idempotent: it always
> queries `port.sqlite` for the next unfinished work and dispatches one
> subagent per entity. Re-run until both `structs` and `methods` are
> 100% `is_implemented = 1`.**

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
   - Else → **Phase C** (snapshot validation): compile + run the
     snapshot tests per `llm-instructions.md` §Phase C, then
     `task_complete`.

3. **Pull the next batch (12 entities)** from the DB.

   Phase A query:
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT struct_key, java_file_path, odin_file_path, struct_layer
     FROM structs WHERE is_implemented = 0
     ORDER BY struct_layer, scc_id, struct_key
     LIMIT 12;"
   ```

   Phase B query (NEVER cross a `method_layer` boundary in one batch —
   trim the batch at the layer change):
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT method_key, owner_struct_key, java_file_path, odin_file_path, method_layer
     FROM methods WHERE is_implemented = 0
     ORDER BY method_layer, method_key
     LIMIT 12;"
   ```

4. **Dispatch one subagent per row, in parallel**, using `runSubagent`
   with `agentName` omitted (the default coding subagent — `Explore`
   cannot write files). Use the prompt templates in the next section.
   All 12 calls go in a single tool-call block.

5. **Collect results.** Each subagent returns one line:
   `done: <referenced types>` or `blocked: <reason>`.

6. **Update the database** for every `done:` row in a single
   `sqlite3 ... "UPDATE ... WHERE ... IN (...)"` call. Remember to
   backslash-escape `$` in inner-class keys
   (e.g. `'struct:foo.Bar\$Baz'`). For `blocked:` rows, do NOT mark
   them implemented — proceed to step 6a.

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
       - Name collision between a map-data XML element class and an
         engine class of the same simple name.
       - Odin file already contains content that conflicts with the
         expected `package game` header.
       - Subagent misread the rules (e.g. tried to define an inner
         class inline).

    2. **Decide: trivial auto-fix vs. stop.**
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
       - **Anything else** (ambiguous, requires schema/DB changes,
         affects the harness, or could mask a deeper bug) → STOP.
         Do NOT auto-fix. Print the likely cause clearly:
         ```
         BLOCKED (manual review required):
           entity: <key>
           reason: <subagent reason>
           likely cause: <your one-paragraph diagnosis>
           suggested next step: <e.g. "add file X to bootstrap
             provisioning", "edit scripts/patch_triplea.py", "split
             struct Y in DB">
         ```
         Save the same block into session memory under "Blocked
         entries", then call `task_complete`.

    3. **Never** mark a blocked entity `is_implemented = 1`, and
       never bypass the rule against editing the harness.

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
  should NOT appear under `actually_called_in_ai_test = 1`. If
  one does, that's a JaCoCo filter regression — STOP and
  document, do NOT auto-shim.

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

- It is doing **one** entity. The orchestrator owns the DB; the
  subagent must NOT update `port.sqlite`.
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
- Return exactly one line: `done: <comma-separated types referenced>`
  or `blocked: <reason>`.

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
- Cross-struct refs become `^Type` pointers. NO `*_Id` types.
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

#### Phase B subagent prompt template (method)

```
Port one Java method to Odin per /home/caleb/todin/llm-instructions.md
(read it first; obey all rules).

Entity: <METHOD_KEY>
Owner struct: <OWNER_STRUCT_KEY>
Java source: <JAVA_FILE_PATH> (focus on the method matching METHOD_KEY)
Odin target: <ODIN_FILE_PATH> (append the proc to this file)

Phase B: METHOD body. The owner struct already exists in the Odin
file with `package game` header — do NOT redefine it.

Rules:
- Instance Foo.bar(int x) → `foo_bar :: proc(self: ^Foo, x: i32) -> ...`.
- Static Foo.baz(...)     → `foo_baz :: proc(...) -> ...`.
- Constructor new Foo(...) → `foo_new :: proc(...) -> ^Foo`.
- `obj.method(args)` calls become `foo_method(obj, args)`.
- Functional interface → Odin `proc` type literal.
- No reflection. No stubs. No `panic("not impl")`. No `// TODO`. No
  logging-only stub. The body must be REAL behavior or return
  `blocked: <reason>`.

Already-ported dependencies: every method at a lower `method_layer`
is ALREADY implemented in /home/caleb/todin/odin_flat/, and ALL
structs are implemented (Phase A is complete). Reference existing
procs and types; do NOT re-implement them. If a referenced proc is
missing, run:
  grep -l "<proc_name> :: proc" /home/caleb/todin/odin_flat/
to confirm. Only if truly absent, return
`blocked: missing <proc_name>`.

JDK boundary types: if you need to call a JDK method (e.g.
`latch.countDown()`, `executor.submit(task)`, `instant.toEpoch
Milli()`), call the corresponding shim proc in `odin_flat/`
(`count_down_latch_count_down(self)`, `executor_service_submit(
self, task)`, `instant_to_epoch_milli(self)`). Grep first to find
the exact proc name. If the shim is genuinely absent, return:
  `blocked: missing JDK proc <fully.qualified.Class.method>`
The orchestrator will extend the shim and re-dispatch you. Never
inline-implement JDK behavior in a TripleA proc — it must live
in the shim file so all callers stay consistent.

DO NOT update port.sqlite.

Return exactly one line:
  done: <comma-separated procs/types referenced, or "none">
or:
  blocked: <reason>
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
- A subagent reports a harness-level blocker (it asks to edit
  `triplea/conversion/odin_tests/test_common/`) → STOP. Per
  `llm-instructions.md`, fix `scripts/patch_triplea.py` and re-run
  bootstrap. Document the change in session memory before stopping.
- A `blocked:` row's root cause is not trivially auto-fixable (see
  step 6a) → STOP after printing the diagnosis and suggested next
  step. Do not keep dispatching new batches that will hit the same
  blocker.
- Context budget feels tight (~70% used) → save progress and
  `task_complete` with the resume instruction.

### Things you must NOT do

- Do NOT write Odin code yourself for TripleA entities — always
  delegate to a subagent. (Exception: JDK shim files under the
  "JDK shim policy" above are orchestrator-owned infrastructure
  and the orchestrator writes them directly.)
- Do NOT use the `Explore` agent for translation (read-only).
- Do NOT mark entities `is_implemented = 1` based on a `blocked:`
  reply.
- Do NOT cross `method_layer` boundaries within a single parallel
  batch in Phase B.
- Do NOT modify the snapshot harness or generated `.odin` test
  files under `triplea/conversion/odin_tests/`.
- Do NOT bypass safety flags (`--no-verify`, etc.) in any git
  operations.

---

(end of PROMPT)
