You are the **orchestrator** for Phase B of the TripleA Java→Odin port.
The authoritative tracker is `port.sqlite` at the workspace root
(`/home/caleb/todin`). The full porting rules live in
[`llm-instructions.md`](./llm-instructions.md) — read that file once at
the start of the session, then proceed.

This prompt covers Phase B only (method bodies). If `structs` still has
unimplemented rows, stop and use [`resume-prompt.md`](./resume-prompt.md)
instead — Phase B assumes Phase A is 100% done.

#### Layering policy (iter-7 onward)

The `methods` / `dependencies` tables now include synthesized
**virtual-dispatch override edges** and (optionally) test-harness procs.
What this changes for Phase B:

- A method with `methods.is_abstract = 1` is a routing node from an
  interface or abstract base. It has no body to port. Its
  `is_implemented` flag should be set to 1 by
  `auto_implement_trivial_methods.py` (or you may set it manually).
- Skip rows with `methods.is_test_harness = 1` — these come from
  `Ww2v5JacocoRun` / `SnapshotHarness` / `GameTestUtils`. They drive
  the JaCoCo trace but are NOT porting targets (the Odin port has its
  own harness in `triplea/conversion/odin_tests/`).
- Layer numbers may shift on rebuild (most go UP, none go down). Treat
  each iteration's layer as authoritative; do not memoize layers
  across rebuilds.

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
   - Verify `s_done == s_total`. If not, STOP and switch to
     `resume-prompt.md` (Phase A still has work).
   - Print one line: `phase B: m_done/m_total`.

2. **Confirm Phase B has work left.** If `m_done == m_total`, Phase B
   is complete: switch to `resume-prompt.md` for Phase C (snapshot
   validation) and `task_complete`.

3. **Pull the next batch from the DB.**

   The current layer `L` is the minimum `method_layer` that still has
   any unimplemented method. The query below computes `L` in a CTE,
   picks up to 8 distinct `odin_file_path`s that have any unimplemented
   method at layer `L`, and returns every unimplemented layer-`L`
   method whose `odin_file_path` is in that batch — all in one
   round-trip.

   Methods at higher layers in the same file are **not** included; they
   wait for their own layer's pass. This is by design (cross-layer
   dependency safety) and avoids the back-and-forth of computing `L`
   in a separate step.

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

   - If the result set is empty, Phase B is complete — go to step 2.
   - The first column of every row is the layer `L` (same value on
     every row, by construction). Read it from the first row and
     record it in session memory under `Current method_layer:` so
     progress notes stay accurate.
   - Group the rows by `odin_file_path` client-side: each unique file
     becomes ONE subagent dispatch carrying the full list of layer-`L`
     `method_key`s for that file.

4. **Dispatch one subagent per file group, in parallel**, using
   `runSubagent` with `agentName` omitted (the default coding subagent
   — `Explore` cannot write files). Use the prompt template in the
   next section. All calls in the batch go in a single tool-call
   block. ≤8 subagents per batch (one per `odin_file_path`).

5. **Collect results.** Each subagent returns exactly one line in one
   of three forms:

   - `done: <space-separated method_keys that succeeded> | <comma-separated procs/types referenced, or "none">`
   - `partial: <done method_keys> | blocked: <method_key> <reason>; <method_key> <reason>; ...`
   - `blocked: <whole-file reason — nothing was ported>`

6. **Update the database.**
   - Collect every `method_key` reported done across the batch
     (including the done portion of any `partial:` reply) and run a
     single `UPDATE methods SET is_implemented=1 WHERE method_key IN (...)`.
   - Backslash-escape `$` in inner-class keys (e.g.
     `'proc:foo.Bar\$Baz#thing()'`).
   - For `blocked:` method_keys (whole-file or inside `partial:`) do
     NOT mark them implemented — proceed to step 6a.

6a. **Triage every `blocked:` row before the next batch.** Do not
    silently re-queue blocked entries; they will likely block again.
    For each blocked entry:

    1. **Analyze the root cause** from the subagent's reason. Cross-
       check by reading the Java source, the target Odin file, and any
       referenced Odin files in `odin_flat/` (use `grep_search` /
       `read_file`). Typical root causes:
       - **Cross-layer dependency** — a layer-N method calls a helper
         that lives at layer M > N. The bootstrap layering should
         normally prevent this, but Lombok-generated helpers, varargs
         forwarders, and a few genuine SCC edges occasionally end up
         at a higher layer than their callers. This is a **benign
         skip** — see step 6a.2.
       - A **JDK boundary proc** is referenced (e.g.
         `count_down_latch_await`, `executor_service_submit`,
         `instant_to_epoch_milli`). The bootstrap excludes JDK classes
         from `port.sqlite`, but Java methods legitimately call them.
         **Resolve by provisioning/extending a JDK shim file in
         `odin_flat/`.** See "JDK shim policy" below.
       - A referenced TripleA proc is genuinely absent from
         `odin_flat/` (provisioning gap, or earlier lower-layer batch
         skipped it).
       - Odin file already contains content that conflicts with the
         expected `package game` header (rare in Phase B since Phase A
         wrote the file, but possible if leftover scaffolding remains).
       - Subagent misread the rules (e.g. tried to redefine the owner
         struct).

    2. **Decide: skip, trivial auto-fix, or stop.**
       - **Benign skip — cross-layer dependency.** If the blocker is
         "depends on `<other_method_key>` at method_layer M (not yet
         ported)" and that other method genuinely lives at a higher
         layer in `port.sqlite`, **do nothing**: leave the blocked
         `method_key` `is_implemented = 0` and move on. The higher
         layer's own pass will pick it up. Record the skip in session
         memory under "Skipped (cross-layer dependency)" so the
         pattern is visible across runs, but **do not stop the loop
         and do not auto-fix**. Treat partial-batch successes the
         same way: mark the done method_keys, leave the blocked one
         as `is_implemented = 0`, and continue.
       - **Trivial & obvious** → fix it inline and re-dispatch ONE
         subagent for that specific entity in the next batch.
         Examples of trivial fixes the orchestrator MAY perform
         directly:
         - **Provisioning a JDK shim file** (or extending an
           existing one with a missing proc) per "JDK shim policy"
           below. Once the shim exists, every future reference to
           that JDK proc resolves automatically.
         - Removing leftover scaffolding/TODO content in the target
           file when it prevents the subagent from writing a clean
           append.
         - Re-dispatching with a clearer hint when the subagent's
           confusion is purely about rules interpretation.
       - **Anything else** (ambiguous, requires schema/DB changes,
         affects the harness, or could mask a deeper bug) → STOP.
         Do NOT auto-fix. Print the likely cause clearly:
         ```
         BLOCKED (manual review required):
           method_key: <key>
           reason: <subagent reason>
           likely cause: <your one-paragraph diagnosis>
           suggested next step: <e.g. "extend shim X with proc Y",
             "edit scripts/patch_triplea.py", "investigate
             cross-layer cycle">
         ```
         Save the same block into session memory under "Blocked
         entries", then call `task_complete`.

    3. **Never** mark a blocked method `is_implemented = 1`, and never
       bypass the rule against editing the harness. A blocked method
       left `is_implemented = 0` is fine — it will be revisited
       automatically on a later batch (its own layer's pass, or after
       the dependency is filled in).

7. **Update session memory** (`/memories/session/triplea-port-progress.md`)
   with the new counters and any blockers (including auto-fixes
   applied this iteration, so future runs can see what the
   orchestrator changed on its own).

8. **Loop back to step 1** until Phase B completes, a non-trivial
   blocker forces a stop, or context feels tight (~70%+ used). When
   stopping mid-port:
   - Save final counters and current `method_layer` into session memory.
   - Print: `Stopping at <m_done>/<m_total> methods (layer <L>).
     Re-run phase-b.md to continue.`
   - Call `task_complete`.

### JDK shim policy (orchestrator-owned)

Java methods legitimately call into JDK types that the bootstrap does
NOT add to `port.sqlite` (only TripleA classes are tracked). When a
subagent reports `blocked: missing JDK proc <fq.Class.method>` (or any
blocked-for-missing-proc whose root cause is a JDK class), the
orchestrator MUST provision/extend the corresponding shim file in
`odin_flat/` and then re-dispatch the subagent.

**Shim location and naming.**

- File path: `odin_flat/<dotted-package-as-double-underscores>__<snake_case_simple_name>.odin`.
  Examples:
  - `java.util.concurrent.CountDownLatch` →
    `odin_flat/java__util__concurrent__count_down_latch.odin`
  - `java.lang.Thread` → `odin_flat/java__lang__thread.odin`
  - `java.util.concurrent.ExecutorService` →
    `odin_flat/java__util__concurrent__executor_service.odin`
- Type name: PascalCase_with_underscores of the simple name
  (`Count_Down_Latch`, `Thread`, `Executor_Service`, …). JDK shim type
  names MUST be derived from the simple class name only — never
  prefixed with the package path.
- Proc names: `<snake_simple_name>_<snake_method_name>` (e.g.
  `count_down_latch_count_down`, `executor_service_submit`,
  `instant_to_epoch_milli`).
- File header: `package game` (all of `odin_flat/` is one package).
- Before writing or extending, run
  `grep -l "<Type_Name> ::" /home/caleb/todin/odin_flat/` and
  `grep -n "<proc_name> :: proc" /home/caleb/todin/odin_flat/<shim>.odin`
  to confirm the current state.

**Shim content.**

Write a real, minimal Odin implementation — not an empty stub — so
every TripleA method that calls into the JDK type gets consistent,
working semantics. The shim is the single source of truth across the
whole port. Guidelines per category:

- **Concurrency primitives** (`CountDownLatch`, `Semaphore`,
  `ReentrantLock`, …): emit a struct with the state fields the Java
  class actually uses (e.g. `Count_Down_Latch :: struct { count: i32 }`)
  plus the small set of procs the TripleA code actually calls. Single-
  process AI-snapshot runs, not real multi-threading — implement the
  semantics needed to satisfy callers, not full JVM thread safety.
- **Threading / executors** (`Thread`, `ExecutorService`,
  `ScheduledExecutorService`, `ScheduledFuture`, `CompletableFuture`):
  the snapshot harness pins `PlainRandomSource.fixedSeed = 42L` and
  runs single-threaded. Implement these as direct/synchronous:
  `Executor_Service :: struct {}` with `executor_service_submit ::
  proc(self: ^Executor_Service, task: proc()) { task() }`, etc.
  Document this with a single one-line comment at the top of the shim.
- **Value types** (`java.time.Instant`, `java.net.URI`,
  `java.util.UUID`, `java.math.BigDecimal`, `java.awt.Point`,
  `java.awt.Color`): port to a struct of plain primitive fields.
  Note `BigDecimal` is already mapped to `f64` per
  `llm-instructions.md` and does not need a shim.
- **Collections beyond what `llm-instructions.md` covers**
  (`Optional<T>`, `Queue<T>`, `Deque<T>`, `Iterator<T>`): emit a
  small generic-ish wrapper using existing Odin primitives. Only add
  the procs the callers actually use.
- **NIO socket plumbing (known exception)**: the AI snapshot harness
  wires up Messengers / Test_Server_Game whose constructor
  instantiates `NioReader` / `NioWriter` for compile-time reasons,
  but no real socket I/O happens during the snapshot run. For these
  JDK NIO/concurrency-queue types, provision **opaque marker shims**
  (no real semantics) so callers compile:
  - `java.nio.channels.SocketChannel` → `Socket_Channel :: struct {}`
  - `java.nio.channels.Selector` → `Selector :: struct {}`
  - `java.nio.channels.SelectionKey` → `Selection_Key :: struct {}`
  - `java.nio.ByteBuffer` → `Byte_Buffer :: struct { data: [dynamic]u8, position: i32, limit: i32, capacity: i32 }`
  - `java.util.concurrent.BlockingQueue` →
    `Blocking_Queue :: struct { items: [dynamic]rawptr }` plus
    `blocking_queue_take`, `blocking_queue_offer`,
    `blocking_queue_poll` procs that do single-threaded in-order
    push/pop on `items`.
- **All other I/O** (Swing, AWT widgets beyond `Point`/`Color`, real
  `Socket`, `FileInputStream`, …) still triggers a STOP — those
  should not appear under `actually_called_in_ai_test = 1`.

**Workflow (orchestrator):**

1. Identify the JDK type/proc from the subagent's `blocked` reason
   (or by reading the Java source if the message is vague).
2. Compute the shim path, type name, and proc name per the rules above.
3. `grep` to confirm current shim state. Either create the file with
   `package game` + the struct + procs, or append the missing proc to
   an existing shim. (You may write this code yourself — JDK shims
   are orchestrator-owned infrastructure, not TripleA entity ports,
   so the "never write Odin yourself" rule does NOT apply here.)
4. Record the shim in session memory under "JDK shims provisioned
   this session" so future runs see what's already on disk.
5. Re-dispatch ONE subagent for the originally blocked method_key in
   the next batch, with a hint: `JDK shim proc
   <count_down_latch_await> has been provisioned in <path>; use it.`
6. Do NOT add the JDK shim to `port.sqlite`. The DB tracks only
   TripleA classes; JDK shims are provisioning, not work items.

If the requested JDK type does not fit any category above (rare, e.g.
a reflective or dynamic-proxy type), STOP per step 6a and document it
for manual review.

### Subagent dispatch template

Every Phase B subagent prompt MUST tell the subagent:

- It is doing **one Odin file's worth of methods** — every
  unimplemented `method_key` whose `odin_file_path` matches the
  assigned file, at the current `method_layer`. The orchestrator owns
  the DB; the subagent must NOT update `port.sqlite`.
- All structs are implemented (Phase A is complete) and all methods
  at lower `method_layer`s are already implemented in `odin_flat/`.
  The subagent should **reference existing types/procs**, not
  re-define them. If a referenced proc seems missing, the subagent
  should:
  1. Run `grep -l "<proc_name> :: proc" /home/caleb/todin/odin_flat/`.
  2. If found, use it.
  3. Only if genuinely absent, mark just the affected method_key(s)
     `blocked: missing <proc_name>`.
  This protects against re-implementation drift.
- Forward references to procs/types defined later in `odin_flat/` are
  fine — Odin resolves them at the package level.
- Read `/home/caleb/todin/llm-instructions.md` at the start for the
  rules summary.
- Return EXACTLY one line in one of the three formats below.

A single Phase B subagent ports **every** unimplemented method that
lives in one Odin file at the current layer, in one shot. The
orchestrator builds the method list from the SQL batch query above
(all rows sharing the same `odin_file_path` at the current
`method_layer`) and substitutes it into the template:

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
  body as usual. The constructor-side proc-field assignment is
  handled by the dedicated Phase B-2 vtable-wiring pass after every
  method body is in place — see "Phase B-2: Vtable wiring pass"
  below. You may leave the constructor untouched here.

Already-ported dependencies: every method at a lower `method_layer`
is ALREADY implemented in /home/caleb/todin/odin_flat/, and ALL
structs are implemented (Phase A is complete). Reference existing
procs and types; do NOT re-implement them. If a referenced proc is
missing, run:
  grep -l "<proc_name> :: proc" /home/caleb/todin/odin_flat/
to confirm. Only if truly absent, mark just the affected
method_key(s) `blocked: missing <proc_name>` and continue with the
rest of the batch.

JDK boundary calls: if you need to call a JDK method (e.g.
`latch.countDown()`, `executor.submit(task)`, `instant.toEpochMilli()`),
call the corresponding shim proc in `odin_flat/`
(`count_down_latch_count_down(self)`, `executor_service_submit(self,
task)`, `instant_to_epoch_milli(self)`). Grep first to find the exact
proc name. If the shim is genuinely absent, mark the affected
method_key(s) `blocked: missing JDK proc <fully.qualified.Class.method>`.
Never inline-implement JDK behavior — the orchestrator extends the
shim and re-dispatches.

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
- Done: <S_DONE>/<S_TOTAL>   (should be 100% before running phase-b.md)

## Phase B — methods
- Done: <M_DONE>/<M_TOTAL>
- Current method_layer: <N>

## JDK shims provisioned this session
- (one per line: <fq.Type> → <odin_flat/path> [proc1, proc2, ...])

## Skipped (cross-layer dependency)
- (one per line: <method_key> — depends on <other_method_key> at layer <M>)

## Blocked entries
- (one per line: <method_key> — <reason>)
```

### Stop conditions (when to exit the loop)

- All methods `is_implemented = 1` → run `resume-prompt.md` for
  Phase C (snapshot validation), then `task_complete`.
- A subagent reports a harness-level blocker (it asks to edit
  `triplea/conversion/odin_tests/test_common/`) → STOP. Per
  `llm-instructions.md`, fix `scripts/patch_triplea.py` and re-run
  bootstrap. Document the change in session memory before stopping.
- A `blocked:` row's root cause is **not** a benign cross-layer skip
  and is not trivially auto-fixable (see step 6a) → STOP after
  printing the diagnosis and suggested next step. Cross-layer
  dependency blockers are NOT a stop condition — they are expected
  and handled by leaving the method `is_implemented = 0` and
  continuing.
- Phase A regression (`s_done < s_total`) → STOP, switch to
  `resume-prompt.md`.
- Context budget feels tight (~70% used) → save progress and
  `task_complete` with the resume instruction.

### Things you must NOT do

- Do NOT write Odin code yourself for TripleA methods — always
  delegate to a subagent. (Exception: JDK shim files under the "JDK
  shim policy" above are orchestrator-owned infrastructure and the
  orchestrator writes them directly.)
- Do NOT use the `Explore` agent for translation (read-only).
- Do NOT mark methods `is_implemented = 1` based on a `blocked:`
  reply.
- Do NOT cross `method_layer` boundaries within a single parallel
  batch.
- Do NOT modify the snapshot harness or generated `.odin` test files
  under `triplea/conversion/odin_tests/`.
- Do NOT bypass safety flags (`--no-verify`, etc.) in any git
  operations.
---

## Phase B-2: Vtable wiring pass (after method bodies complete)

Phase B's per-method dispatch ports the **bodies** of overriding
methods (`purchase_delegate_start`, `change_attachment_change_perform`,
…) but does NOT wire the constructor-side proc-fields that connect
those bodies to the parent's vtable. Without that wiring,
polymorphic dispatch through `^I_Delegate` / `^Change` /
`^Named` silently no-ops at runtime even though `odin check` is
clean.

**This was the 30→34/52 plateau in the original snapshot run** —
many `*_perform`, `*_start`, `*_end`, `*_save_state`, `*_load_state`
bodies existed and were marked `is_implemented = 1`, but the
corresponding `*_new` constructors never assigned the proc-fields
on the parent. Phase B-2 closes that gap before Phase C can pass.

### When Phase B-2 runs

After every layer of regular Phase B finishes (i.e. when
`SELECT MIN(method_layer) FROM methods WHERE is_implemented = 0`
returns `NULL`), the orchestrator runs:

```sh
python3 scripts/scan_vtable_wiring.py --commit
```

This scans `odin_flat/` and populates `port.sqlite.vtable_wiring`
with one row per (subclass, proc-field) pair. Statuses:

  - `ok`            — constructor assigns the proc-field (any path,
                       direct or through a delegated `*_new_canonical`)
  - `missing`       — Java has `<Class>#<methodName>` AND parent
                       declares `<methodName>: proc(...)` but the
                       subclass's `*_new` never assigns it
  - `missing_kind`  — parent transitively carries a `kind: <Enum>`
                       discriminator but the constructor never sets
                       `self.kind = .<Variant>`

### Vtable-wiring batch query

```sh
sqlite3 -separator '|' port.sqlite "
  SELECT odin_struct_name, proc_field, java_method, parent_struct,
         constructor, status, odin_file_path, owner_struct_key
  FROM vtable_wiring
  WHERE status IN ('missing', 'missing_kind')
    AND known_broken = 0
  ORDER BY odin_file_path, odin_struct_name, proc_field
  LIMIT 8;"
```

Group rows by `odin_file_path` and dispatch ONE subagent per file
(up to 8 in parallel) using the template below. After all
subagents return, re-run `scan_vtable_wiring.py --commit`. Repeat
until the count above reaches 0.

Rows with `known_broken = 1` are deliberately deferred Phase C work
(the body of the wired proc has a latent porting bug that crashes
the snapshot harness when the proc-field is wired). The scanner
preserves these flags across runs. To inspect or progress them:

```sh
sqlite3 -header -column port.sqlite "
  SELECT odin_struct_name, proc_field, substr(known_broken_reason,1,80)
  FROM vtable_wiring WHERE known_broken = 1;"
```

Fix the underlying body, then in the constructor replace the
`_ = <shim>` discard with `self.<field> = <shim>` and clear the
flag: `UPDATE vtable_wiring SET known_broken=0, known_broken_reason=NULL
WHERE odin_struct_name='X' AND proc_field='Y';`.

### Phase B-2 subagent prompt template

```
Wire constructor proc-fields ("vtable wiring") for one Odin file
per /home/caleb/todin/llm-instructions.md "Vtable wiring" section
(read it first; obey all rules).

Odin target file: <ODIN_FILE_PATH>
Wirings to add (each is a (struct, proc_field, status) triple):
  - <Odin_Struct_Name>.<proc_field>  status=<missing|missing_kind>
    parent=<Parent_Struct>  java_method=<methodCamel or "kind">
    constructor=<expected_constructor_name>
  - ...

Rules per row:
  1. For status=`missing`: locate the `<expected_constructor_name>`
     proc in the file (or any `*_new*` returning ^Odin_Struct_Name).
     Add a `<snake>_v_<methodSnake>` shim proc taking the parent's
     signature and casting `^Parent_Struct` to `^Odin_Struct_Name`,
     then assign `self.<proc_field> = <snake>_v_<methodSnake>`
     inside the constructor BEFORE `return self`. The body the
     shim calls is `<snake>_<methodSnake>` (already implemented in
     Phase B). If multiple `*_new*` constructors exist, prefer
     adding the assignment to the canonical one (the longest-named
     `*_new_canonical` if present, else the most-arg overload).
  2. For status=`missing_kind`: assign `self.kind = .<Variant>`
     inside the constructor BEFORE `return self`. The expected
     `.<Variant>` is the Pascal_Underscore form of the struct name
     itself (e.g. `Owner_Change` → `.Owner_Change`).
  3. If the constructor delegates to another `*_new*` (e.g.
     `return foo_new_canonical(...)`), patch the canonical instead
     so every entry point benefits.
  4. Do NOT modify the method body procs themselves. Do NOT add
     new fields. Do NOT redefine the struct.
  5. If the corresponding `<snake>_<methodSnake>` body proc does
     not exist (sanity check via grep), mark that wiring
     `blocked: missing body proc <name>` and continue with the
     rest of the batch.

DO NOT update port.sqlite. The orchestrator re-runs
scan_vtable_wiring.py --commit after the batch returns.

Return EXACTLY one line:
  done: <Odin_Struct_Name>.<proc_field> ... | <referenced procs>
or:
  partial: <done struct.field> ... | blocked: <struct.field> <reason>; ...
or:
  blocked: <whole-file reason>
```

### Phase B-2 stop condition

Phase B is only complete when:

  ```sql
  SELECT COUNT(*) FROM methods WHERE is_implemented = 0;
  -- → 0
  SELECT COUNT(*) FROM vtable_wiring
   WHERE status != 'ok' AND known_broken = 0;
  -- → 0  (this is the "effective_missing" the scanner prints)
  ```

Only then does the orchestrator advance to Phase C. A non-empty
`vtable_wiring` with `missing*` rows where `known_broken = 0` is
treated identically to an unimplemented `methods` row: it blocks
Phase C. Rows with `known_broken = 1` are tracked Phase C work
items and do NOT block the gate (they are explicitly unwired in
the corresponding constructor with a `_ = <shim>` discard so the
snapshot harness reaches its prior baseline).
