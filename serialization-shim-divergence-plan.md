# Game_Data deep clone plan — snap 0013/0014 unblock

**Workspace:** `/home/caleb/todin`
**Last updated:** 2026-05-07 (session 5)
**Baseline:** 50/52 snapshots PASS. Reds: snap 0013 (`Russians.PUs 24 != 0`),
snap 0014 (`unit.alreadyMoved 0 != N`).

## TL;DR — current understanding (verified, reproducible)

The snap 0013/0014 failures, the missing clone, and the json_loader's
incomplete `Named_Kind` discriminators are **one tightly coupled
problem**. They cannot land piecewise:

1. **`game_data_utils_clone_game_data` returns nil today.** That alone
   doesn't break snap 0013 — `pro_purchase_ai_purchase` early-returns
   on `data_copy == nil`, so PUs stay at 24 (which is what the snap
   expects... no, sorry, expects 0). The PUs-stay-at-24 is the
   expected Java behavior with a working AI. So clone IS needed.
2. **Enabling shallow clone exposes Layer N+1 bugs.** With
   `clone^ = data^`:
   - Layer 5 (sequence cursor leak): FIXED via save/restore defers in
     `abstract_pro_ai_purchase`.
   - move_del.bridge/player leak: FIXED via save/restore defers.
   - `Pro_Purchase_Option_Map` is empty for every player because
     json_loader doesn't set `ut.named.kind = .Unit_Type`. Adding
     the kind assignment unlocks AI logic for ~10 snapshots that
     previously had a no-op AI; their expected-state JSONs (which
     assumed no-op AI) now mismatch.
   - AI's combat-move sim mutates `Unit.already_moved` on the
     SHARED unit graph (no per-unit clone) → snap 0014 perturbs.
3. **Per-unit deep clone is the hard prerequisite.** Without it, no
   incremental fix can land — every "fix the obvious json_loader
   gap" pull regresses 8+ snaps because the AI's sim leaks state
   into the harness's pre-state read.

## What's already landed (DO NOT re-discover)

In [odin_flat](odin_flat/) and [triplea/conversion/odin_tests/test_common](triplea/conversion/odin_tests/test_common/) /
[templates/odin_test_common](templates/odin_test_common/):

1. `json_loader self_relation` → ALLIED archetype (snap 0013 pre-req).
2. `json_loader gd.state = game_data_state_new(gd)` (tech_tracker pre-req).
3. `json_loader deserialize_player`: sets game_data back-ref on
   `default_named.game_data_component.game_data` AND
   `resources.game_data_component.game_data`.
4. `abstract_pro_ai_purchase` inline bridge assignment (replaces broken
   `i_delegate_bridge_get_game_player` cast-dispatch).
5. `abstract_ai` purchase_delegate vtable wrap via
   `purchase_delegate_to_i_purchase_delegate`.
6. `abstract_pro_ai_purchase` save/restore defers:
   - `sequence.current_index` / `sequence.round`
   - `move_del.abstract_delegate.bridge` / `.player`

   These defers are dead under the nil-return clone shim but ready
   for when a real clone (or shallow clone) lands.

## What `game_data_utils_clone_game_data` looks like today

[odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin) —
returns nil. Java-faithful shim (`Object_Input_Stream` has no
`readObject` semantics in Odin).

## Things proven false / debunked

Recorded so they don't get re-tried:

- **"`find_purchase_territories` returns 0 for Russians"** — false.
  Returns 3 (Caucasus, Karelia S.S.R., Russia). Verified
  2026-05-07 with PROBE_FPT.
- **"`pro_purchase_ai_purchase` runs but produces 0 rules because of
  pure AI-decision logic"** — false. Returns 0 rules because
  `Pro_Purchase_Option_Map` is empty because `pro_purchase_option_map_new`
  filters every rule on `kind != .Unit_Type` and json_loader
  never sets `ut.named.kind = .Unit_Type`.
- **"Cloning just `Player_List + Resource_Collection` is enough to
  unblock snap 0013"** — false. Required scope is full deep clone.
- **"The Unit_Type kind discriminator fix in json_loader is a benign
  infrastructure patch"** — false. Causes 8 snap regressions because
  it unlocks AI logic across many snapshots whose expected-state
  JSONs assumed a no-op AI.
- **"Setting game_data back-refs on Territory/Unit/Territory_Attachment
  in json_loader is benign"** — false (when paired with kind fix).
  Same regression pattern as above.
- **"Embedding I_Delegate_Bridge in Default_Delegate_Bridge with
  proc-field priority dispatch is a clean infrastructure fix"** —
  false. Perturbs snap 0014 via offset shifts. Use the inline
  bridge-assignment workaround in `abstract_pro_ai_purchase`
  instead (already landed).

## Quick-reference reproduction

```sh
cd /home/caleb/todin/triplea && \
  /nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/bin/odin test \
    conversion/odin_tests/server_game_run_next_step \
    -collection:flat=/home/caleb/todin/odin_flat \
    -collection:test_common=conversion/odin_tests/test_common \
    -define:ODIN_TEST_TRACK_MEMORY=false 2>&1 | grep -E "FAILED|Finished" | tail -10
```

Expected current output (50/52):
```
Snapshot 0013 FAILED: players.Russians.resources[PUs]: 24 != 0
Snapshot 0014 FAILED: units[...].alreadyMoved: 0.000 != N.000
Finished 1 test in ~0.6s. The test failed.
```

To enable shallow clone for drilling (paired with the existing
defers — DO NOT remove the defers):

```odin
// odin_flat/games__strategy__engine__framework__game_data_utils.odin
game_data_utils_clone_game_data :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> ^Game_Data {
    _ = options
    if data == nil { return nil }
    clone := new(Game_Data)
    clone^ = data^
    return clone
}
```

Probe pattern: `when #config(NAME, false) { fmt.eprintf(...) }`,
enable with `-define:NAME=true`.

## The plan: land deep clone + kind fix + back-refs together as one PR

These three must land atomically. The order of work within the PR:

### Step 1 — Implement the deep clone

[odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin)
`game_data_utils_clone_game_data`. Strategy:

- Shallow-copy the `Game_Data` header (preserves `Game_State` vtable
  wiring already done by `game_data_v_*`).
- Walk a "what to clone" list, allocating fresh nodes, building a
  `map[rawptr]rawptr` old→new translation table.
- Walk a "what to relink" list, rewriting every cross-reference
  pointer to the new node by table lookup.
- Walk a "back-ref restore" pass that sets every cloned object's
  `game_data_component.game_data = clone`.

#### Deep-clone scope (must clone)

| Type | Why |
|---|---|
| `Game_Data` | header |
| `Player_List` + every `Game_Player` | name/identity preserved |
| `Resource_Collection` per player + `resources` map | mutated by purchase sim |
| `Unit_Collection` per player (`units_held`) | unit list mutated |
| `Units_List` + every `Unit` | `already_moved`, `hits`, `submerged` etc. mutated by combat-move sim |
| `Game_Map` + every `Territory` | unit_collection.units mutated, owner reassigned |
| `Territory.unit_collection` per territory | units added/removed |
| `Game_Sequence` + every `Game_Step` | cursor + round mutated |
| `delegates` map | each entry stores `^I_Delegate` over a concrete subtype (Move_Delegate, Purchase_Delegate, Battle_Delegate, etc.) — needs per-concrete-type clone (switch on name or `clone` slot in vtable) |
| `Game_Data_State` + `tech_tracker` | mutated by tech advances |
| `Game_Properties` map | mutated by AI |

#### Stays shared (immutable static data)

| Type | Why safe |
|---|---|
| `Resource_List` + every `Resource` | static after load |
| `Unit_Type_List` + every `Unit_Type` + `Unit_Attachment` | static |
| `Production_Frontier_List` + frontiers + `Production_Rule` | static |
| `Repair_Frontier_List` + repair rules | static |
| `Relationship_Type_List` + types | static |
| `Technology_Frontier` + `Tech_Advance` | static |
| `Game_Map.connections` (territory adjacency) | static topology |
| `Alliance_Tracker`, `Relationship_Tracker` | snapshot-immutable |
| `History` | not exercised by snapshot harness |
| `loader` (`I_Game_Loader`) | static |

#### Cross-reference relinks

| Field | Lookup key |
|---|---|
| `Unit.owner` | Game_Player by name |
| `Unit.original_owner` | Game_Player by name |
| `Unit.transported_by` | Unit by UUID |
| `Unit.unloaded_to`, `Unit.originated_from` | Territory by name |
| `Territory.owner` | Game_Player by name |
| `Territory.territory_attachment.original_owner` | Game_Player by name |
| `Game_Step.player_id` | Game_Player by name |
| `Player_List.null_player` | Game_Player by name ("Neutral") |
| `Resource_Collection.resources` map keys | Resource — pointer-keyed map; share Resource pointer because `Resource_List` is shared, so keys can stay |
| `Pro_Purchase_Territory.player` (if present in game_data) | Game_Player by name |

Note: `Resource_Collection.resources: map[^Resource]i32` — keys
remain valid because `Resource_List` is shared. Same for any
`map[^Unit_Type]_` since `Unit_Type_List` is shared.

For `map[^Unit]X` and `map[^Territory]X` and `map[^Game_Player]X`:
must rebuild key-by-key by name/UUID lookup against the cloned
master lists.

#### Back-ref restore pass

For every cloned object that embeds `using game_data_component:
Game_Data_Component`, set `obj.game_data_component.game_data = clone`.
The list is at least: `Player_List`, every `Game_Player`,
`Resource_Collection` per player, `Unit_Collection` per player,
every `Unit`, `Game_Map`, every `Territory`, `Territory_Attachment`,
`Game_Sequence`, every `Game_Step` (if it has the embedding —
verify), `Game_Data_State`.

#### Delegate clone

Each entry in `data.delegates: map[string]^I_Delegate` is actually a
concrete subtype that extends past `sizeof(I_Delegate)`. Cannot
shallow-copy via `^I_Delegate`. Options:

- **Switch on delegate name** (cheap, ~10 cases):
  `move_delegate_clone`, `purchase_delegate_clone`,
  `battle_delegate_clone`, etc. — each does `new(Concrete_Type);
  clone^ = original^` then resets the vtable proc-fields by calling
  the original `_new` constructor's vtable wiring inline (or by
  factoring a `_v_install` proc).
- **Add a `clone` proc-field to I_Delegate vtable** (more invasive).

Pick the switch approach for the first cut. `Abstract_Delegate.bridge`
and `.player` are already protected by save/restore defers in
`abstract_pro_ai_purchase`, so the cloned delegate doesn't need its
own bridge — but its concrete state fields (`Purchase_Delegate.pending_production_rules`,
`Move_Delegate.moves_to_undo`, etc.) must be copied so the AI sim's
mutations don't leak.

### Step 2 — Land the json_loader kind discriminator fix

In both [triplea/conversion/odin_tests/test_common/json_loader.odin](triplea/conversion/odin_tests/test_common/json_loader.odin)
and [templates/odin_test_common/json_loader.odin](templates/odin_test_common/json_loader.odin):

```odin
deserialize_unit_type :: proc(obj: json.Object) -> ^game.Unit_Type {
    ut := new(game.Unit_Type)
    ut.named.base.name = get_string(obj, "name")
    ut.named.kind = .Unit_Type   // <-- ADD THIS
    if ua_obj, ok := get_object(obj, "unitAttachment"); ok {
        ut.unit_attachment = deserialize_unit_attachment(ua_obj)
    }
    return ut
}
```

Audit every other `deserialize_*` proc that allocates a `Named_Attachable`-
descended type and confirm `kind` is set:

- `deserialize_player` — sets `.Game_Player` ✅
- `deserialize_territory` — sets `.Territory` ✅
- `deserialize_unit_type` — MUST add `.Unit_Type`
- `deserialize_resource` (if exists) — must set `.Resource`
- `deserialize_production_rule` (if exists) — must set `.Production_Rule`
- Anything else with a `named.kind` field discoverable via grep

### Step 3 — Add missing game_data back-refs in json_loader

Once deep clone exists, the AI sim runs against the clone and
mutates clone-only state. The original `data` (which the harness
reads pre-state from) is unmutated. So back-refs on the original
become safe to add:

- `deserialize_territory`: `t.named_attachable.default_named.game_data_component.game_data = gd`
- `deserialize_unit`: `u.game_data_component.game_data = gd`
- `deserialize_territory`'s territory_attachment branch:
  `ta.default_attachment.game_data_component.game_data = gd`
- Spot-check every other `new(game.X)` in json_loader where `X`
  embeds `Game_Data_Component`.

### Step 4 — Regenerate snapshot expected-states (if needed)

Run the suite. Some snaps may now PASS that previously failed
in expected ways; some may FAIL with new expected-vs-actual diffs
that reflect the AI's now-active turn. For each new failure:

- Verify the actual matches the Java reference behavior (run the
  same scenario through the Java game-core to confirm).
- If actual is correct, regenerate the snapshot's `after.json`.
- If actual is wrong, drill the next layer.

### Step 5 — Update divergence policy

Once the clone lands and snap 0013 PASSES, add to
[llm-instructions.md](llm-instructions.md):

> **Serialization-shim divergence (orchestrator-owned).**
> JVM-native reflective serialization (`ObjectOutputStream`,
> `ObjectInputStream`, `writeObject`, `readObject`, `Serializable`)
> has no Odin equivalent. Where Java code uses these to clone or
> transmit `Game_Data`, the Odin port substitutes a
> functionally-equivalent in-memory deep-clone (see
> `game_data_utils_clone_game_data`). The byte-array intermediate
> is a diagnostic-only side effect; callers depend on the resulting
> `^Game_Data`, not the bytes.
>
> **Do not "fix" this back to Java-faithful.** No equivalent runtime
> exists. When porting a Java method that calls
> `writeObject`/`readObject`, treat those calls as opaque and route
> through `game_data_utils_clone_game_data` (or the
> `translateIntoOtherGameData` analog) instead of trying to model
> `Object_Output_Stream` semantics.

## Implementation pattern (suggested)

```odin
// odin_flat/games__strategy__engine__framework__game_data_utils.odin

@(private="file")
Clone_Ctx :: struct {
    table: map[rawptr]rawptr,  // old -> new
    src:   ^Game_Data,
    dst:   ^Game_Data,
}

@(private="file")
clone_remember :: proc(ctx: ^Clone_Ctx, old: rawptr, new: rawptr) {
    ctx.table[old] = new
}

@(private="file")
clone_lookup :: proc(ctx: ^Clone_Ctx, old: rawptr) -> rawptr {
    if old == nil { return nil }
    if v, ok := ctx.table[old]; ok { return v }
    return old  // shared (static) — pass-through
}

game_data_utils_clone_game_data :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> ^Game_Data {
    _ = options
    if data == nil { return nil }

    ctx: Clone_Ctx
    ctx.src = data
    ctx.table = make(map[rawptr]rawptr)
    defer delete(ctx.table)

    // 1. Allocate clone, shallow-copy header.
    clone := new(Game_Data)
    clone^ = data^
    ctx.dst = clone
    clone_remember(&ctx, rawptr(data), rawptr(clone))

    // 2. Clone Player_List + Game_Players + Resource_Collections + Unit_Collections.
    // 3. Clone Game_Map + Territories + per-territory Unit_Collections.
    // 4. Clone Units_List + every Unit.
    // 5. Clone Game_Sequence + Game_Steps.
    // 6. Clone delegates map + per-delegate concrete switch.
    // 7. Clone Game_Data_State.
    // 8. Relink pass: walk the clone, rewrite cross-reference pointers via clone_lookup.
    // 9. Back-ref pass: set game_data_component.game_data = clone on every cloned node.

    return clone
}
```

Estimated size: 400–800 LOC of straightforward boilerplate. Per-type
clone procs (`game_player_clone(src, ctx) -> ^Game_Player`, etc.)
are independently fan-outable to subagents once the skeleton lands.

## Acceptance test

After deep clone + kind fix + back-refs land:

- snap 0013 PASSES (`Russians.PUs == 0`)
- snap 0014 PASSES (`alreadyMoved` matches expected for every unit)
- All previously-passing snaps (0001–0012, 0015–0052 except 0013/0014)
  remain green
- No segfault on any snap
- `mark_test_status.py` can flip
  `proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase` and
  `proc:games.strategy.engine.framework.ServerGame#runNextStep` to green

## Cross-references

- Session memory: [/memories/session/triplea-port-progress.md](memories/session/triplea-port-progress.md)
- Phase C state: [/memories/repo/phase-c-state.md](memories/repo/phase-c-state.md)
- Java source under analysis: [triplea/game-app/game-core/src/main/java/games/strategy/engine/framework/GameDataUtils.java](triplea/game-app/game-core/src/main/java/games/strategy/engine/framework/GameDataUtils.java)
- Phase C doctrine: [llm-instructions.md](llm-instructions.md) §"Layered drill-down debugging"
- Existing landed defers / inline workarounds: [odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin](odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin) `abstract_pro_ai_purchase`
- Game_Data struct decl: [odin_flat/games__strategy__engine__data__game_data.odin](odin_flat/games__strategy__engine__data__game_data.odin)
- Pro_Purchase_Option_Map ctor (the kind-filter site): [odin_flat/games__strategy__triplea__ai__pro__data__pro_purchase_option_map.odin](odin_flat/games__strategy__triplea__ai__pro__data__pro_purchase_option_map.odin) `pro_purchase_option_map_new`
