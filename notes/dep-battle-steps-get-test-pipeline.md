# Per-method snapshot-test pipeline for `dep_battle_steps_get`

This file mirrors the repo memory at `/memories/repo/dep-battle-steps-get-test-pipeline.md`
so the same context is checked into the project tree.

## Components

### `triplea/conversion/odin_tests/test_common/proc_snapshot_marshal.odin` (~570 LOC)

- **Requires** `#+feature dynamic-literals` on line 1.
- **Public**: `marshal :: proc(v: any, pretty: bool, allocator) -> string`.
- Reflection-based, emits Jackson-shaped JSON:
  - `@class` from `Type_Info_Named.name`
  - `@id` / `@ref` for pointer cycles via per-call `Marshal_Ctx.seen` (`map[rawptr]int`)
  - Structured 2-deep identity stubs for ~40 `PRUNE_TYPES` (`Game_Data`,
    `Game_Map`, `Territory`, `Unit`, `Game_Player`, `Battle_State`,
    `Battle_Actions`, `Must_Fight_Battle`, all attachments, etc.)
  - Inline `using`-field flattening
  - Skip proc-fields and `game_data` back-pointers
  - Omit empty containers
- Uses `reflect.iterate_map(any, ^int)`.

### `triplea/conversion/odin_tests/test_common/proc_snapshot_compare.odin`

- **Public**: `compare_proc_snapshot :: proc(odin_json, java_json: string) -> string`
  returning `""` on match or first-divergence JSON-pointer path.
- Canonicalization rules:
  - Java FQCN → snake_case (`BattleStep$StepDetails` ≡ `Battle_Step_Step_Details`)
  - camelCase fields ≡ snake_case
  - `null` ≡ absent ≡ empty container
  - ints ≡ floats (via JSON parse coercion)
  - key order ignored
  - array order respected
  - Follows `@ref` via per-side `@id` table

### `triplea/conversion/odin_tests/test_common/proc_snapshot_receiver.odin`

- **Public**: `load_battle_steps_receiver(snapshot_dir, id, data) -> (^Battle_Steps, err: string)`.
- Looks up:
  - attacker / defender by name via `data.player_list.players`
  - `battle_site` by name via `data.game_map.territory_lookup`
  - units by uuid via `game.units_list_get(data.units_list, id)`
- Allocates `^Must_Fight_Battle` and populates the `Abstract_Battle` layer
  scalars (`battleId`, `headless`, `isAmphibious`, `isOver`, `round`,
  `maxRounds`, `battleType`, etc.) from `before-self.json`'s `battleState`
  object.
- `Battle_State` and `Battle_Actions` are zero-size sentinel structs;
  cast `^Must_Fight_Battle` to either.
- Calls `backfill_game_data_refs(data)` to set
  `Game_Data_Component.game_data` on every loaded player / territory /
  unit (the existing snapshot loader leaves these nil, breaking every
  `*_get_data_or_throw` call site).

## Tests

In `triplea/conversion/odin_tests/dep_battle_steps_get/`:

- `test_marshal_smoke.odin` — verifies `@class`/`@id`/`@ref` emission on
  a 2-element `Battle_Step_Step_Details` list with shared `^Battle_Step`.
- `test_compare_smoke.odin` — 8 unit tests for the comparator.
- `test_compare_real_golden.odin` — round-trips a real 6034-line
  Java-side `after-return.json` and verifies a one-byte mutation is
  detected.
- `test_battle_steps_get.odin` — integration test for snap 0001. Loads
  game data, builds receiver, runs an instrumented per-step harness
  that constructs each of the 24 step subtypes one at a time and probes
  `get_order` / `get_all_step_details` so a panic identifies exactly
  which subtype fails.

## Current blocker

Snap 0001 panics with `SIGSEGV` during `DefensiveAaFire.get_all_step_details`
inside `firing_group_splitter_aa_apply` (step #1 of 24).

```
[00] OffensiveAaFire — get_order... AA_OFFENSIVE — get_all_step_details... 0 details:
[01] DefensiveAaFire — get_order... AA_DEFENSIVE — get_all_step_details... <SIGSEGV>
```

`firing_group_splitter_aa_apply` reads:

- `data.technology_frontier` — left nil by the loader
- `tech_attachment` on `opp_player` — partially populated
- `unit_get_unit_attachment` on each unit — `unit.type.unit_attachment`
  back-reference is nil

Same root cause documented in the existing repo memories:

- "GamePlayer.game_data_component.game_data is nil in snapshot harness"
- "change_attachment_change_perform body must stay no-op until I_Attachment vtables are wired"

## Remaining work

1. Either fix the loader's nil-cascade in `json_loader.odin`
   (technology_frontier loading + tech_attachment population +
   attachment vtables + unit_attachment.type wiring) — also unblocks
   the 18 known_broken Phase B-2 wirings, OR
2. Synthesize minimal placeholder `Tech_Frontier` / attachments in
   `load_battle_steps_receiver` for this test alone.

Once snap 0001 passes byte-for-byte:

3. Widen the integration test to all 190 captured goldens.
4. Use first-diff output to bisect the wrong-length-step-list bug
   (Odin currently emits 5 steps, Java expects 8).

## Key facts

- `Battle_Steps :: struct { battle_state: ^Battle_State, battle_actions: ^Battle_Actions }` — the receiver is just two pointers.
- `battle_steps_get` calls `battle_step_get_all(state, actions)` which constructs all 24 step subtypes unconditionally; subtypes filter themselves out in `get_all_step_details` by returning an empty list when `_valid` returns false.
- `Battle_State` / `Battle_Actions` are sentinel `struct {}` types; all method dispatch casts to `^Must_Fight_Battle` (per the "Game_State interface dispatchers must bypass proc-field vtable" memory).
- Ordering in `battle_step_get_all` matches Java's `List.of(...)` literal verbatim (24 entries from `OffensiveAaFire` through `CheckStalemateBattleEnd`).

## Snap 0001 expected output

```
8 elements:
  [0] Russians fire             RollDiceStep
  [1] Germans select casualties SelectCasualties
  [2] Germans notify casualties MarkCasualties
  [3] Germans fire              RollDiceStep
  [4] Russians select casualties SelectCasualties
  [5] Russians notify casualties MarkCasualties
  [6] Remove casualties         ClearGeneralCasualties
  [7] Russians withdraw?        OffensiveGeneralRetreat
```

Russians (attacker) attacking Germans (defender) at Belorussia, round 1, 8 attacking units vs 3 defending units.
