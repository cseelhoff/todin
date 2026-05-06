# LLM porting instructions

> **Driving prompt:** to actually run the port, paste the `PROMPT`
> block from [`resume-prompt.md`](./resume-prompt.md) into a fresh
> chat. That prompt implements the orchestrator loop described
> below — query DB → dispatch ~12 parallel subagents → update DB →
> repeat — and is the canonical entry point after `./bootstrap.sh`.
> This file is the rulebook the orchestrator and every subagent
> read; `resume-prompt.md` is the runner.

You are an autonomous coding agent porting TripleA from Java to Odin.
Your inputs are:

1. `port.sqlite` — the authoritative tracker. Every class and method that
   the running game touches is a row.
2. `odin_flat/*.odin` — one blank file per Java owner class, paths
   already recorded in `port.sqlite`. All files share `package game`.
3. The TripleA Java sources at `$TRIPLEA_DIR`.
4. The snapshot harness at `$TRIPLEA_DIR/conversion/odin_tests/`,
   in particular `test_common/{json_loader,game_state_compare,
   snapshot_runner}.odin` which already pin down the expected Odin
   type shapes (`Game_Data`, `Game_Player`, `Territory`, `Unit`,
   `Unit_Type`, `Unit_Attachment`, `Tech_Attachment`, `Resource`,
   `Resource_Collection`, `Resource_List`, `Player_List`, `Game_Map`,
   `Units_List`, `Unit_Collection`, `Game_Sequence`, `Game_Step`,
   `Alliance_Tracker`, `Relationship_Tracker`, `Relationship`,
   `Relationship_Type`, `Relationship_Type_List`, `Related_Players`,
   `Game_Properties`, `Editable_Property`, `Property_Value`,
   `Test_Server_Game`, `Uuid`, `Integer_Map_Resource`).

You are not asked to design. The bootstrap already designed the order
and the data layout. Your job is mechanical translation, validated at
the end against snapshots.

---

## Subagent dispatch model (MANDATORY)

**Every conversion task MUST be delegated to a subagent via the
`runSubagent` tool.** The top-level (orchestrator) agent does not
write Odin code directly (except for JDK shim infrastructure — see
`resume-prompt.md`); it only:

1. Queries `port.sqlite` for the next batch of unimplemented work.
2. Spawns subagents in parallel (see granularity below).
3. Collects each subagent's report, updates `is_implemented` in
   `port.sqlite`, and proceeds to the next batch.

**Granularity:**

- **Phase A — one subagent per struct.** Each subagent edits exactly
  one struct's `odin_file_path`.
- **Phase B — one subagent per Odin file.** Methods are grouped by
  `odin_file_path`: a single subagent receives the full list of
  unimplemented `method_key`s that belong to one Odin file (at the
  current `method_layer`) and ports all of them in one editing
  pass. A given file commonly has many methods (sometimes dozens);
  porting them together avoids redundant file reads and keeps
  related procs visually adjacent. The subagent reports per-method
  success/failure so the orchestrator can mark only the genuinely
  ported `method_key`s `is_implemented = 1`.

Rules for subagent dispatch:

- **Independent subagents may be dispatched in parallel** within the
  same layer (Phase A is order-free across structs; Phase B is
  order-free *within* a single `method_layer`). Never parallelize
  across method layers, and never mix layers inside a single Phase
  B batch — the orchestrator pins each batch to the current minimum
  unfinished `method_layer` (see `resume-prompt.md` for the SQL).
- **Use the `Explore` agent for read-only scouting only** (e.g. "find
  every field referenced by `GameStateJsonSerializer` for class `Foo`")
  — `Explore` cannot write files. Use the **default coding subagent**
  (omit `agentName` in the `runSubagent` call) for the actual
  translation, since only it has file-write tools.
- **The subagent prompt must include**:
  - For Phase A: the exact `struct_key`, the Java source path
    (`java_file_path`), and the Odin target (`odin_file_path`).
  - For Phase B: the Odin target file (`odin_file_path`), the
    distinct owner struct key(s) and Java source path(s) for that
    file, and the **complete list of `method_key`s** to port in
    that file.
  - A pointer to this file (`llm-instructions.md`) for the rules.
  - The instruction to return a one-line status report. Phase A:
    `done` / `blocked`. Phase B: `done` / `partial` / `blocked`,
    enumerating per-`method_key` outcomes (see the Phase B template
    in [`resume-prompt.md`](./resume-prompt.md)).
- **The orchestrator owns the database.** Subagents must NOT run
  `UPDATE structs/methods SET is_implemented = 1`. They report
  completion; the orchestrator records it. This keeps the tracker
  authoritative. In Phase B the orchestrator may mark a strict
  subset of a subagent's assigned `method_key`s done when the
  subagent reports `partial:`.
- **No subagent edits the harness.** If a subagent reports it needs
  a harness change, the orchestrator stops, edits
  `scripts/patch_triplea.py`, and re-runs the bootstrap.
- **Layer ordering means dependencies already exist.** Phase A
  finishes before Phase B; within Phase B, every batch belongs to a
  single `method_layer` and all lower layers are complete. A
  subagent must therefore **reference** existing types/procs in
  `odin_flat/` rather than re-defining them. The dispatch templates
  in [`resume-prompt.md`](./resume-prompt.md) bake this in.

---

## Hard rules

1. **Only port entities flagged `actually_called_in_ai_test = 1`.**
   Other code is statically reachable but never runs in real games.

2. **Three sequential phases. Do NOT mix them.**
   - **Phase A — All structs.** Port every row in `structs` (631 total)
     before touching any proc. Within Phase A, ascending
     `struct_layer`, then `scc_id`, then alphabetical is the
     suggested review order, but Odin's package-level scope means
     order is not required for compilation.
   - **Phase B — All procs.** After every struct is implemented, port
     every row in `methods` (3,137 total) in ascending `method_layer`,
     then alphabetical. Procs DO have ordering dependencies; honor
     `method_layer`.
   - **Phase C — Snapshot validation.** After Phase B, run the snapshot
     test (one test, 52 paired before/after JSON snapshots). Diff
     failures, fix, repeat until 52/52 pass.

3. **Stay faithful to the Java field shapes.** The Odin port mirrors
   Java's data layout one-to-one. Translate each field as the Java
   declares it:
   - A field declared as another class type (`Player owner`,
     `List<Unit> units`, `Map<Territory, Integer> distances`) →
     pointer / collection of pointers (`owner: ^Player`,
     `units: [dynamic]^Unit`, `distances: map[^Territory]i32`).
     Use Odin's package-level forward declarations to resolve
     cycles; `^Player` inside `Territory` is fine even though
     `Player` is defined in a later file.
   - A field declared as a Java primitive or `String` stays a
     primitive or `string` (`name: string`, `count: i32`,
     `unit_id: string` if Java has `String unitId`).
   - **Do NOT invent synthetic `*_Id` substitutions.** If the Java
     field is `Player owner`, the Odin field is `owner: ^Player`,
     never `owner_id: string` / `owner_id: i32`. Likewise
     `List<Unit> units` is `units: [dynamic]^Unit`, never
     `unit_ids: [dynamic]string`. The rule prohibits replacing a
     real reference with a fabricated identifier; it does NOT
     prohibit Java fields that genuinely are `String` /
     `UUID` / numeric ids — those keep their Java type.
   - Conversely, do NOT "upgrade" a Java `String someId` field
     into `^Some_Type`. Mirror Java exactly.

   **Simple-name collisions (authoritative disambiguation table).**
   Three Java classes share a simple name with a harness-required
   engine type. The engine class keeps the bare Odin name; the twin
   uses a prefix:

   | Java struct_key                                                                                | Odin type name                  |
   |------------------------------------------------------------------------------------------------|---------------------------------|
   | `org.triplea.map.data.elements.PlayerList` (and inner `Player`, `Alliance`)                    | `Xml_Player_List(_Player|_Alliance)` |
   | `org.triplea.map.data.elements.ResourceList` (and inner `Resource`)                            | `Xml_Resource_List(_Resource)`  |
   | `games.strategy.triplea.delegate.battle.steps.change.suicide.RemoveUnits`                      | `Suicide_Remove_Units`          |

   Bare names `Player_List`, `Resource_List`, `Remove_Units` are
   reserved for the engine types listed in §1. All other map-data
   XML element classes keep their file-derived names unchanged.

4. **The harness scaffolding is authoritative.** Field names, sub-struct
   embeddings, and naming conventions in
   `triplea/conversion/odin_tests/test_common/*.odin` are not
   negotiable. If you need to change it, change `scripts/patch_triplea.py`
   and re-run bootstrap; do not edit the placed file directly.

   Conventions baked into the harness:
   - Snake_case file names (already on disk).
   - Type names PascalCase with underscores: `Game_Data`, `Unit_Type`.
   - Procs snake_case: `server_game_run_next_step`, `compare_game_states`.
   - Java classes implementing `Named` get a 2-level embedded form:
     ```odin
     Default_Named_Base :: struct { name: string }
     Named              :: struct { base: Default_Named_Base }
     // Subtypes embed Named:
     Game_Player :: struct { using named: Named, ... }
     ```
     so `player.named.base.name` works as the harness expects.
   - Maps use Odin builtin `map[K]V`. The harness allocates these
     explicitly with `make(...)`; struct definitions must declare
     them as plain `map[K]V` fields.

5. **No stubs. No "simplified". No "skipped".** Either fully port the
   entity or leave it untouched. The `is_implemented` flag must
   reflect reality.

6. **Match snapshot output byte-for-byte (Phase C only).** RNG is
   `PlainRandomSource.fixedSeed = 42L` for snapshot runs.

---

## Phase A workflow (structs)

Pick the next struct:

```sql
SELECT struct_key, java_file_path, struct_layer, scc_id
FROM structs
WHERE is_implemented = 0
ORDER BY struct_layer, scc_id, struct_key
LIMIT 1;
```

For each struct:

1. Read the Java source at `java_file_path`.
2. Open the Odin target file at `odin_file_path`. Replace the TODO
   header with `package game`.
3. **Translate the type only — no methods**:
   - Java `class Foo extends Bar implements Baz { Type field; }` →
     ```odin
     Foo :: struct {
         using bar: Bar,    // single inheritance: embed parent
         field: ^Type,      // cross-struct refs are pointers
     }
     ```
   - Primitives: `boolean → bool`, `int → i32`, `long → i64`,
     `float → f32`, `double → f64`, `String → string`,
     `BigDecimal → f64`.
   - Collections: `List<T> → [dynamic]^T`, `Map<K,V> → map[K]V`,
     `Set<T> → map[^T]struct{}`.
   - Java enums → Odin `enum`.
   - Inner classes (e.g. `AllianceTracker$SerializationProxy`) get
     their own top-level Odin struct in the same package.
4. **Skip method bodies entirely.** Methods are Phase B.
5. Mark struct done:
   ```sql
   UPDATE structs SET is_implemented = 1 WHERE struct_key = '...';
   ```

A struct is `is_implemented = 1` only when:
- The Odin source file exists with `package game`.
- The struct has all fields the JSON exporter writes (cross-check
  `GameStateJsonSerializer.java` and `json_loader.odin`).
- All field types referenced are defined somewhere in `odin_flat/`.

---

## Phase B workflow (methods)

Phase B batches methods **by `odin_file_path`**. The orchestrator
pulls every unimplemented method at the current minimum
`method_layer`, groups the rows by their target Odin file, and
dispatches one subagent per file (up to ~8 files in parallel). The
exact SQL lives in [`resume-prompt.md`](./resume-prompt.md); a
single subagent receives a file-and-method-list bundle of the form:

```
odin_file_path: <ODIN_FILE_PATH>
method_layer:   <N>
methods:
  - <method_key_1>
  - <method_key_2>
  - ...
```

For each method the subagent must:

1. Read the Java source at `java_file_path`, focused on the
   specific `method_key`.
2. Open the owner struct's Odin file at `odin_file_path` (the same
   file shared by every method in the bundle).
3. Translate:
   - Instance `Foo.bar(int x)` → `foo_bar :: proc(self: ^Foo, x: i32) -> ...`.
   - Static `Foo.baz(...)` → `foo_baz :: proc(...)`.
   - Constructor `new Foo(...)` → `foo_new :: proc(...) -> ^Foo`.
   - `obj.method(args)` → `foo_method(obj, args)`.
   - Functional interfaces → Odin `proc` type literal.
4. **No reflection.** The Java side's reflection is read-only and
   not part of the port surface.
5. Report per-method status back to the orchestrator (see Phase B
   subagent template in `resume-prompt.md`). The orchestrator runs
   a single batched update for the successful method_keys:
   ```sql
   UPDATE methods SET is_implemented = 1
   WHERE method_key IN ('...', '...', ...);
   ```

A method is `is_implemented = 1` only when:
- The proc body is real — no `// TODO`, no `panic("not impl")`, no
  logging-only stub.
- All called procs are themselves implemented (layer ordering
  guarantees this).
- **If the Java method is an `@Override` of a virtual on the parent
  class or interface**, the corresponding `*_new` constructor MUST
  assign the matching proc-typed field on the parent (this is how
  Odin models the JVM's vtable — see "Vtable wiring" below). A
  method body alone is NOT enough; without the constructor
  assignment, polymorphic dispatch through the parent type silently
  no-ops at runtime, even though the file compiles cleanly.

### Vtable wiring (constructor proc-field assignment)

Java polymorphism (`@Override`) is modeled in the port as
**proc-typed fields** on the parent struct (`I_Delegate.start: proc(^I_Delegate)`,
`Change.perform: proc(^Change, ^Game_State)`, etc.). For dispatch
through the parent type to reach a subclass override, the
subclass's `*_new` constructor MUST assign the proc-field
explicitly — Odin does NOT auto-wire methods to fields.

Convention:

```odin
purchase_delegate_v_start :: proc(self: ^I_Delegate) {
    purchase_delegate_start(cast(^Purchase_Delegate)self)
}
purchase_delegate_v_end :: proc(self: ^I_Delegate) {
    purchase_delegate_end(cast(^Purchase_Delegate)self)
}

purchase_delegate_new :: proc() -> ^Purchase_Delegate {
    self := new(Purchase_Delegate)
    self.start = purchase_delegate_v_start   // <-- WIRING
    self.end   = purchase_delegate_v_end     // <-- WIRING
    return self
}
```

The `*_v_*` shim is needed because Odin proc types are nominal:
`proc(^I_Delegate)` and `proc(^Purchase_Delegate)` are different
types even when the body would compile against either. The shim
takes the parent's signature and casts to the concrete pointer.

For the **discriminator-enum dispatch** pattern (used by
`Change_Kind` → `change_perform` switch, `Named_Kind` → various
JSON serializers, `History_Node_Kind` → tree walkers), the same
rule applies: every `*_new` constructor of a subtype MUST assign
the discriminator field, e.g. `self.kind = .Owner_Change`. A
missing kind-assignment makes the switch silently fall through to
the default case and the subtype is treated as a no-op.

The `scripts/scan_vtable_wiring.py` scanner enforces both
patterns. It is run by the orchestrator after Phase B completes
and populates the `vtable_wiring` table in `port.sqlite` with
status `ok` / `missing` / `missing_kind`. Phase B does NOT
finish until every `vtable_wiring.status = 'missing*'` row has
been resolved (the constructor patched and the row re-scanned to
`ok`). See `phase-b.md` "Vtable wiring pass" for the workflow.

---

## Phase C workflow (snapshot validation)

Phase C starts only after Phase A and Phase B are 100% complete.

1. Compile:
   ```sh
   cd $TRIPLEA_DIR/conversion
   odin check odin_tests/server_game_run_next_step \
       -collection:flat=../../odin_flat \
       -collection:test_common=odin_tests/test_common
   ```
2. Run:
   ```sh
   odin test odin_tests/server_game_run_next_step \
       -collection:flat=../../odin_flat \
       -collection:test_common=odin_tests/test_common
   ```
3. For each failure, **drill down by `method_layer`** to find the
   root-cause proc (see "Layered drill-down debugging" below). Do
   not edit the snapshots. Do not write new logic from scratch —
   every fix is a faithful re-port from the original `.java`.

### Layered drill-down debugging (snapshot failure root-causing)

When a snapshot test fails or crashes, **never start by guessing**
which proc is wrong. The `methods` table's `method_layer` column
plus the `dependencies` table give an exact procedure for finding
the root cause:

> **Note (iter-7).** The pipeline now records *both* the static
> call edge (declared receiver type, e.g.
> `proc:IPurchaseDelegate#purchase`) **and** synthesized
> `override` edges to every concrete impl in the methods set
> (e.g. `proc:ProAi#purchase`). When drilling down through a
> dependency list you will see both the abstract proc *and* its
> concrete override; descend into the override (it has the higher
> `method_layer` and the actual logic). Abstract / interface
> methods are flagged `methods.is_abstract = 1` and are present
> only as routing nodes; their `is_implemented` is irrelevant —
> the override implementation is what needs porting.

#### Mandatory: maintain a running drill-down trace table

Before, during, and after **every** drill-down step, you MUST
print a running **two-column trace table** showing the current
descent path from the originally-failing proc down to the node
under analysis. The table is a stack: append a row when you
descend into a dependency, pop the last row when a dependency
passes its targeted test and you back out, never silently skip
rows. Re-print the full table at each of these moments:

  1. After step 2 — initial node identified, table has one row.
  2. Before deciding which dependency to descend into (step 4),
     so the choice is auditable.
  3. After descending — append the new row, then re-print.
  4. Before committing to a fix at a layer-0 leaf or at a
     "dependencies-pass-but-this-proc-fails" node — the trace
     IS the justification; it bounds the bug site to one row.
  5. After every fix, walking back up: pop rows as their
     targeted tests turn green, re-printing the shortened
     table each pop, until you reach the original failing
     proc and confirm it now passes.

Format (Markdown, exactly two columns, layer descending):

| layer | method_key                                                  |
|------:|-------------------------------------------------------------|
|   34  | proc:games.strategy.triplea.ai.AbstractAi#start(java.lang.String) |
|   13  | proc:games.strategy.engine.delegate.IPurchaseDelegate#purchase(...) |
|   12  | proc:games.strategy.triplea.delegate.PurchaseDelegate#purchase(...) |

Generate each new row from the same SQL the drill-down already
uses (step 4 below), copying its `method_layer` and
`depends_on_key` columns into the trace.

Why this is mandatory:

  - It makes recursion termination provable — every appended row
    has strictly lower `method_layer` than the row above it; if
    that invariant ever breaks, the drill-down has gone wrong
    (most often: descended into an abstract routing node instead
    of its `override` target — see the iter-7 note above).
  - It gives the next session (or the next reviewer) the exact
    bug-site witness without re-deriving it.
  - It prevents the failure mode of "I think the bug is in
    proc X" without naming the chain that justifies X — every
    fix MUST cite the trace table that pinpointed it.

Record the final trace table (the one whose bottom row is the
fixed proc) in `/memories/repo/phase-c-state.md` together with
the fix summary, per step 10 below.

#### Mandatory: track per-proc test status in port.sqlite

Every proc / struct touched during a drill-down has a colored
test-status flag stored in the `test_status` table of
`port.sqlite`. The schema is:

```sql
CREATE TABLE test_status (
    entity_key  TEXT PRIMARY KEY,        -- matches entities.primary_key
    status      TEXT NOT NULL DEFAULT 'yellow'
                CHECK(status IN ('green','red','yellow')),
    note        TEXT,
    updated_at  TEXT NOT NULL
);
```

Semantics — exactly three states:

  - **green**: the entity is covered by **at least one
    fixture-driven test that compares observable outputs against
    a golden value derived from the Java reference**, AND that
    test currently passes, AND **every transitive call-graph
    descendant is also green**.

    What counts as a fixture-driven golden test (any one of):

      a. A snapshot test in `conversion/odin_tests/server_game_run_next_step/`
         whose execution path **provably enters the proc** (use a
         temporary `eprintln` counter or an explicit instrumentation
         build-tag to confirm coverage) AND whose post-state diff
         against `after.json` is empty.
      b. A targeted Odin test that loads a real `before.json`
         fixture via `tc.load_game_state`, calls the proc with
         the **exact arguments the parent passes at its real
         call site** (capture via a temporary trace in the parent
         if needed), and **value-compares** the proc's outputs
         and observable side effects (history-channel events,
         change-factory mutations, returned collections) against
         a golden expectation derived from the Java method body
         or from a Java-side reference run.
      c. A vtable test asserting the proc is bound to the
         correct concrete impl, IF the proc is purely a dispatch
         shim (zero behaviour of its own) AND every concrete
         override is itself green by criterion (a) or (b).

    **Crash-only / liveness-only assertions are FORBIDDEN as
    proof of green.** The following do NOT classify a proc green:
    `testing.expect(t, true, "no crash")`, `expect(x != nil)`,
    `expect(len(out) > 0)`, "returned without panicking", or any
    assertion that does not value-compare the proc's output to a
    golden derived from Java semantics. A proc that is exercised
    on a trivial early-return path (e.g. `headless=true` short
    circuit, `nil` channel guard, empty input list) is **not**
    green either — the test must drive the same realistic inputs
    the failing snapshot's parent feeds it.

    Invariant: a green proc cannot be a transitive caller of a
    red proc. If a "passing" test exists but the proc still
    transitively calls a red, that test is missing behaviour
    coverage (it exercises dispatch / a happy path that doesn't
    reach the broken callee) — the parent must stay yellow until
    the red descendant is fixed.

  - **red**: the entity has a failing fixture-driven test, OR
    the trace-table drill-down has positively identified it as
    the cause of a downstream golden mismatch.
  - **yellow** (default): untested / unknown — no fixture-driven
    golden test has been written yet, or the proc has not been
    visited by the drill-down. Every entity not in the
    `test_status` table is implicitly yellow. **Yellow is the
    correct status for a proc whose only available test is
    crash-only or trivial-input** — do not promote it to green.

The invariant is enforced two ways:

  1. `scripts/mark_test_status.py <KEY> green` REFUSES to mark a
     proc green when any transitive call-graph descendant is red
     (returns exit code 3).  Pass `--force` only after auditing
     that the test really does cover the relevant behaviour
     despite the red below — this is rare and should be noted.
  2. `scripts/validate_test_status.py` finds existing violations.
     Run it before committing test_status changes:

     ```sh
     python3 scripts/validate_test_status.py          # report only
     python3 scripts/validate_test_status.py --fix    # demote violators to yellow
     ```

     The fixer demotes each offending green to yellow with an
     audit note `auto-demoted: green parent of red descendant <KEY>`.

You MUST update the table at every drill-down moment that
changes a known status:

  1. When you mark a proc as the trace-table top row (it has
     a failing snapshot) → mark **red**.
  2. When you descend into a dependency to validate it →
     write its targeted test, run it, then mark **green** or
     **red** based on the result.
  3. When a fix flips a previously red proc green → mark
     **green** and set `note` to a one-line "what fixed it".
  4. When you discover an entity has no test at all and the
     drill-down does not implicate it → leave it yellow
     (do not invent green statuses).

Use the helper script (do **not** hand-write SQL):

```sh
python3 scripts/mark_test_status.py \
    "proc:games.strategy.engine.framework.ServerGame#runNextStep()" \
    red --note "snapshot 0013/0014/0015 fail"

python3 scripts/mark_test_status.py \
    "proc:games.strategy.triplea.ai.AbstractAi#purchase(...)" \
    green --note "vtable test test_pro_ai_purchase_vtable_wired green"

python3 scripts/mark_test_status.py summary
python3 scripts/mark_test_status.py list red
```

The `entity_key` is the exact `primary_key` from the `entities`
table — copy it from the same SQL the trace table is built from
so the two views stay aligned. Use `--force` only when marking
a synthetic key (e.g. an Odin-only helper that has no Java
peer).

The status table powers a realtime dashboard — start it with:

```sh
python3 scripts/test_status_dashboard.py            # http://127.0.0.1:8765/
```

The page polls `/api/tree` every 2 s and renders every red
entity together with its direct (one-layer-down) dependencies,
each colored by its current `test_status`. This is the canonical
view for monitoring drill-down progress: red cluster = current
work front; yellow children = not-yet-validated deps to descend
into; green children = deps whose targeted test already passed.
Keep the dashboard open while drilling so the trace table and
the colored tree stay in sync.

#### Mandatory: ask the picker for the next task

Every drill-down iteration begins with a single command:

```sh
python3 scripts/next_task.py
```

The picker is a deterministic, read-only function of
`test_status` ⨯ `dependencies` ⨯ `methods`. It implements the
exact algorithm that governs this entire workflow:

  1. Pick the **deepest red** proc (lowest `method_layer`).
  2. Look at its direct call-graph dependencies (rows of
     `dependencies` with `edge_kind` ∈ {`static`, `virtual`,
     `override`}, joined to `methods`). Each dep's status comes
     from `test_status` (default **yellow** when unrecorded).
  3. Emit one of three task kinds:
       - **`TEST_DEP`** — the chosen red has at least one yellow
         dep. **Yellow means UNKNOWN, not "the bug."** Your
         job is to *classify every yellow sibling first* by
         building a **fixture-driven golden test** for each one
         (per the methodology in "How to classify a yellow proc"
         below) and marking it **green** or **red** via
         `scripts/mark_test_status.py <KEY> {green|red}`.
         A green mark is only legitimate if the test value-
         compares the proc's outputs to a golden derived from
         the Java reference. Crash-only / non-nil / non-empty /
         trivial-input assertions are explicitly forbidden as
         proof of green — if that's all you have, the proc must
         stay yellow and you escalate to `INVESTIGATE_PARENT`
         (see below) instead of marking it. Then:
           * If any sibling came back **red**, drill into the
             deepest such red on the next picker iteration
             (it will surface automatically).
           * If every sibling came back **green**, the picker
             will pop up to `INVESTIGATE_PROC` on the original
             red — the bug is in that proc's own body.
         **Never** assume the deepest yellow is the bug and
         drill into it without first classifying its siblings.
       - **`INVESTIGATE_PROC`** — every dep is green (or the
         proc is a leaf with no recorded deps). The bug is
         inside this proc itself: re-read the original Java in
         full, diff against the Odin port, fix line-by-line, and
         flip the status to green when its targeted test passes.
       - **`NO_REDS`** — `test_status` has no red entries; mark
         the next failing snapshot's top-of-stack proc red to
         seed the next iteration.

You **MUST** start every drill-down iteration by running the
picker and quoting its `kind` + `red` + (if `TEST_DEP`)
yellow-children list in your trace table / progress note. Do not
guess what to test next — the picker has the deterministic
answer. Same view is rendered at the top of the dashboard
(`/api/next`).

JSON form for tooling / sub-agent dispatch:

```sh
python3 scripts/next_task.py --json
python3 scripts/next_task.py --top 5   # also show top-N reds
```

Termination: when `python3 scripts/next_task.py` reports
`NO_REDS` AND the failing snapshot suite is back to green for
the symptom you started from, the drill-down is done. Pop the
trace table and write the one-line note in
`/memories/repo/phase-c-state.md`.

#### How to classify a yellow proc (mandatory methodology)

Every yellow → green transition MUST be backed by a
fixture-driven golden test. Use the following decision procedure
in order; do **not** skip steps, do **not** invent shortcuts.

**Step 1 — Coverage by an existing green snapshot.**

Run the full snapshot suite and record which snapshots pass
(`scripts/run_full_snapshot_status.py` or equivalent). For each
yellow proc, check whether any **passing** snapshot's execution
path enters the proc on a non-trivial branch:

  1. Add a temporary one-line `eprintln` at the top of the proc
     body, behind `when ODIN_DEBUG` or a guarded counter — never
     a permanent log line.
  2. Re-run the passing snapshot suite. If the proc fires under
     a snapshot whose `after.json` diff is empty, the proc is
     covered by a passing golden comparison and may be marked
     **green** (note: `covered by snapshot <id> (post-state
     matches golden)`). The instrumentation MUST be removed
     before marking — record the snapshot id in the note as
     evidence.
  3. If no passing snapshot fires the proc on a realistic
     branch, proceed to step 2.

**Step 2 — Java-side capture via `capture_proc_snapshot.py`
(preferred when the proc has a return value or pure-state
output).**

The Byte Buddy snapshot agent at `templates/snapshot-agent/`
can capture before/after `GameData` plus the actual return
value of any Java method on demand. Use it to obtain the
golden directly from a Java run, avoiding manual derivation
from the Java source. Workflow:

  1. Run the capture (defaults: 10 MiB / 10 minute caps;
     overridable with `--max-bytes` / `--max-minutes`):

     ```sh
     python3 scripts/capture_proc_snapshot.py \
         --class <FQCN> \
         --method <methodName> \
         --rounds 3
     ```

     Combat-phase procs need `--rounds 3` or higher so battles
     fire under WW2v5 seed 42; round-1-only procs work with
     `--rounds 1`. The script:
       - builds (or reuses) the agent jar,
       - narrows the methods file to entries from the target
         class for ~50× speedup,
       - runs `Ww2v5JacocoRun.runWithSnapshots` with
         `-PsnapshotAgent=<jar>`,
       - filters tick dirs to ones whose `before-meta.txt`
         matches `<Class>.<method>(`,
       - renumbers them `0001..NNNN` under
         `triplea/conversion/odin_tests/dep_<snake_class>_<snake_method>/snapshots/`,
       - emits `before.json`, `after.json`, `before-meta.txt`,
         `after-meta.txt`, and `return.txt` per snap.

  2. Inspect the captured returns to confirm the proc fired
     on the path of interest and that returns vary (or are
     legitimately constant):

     ```sh
     for f in .../snapshots/*/return.txt; do
         printf "%s: " "$(basename $(dirname $f))"; cat $f
     done
     ```

     If the agent emitted `CAP_EXCEEDED.txt` in scratch, the
     driver surfaces a warning. Re-run with larger
     `--max-bytes` / `--max-minutes` only when justified — the
     defaults are tight on purpose because a runaway capture
     will fill the disk.

  3. Add a coverage probe at the top of the Odin proc behind
     `when #config(PROBE_<NAME>, false)` — log the same shape
     of output the Java agent recorded:

     ```odin
     when #config(PROBE_DETERMINE_STEP_STRINGS, false) {
         fmt.eprintf("[PROBE_STEPS] %d strings: %v\n",
             len(self.step_strings), self.step_strings)
     }
     ```

     Then run:

     ```sh
     odin test conversion/odin_tests/server_game_run_next_step \
         -collection:flat=/home/caleb/todin/odin_flat \
         -collection:test_common=conversion/odin_tests/test_common \
         -define:ODIN_TEST_TRACK_MEMORY=false \
         -define:PROBE_<NAME>=true 2>&1 | grep PROBE_
     ```

  4. **Compare the probe lines against the captured
     `return.txt`s.** If they match — green; if they diverge —
     red. Either way, the diff itself is gold for fixing the
     proc: it tells you exactly which inputs it differs on
     (different snapshot ids → different `return.txt` lines).

  5. Remove the probe via `replace_string_in_file` BEFORE
     marking status. Re-run the snapshot suite to confirm the
     baseline `Results: N passed, M failed` count is
     unchanged.

  6. Mark with full diagnostic context:

     ```sh
     scripts/mark_test_status.py '<METHOD_KEY>' {green|red} \
         --note 'Java goldens (NN captures) for <fixture>: <expected>. Odin probe in snap <id>: <observed>. Goldens at triplea/conversion/odin_tests/dep_<...>/snapshots/.'
     ```

**Step 3 — Targeted Odin fixture test (when capture is
infeasible).**

Use this when the proc has no return value, when its effects
are observed via change-factory mutations / history events
that the agent cannot serialise, or when the parent's call
site arguments depend on runtime state the agent's classpath
filtering cannot reach.

Write a focused Odin test in
`triplea/conversion/odin_tests/<topic>/`:

  1. Load a real `before.json` via `tc.load_game_state(SNAP_DIR,
     "<id>", "before.json")`. Pick the snapshot that drives the
     parent red proc — the dep must see the same fixture state
     it would see at runtime.
  2. **Capture the parent's call-site arguments** — instrument
     the parent proc temporarily to print the arg list (unit
     counts, territory names, player names, flags) at the point
     it calls the dep, run the failing snapshot once, copy the
     observed values into the test, then remove the trace.
  3. Build a `Default_Delegate_Bridge` the same way
     `test_server_game_run_next_step` does (matching messengers,
     `Delegate_Execution_Manager`, history writer) so dispatch
     paths through `getOutbound` work.
  4. Call the proc with those captured arguments.
  5. **Value-compare** outputs against a golden:
       - For procs returning a collection: assert specific
         elements / counts derived from the Java method body
         (or from the corresponding entries in `after.json` if
         the proc's output is a sub-tree of the post-state).
       - For procs with side effects on history / change /
         attachment state: snapshot the affected sub-tree before
         the call, call, snapshot again, and assert the diff
         matches the Java reference diff.
       - For procs returning a primitive: assert the exact
         expected value, not just `!= 0` or `> 0`.
  6. The golden expectation is derived from the Java source by
     reading the method top-to-bottom and tracing what it would
     produce on the captured inputs. Cite the Java line range in
     a one-line comment at the top of the test, e.g.
     `// Golden derived from MustFightBattle.java:1234-1267`.

  Side-effect-capture hooks (already wired into the codebase):

  - `dbg_add_change_capture_enabled` / `dbg_add_change_capture_changes`
    in `default_delegate_bridge.odin` — capture every
    `bridge.addChange(...)` call.
  - `dbg_history_capture_enabled` in `delegate_history_writer.odin`
    — capture history events.
  - `dbg_sound_capture_enabled` in `headless_sound_channel.odin`
    — capture sound channel emissions.

  See `dep_mark_attacking_transports/` for a worked example.

**Step 4 — If none of steps 1-3 is feasible, leave the proc
yellow.**

If the proc is only reachable through a currently-red snapshot
and no realistic fixture exists for it (e.g. it depends on
runtime state the loader can't reproduce yet), the picker will
eventually pop the parent red into `INVESTIGATE_PROC` and you
fix the parent in place. **Do NOT manufacture a green via a
crash-only smoke test.** The cost of a false green is a hidden
bug at the wrong layer, exactly the failure mode this whole
doctrine exists to prevent.

**Forbidden test shapes (auto-disqualifying):**

  - `testing.expect(t, true, "no crash")` after the call.
  - `expect(x != nil)` as the only assertion on a returned
    pointer.
  - `expect(len(out) > 0)` without comparing the contents.
  - Tests that drive only the headless / nil-channel / empty-
    list early-return path of the proc.
  - Tests whose inputs are synthesized from `nil` / zero values
    rather than loaded from a real `before.json` fixture.
  - Tests that exercise dispatch-shim wiring without exercising
    the concrete impl (vtable tests are only acceptable as
    proof of green when criterion (c) above is satisfied).

If you find yourself writing one of the above, stop and either
build the real fixture-driven test or leave the proc yellow.

1. **Identify the failing proc.** From the JSON diff (or panic
   stack frame), pinpoint the specific Odin proc whose output
   diverges from Java. Translate it back to its Java
   `method_key`.

2. **Look up its layer:**
   ```sh
   sqlite3 port.sqlite "SELECT method_key, method_layer, odin_file_path \
     FROM methods WHERE method_key = '<KEY>';"
   ```

3. **If `method_layer == 0`**, this is a leaf proc — no tracked
   dependencies. The bug must be inside its own body (or in a
   piece of harness data the proc reads). **Re-read the original
   Java method in full** at `java_file_path:java_lines`, diff
   against the Odin port line-by-line, and reconcile. Stay as
   faithful as humanly possible to the Java semantics; resist
   the urge to "improve" or "simplify". This is where
   conversion bugs hide.

4. **If `method_layer > 0`**, list every dependency:
   ```sh
   sqlite3 -separator '|' port.sqlite "
     SELECT d.depends_on_key, m.method_layer, m.odin_file_path
     FROM dependencies d
     JOIN methods m ON m.method_key = d.depends_on_key
     WHERE d.primary_key = '<KEY>'
     ORDER BY m.method_layer, d.depends_on_key;"
   ```

5. **Validate each dependency with its own targeted snapshot
   test.** The default snapshot harness exercises whole game
   steps, but per-proc snapshot fixtures may exist under
   `triplea/conversion/odin_tests/<proc>/snapshots/` (the
   bootstrap is capable of generating them — see
   `BOOTSTRAP_SNAPSHOTS=1 ./bootstrap.sh`). For each dependency:
   - If a per-proc snapshot exists, run it and check pass/fail.
   - If not, write a minimal call-site test that feeds the
     dependency's recorded inputs from `dependencies` /
     snapshot JSON and compares its output to the Java capture.
   - **Update `test_status` immediately:** call
     `scripts/mark_test_status.py <KEY> green` or `... red`
     based on the result. This is what populates the realtime
     dashboard and makes the drill-down auditable.

6. **Recurse.** For every dependency that fails its targeted
   test, repeat steps 2-5. The recursion is finite: each step
   strictly decreases `method_layer`, and layer 0 always
   terminates the descent.

7. **Termination cases:**
   - **Some dependency at layer 0 fails** → that's the bug.
     Fix it by re-porting from the original `.java` source.
     Re-test the dependency, then re-test its callers, walking
     back up the chain. As each proc's targeted test flips
     green, run `scripts/mark_test_status.py <KEY> green` so
     the dashboard reflects the cleared layer.
   - **All dependencies pass but the original proc still
     fails** → the bug is in the original proc's own body
     (its translation logic, not anything it calls). Fix that
     proc by re-porting from Java. Mark the proc red while
     debugging; flip it to green only after its own targeted
     test passes.

8. **Always re-port from `.java`, never write Odin from scratch.**
   The Java sources at `java_file_path` are the single source of
   truth. When fixing a proc, open the Java method, read it in
   full, and write the Odin port one statement at a time —
   preserving control flow, variable names (snake-cased),
   operator order, and short-circuit semantics. Do NOT
   "modernize" the code. Do NOT add or remove logging,
   defensive checks, or null-guards. Do NOT collapse Java's
   step-by-step assignments into Odin one-liners. Idiomatic
   sugar is fine for trivial accessors; **everything else must
   visually mirror the Java**.

9. **Triage harness vs. proc bugs honestly.** If the JSON diff
   shows that a Java field present in the snapshot is `nil` /
   missing in the Odin run, two equally valid causes exist:
     1. The proc that should populate it is buggy.
     2. The harness `json_loader` is failing to deserialize it.
   Always confirm via the dependency drill-down before editing
   anything. Editing the harness to mask a real proc bug, or
   editing a proc to compensate for a harness deserialization
   gap, both cause regressions later.

10. **Record findings.** After fixing a layer-0 root cause,
    write a one-line note in
    `/memories/repo/phase-c-state.md` summarizing the bug, the
    fix, and the snapshot ids that flipped green. This builds
    institutional memory across resume sessions.

---

## What to do when blocked

- **Value objects (Point, Color, BigDecimal).** Embed by value or
  use a primitive (BigDecimal → `f64`).
- **Functional interface.** Use Odin's `proc` type literal:
  `predicate: proc(^Unit) -> bool`.

  **Closure capture (Predicate / BiPredicate / Function).** When a
  Java lambda captures variables (e.g.
  `predicate.test(it) → other.test(it, captured_x)`), Odin's bare
  `proc` type cannot carry environment. Convention: pair the proc
  with a `rawptr` userdata, i.e. method signatures take
  `predicate: proc(rawptr, ^T) -> bool, predicate_ctx: rawptr`. A
  Predicate→BiPredicate (or similar) adapter heap-allocates a
  small ctx struct holding the inner predicate + its ctx, and
  passes that struct's pointer as `rawptr`. For non-capturing
  lambdas / method references, prefer the simpler
  `proc(^T) -> bool` form (no ctx needed). Adopt the rawptr form
  ONLY when the Java code actually captures.
- **Reflection.** Replace with explicit code.
- **Swing/AWT/UI.** Should not be flagged
  `actually_called_in_ai_test = 1`. If it is, the JaCoCo filter is
  letting UI through — recheck.

---

## Reporting

After every layer of Phase A or Phase B completes, post a summary:

```
Phase A — Layer N (structs): M/M done.
Newly implemented: <list>
Total Phase A progress: X/631
```

Do not start Phase B until Phase A reports 631/631.
