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

**Every individual entity conversion MUST be delegated to its own
subagent via the `runSubagent` tool.** The top-level (orchestrator)
agent does not write Odin code directly; it only:

1. Queries `port.sqlite` for the next batch of unimplemented entities.
2. Spawns one subagent per `.odin` file / entity / conversion task.
3. Collects the subagent's report, updates `is_implemented` in
   `port.sqlite`, and proceeds to the next batch.

Rules for subagent dispatch:

- **One subagent = one entity = one `.odin` file edit.** A subagent
  handling a struct touches only that struct's `odin_file_path`. A
  subagent handling a method touches only its owner struct's file
  (and only the proc it owns).
- **Use the `Explore` agent for read-only scouting only** (e.g. "find
  every field referenced by `GameStateJsonSerializer` for class `Foo`")
  — `Explore` cannot write files. Use the **default coding subagent**
  (omit `agentName` in the `runSubagent` call) for the actual
  translation, since only it has file-write tools.
- **Independent subagents may be dispatched in parallel** within the
  same layer (Phase A is order-free across structs; Phase B is
  order-free *within* a single `method_layer`). Never parallelize
  across method layers.
- **The subagent prompt must include**:
  - The exact `struct_key` or `method_key`.
  - Absolute paths to the Java source (`java_file_path`) and Odin
    target (`odin_file_path`).
  - A pointer to this file (`llm-instructions.md`) for the rules.
  - The instruction to return a one-line status report
    (`done` / `blocked: <reason>`) plus the list of any new
    cross-struct references introduced.
- **The orchestrator owns the database.** Subagents must NOT run
  `UPDATE structs/methods SET is_implemented = 1`. They report
  completion; the orchestrator records it. This keeps the tracker
  authoritative.
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

Pick the next method:

```sql
SELECT method_key, owner_struct_key, java_file_path, method_layer
FROM methods
WHERE is_implemented = 0
ORDER BY method_layer, method_key
LIMIT 1;
```

For each method:

1. Read the Java source at `java_file_path`, focused on `method_key`.
2. Open the owner struct's Odin file at `odin_file_path`.
3. Translate:
   - Instance `Foo.bar(int x)` → `foo_bar :: proc(self: ^Foo, x: i32) -> ...`.
   - Static `Foo.baz(...)` → `foo_baz :: proc(...)`.
   - Constructor `new Foo(...)` → `foo_new :: proc(...) -> ^Foo`.
   - `obj.method(args)` → `foo_method(obj, args)`.
   - Functional interfaces → Odin `proc` type literal.
4. **No reflection.** The Java side's reflection is read-only and
   not part of the port surface.
5. Mark method done:
   ```sql
   UPDATE methods SET is_implemented = 1 WHERE method_key = '...';
   ```

A method is `is_implemented = 1` only when:
- The proc body is real — no `// TODO`, no `panic("not impl")`, no
  logging-only stub.
- All called procs are themselves implemented (layer ordering
  guarantees this).

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
3. For each failure, find the field that differs in the JSON diff,
   trace back to the Odin code, fix. Do not edit the snapshots.

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
