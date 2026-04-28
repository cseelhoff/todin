# LLM porting instructions

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

3. **Pointer-based data layout. No `*_Id` types.** Every cross-struct
   reference is a raw `^Foo` pointer. Odin's package-level forward
   declarations resolve all cycles automatically — `^Player` inside
   `Territory` is fine even though `Player` is defined later in
   another file.

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
