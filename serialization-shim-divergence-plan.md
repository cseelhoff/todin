# Serialization-shim divergence plan — Game_Data clone

> **NEW SESSION? START HERE.** This file is the resume prompt for Stage 2
> work. The repo workspace is `/home/caleb/todin`. After reading this
> file end-to-end, also read:
>   1. [/memories/session/triplea-port-progress.md](/memories/session/triplea-port-progress.md) — full session history
>   2. [llm-instructions.md](llm-instructions.md) — porting rules
>   3. The Java source at the path linked below in **Java side**
>   4. The current Odin shim at
>      [odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin)
>
> Then jump to **Stage 2 implementation guide** below. Skip Stage 1 — it
> is already complete (and reverted).

## Quick-reference reproduction commands

```sh
# Run snapshot suite, summarize fails (canonical baseline check):
cd /home/caleb/todin/triplea && \
  /nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/bin/odin test \
    conversion/odin_tests/server_game_run_next_step \
    -collection:flat=/home/caleb/todin/odin_flat \
    -collection:test_common=conversion/odin_tests/test_common \
    -define:ODIN_TEST_TRACK_MEMORY=false 2>&1 | \
  grep -E "FAILED:|passed|failed" | tail -10

# Current expected baseline output:
#   Snapshot 0013 FAILED: players.Russians.resources[PUs]: 24 != 0
#   Snapshot 0014 FAILED: units[...].alreadyMoved: 0.000 != 2.000
#   Finished 1 test in ~0.6s. The test failed.

# Add probes via -define:PROBE_NAME=true; pattern in Odin source:
#   when #config(PROBE_NAME, false) { fmt.eprintf("[PROBE] ...\n", ...) }
```

## Status header

**Status:** STAGE 1 COMPLETE (probe only; reverted). Stage 2 NOT YET STARTED.
**Owner:** orchestrator (this is infrastructure, not a TripleA entity port)
**Blocker:** snap 0013 (`Russians.PUs 24 != 0`) — `AbstractProAi.purchase` early-returns
because `abstract_pro_ai_copy_data` returns nil because
`game_data_utils_clone_game_data` returns nil.
**Java side:** [GameDataUtils.cloneGameData](triplea/game-app/game-core/src/main/java/games/strategy/engine/framework/GameDataUtils.java#L21-L27)
relies on JVM-native `ObjectOutputStream`/`ObjectInputStream` reflective serialization,
which has no Odin equivalent. The current Odin shim is structurally faithful but
returns nil because `Object_Input_Stream` has no `readObject` semantics.

## Decision: diverge from 1:1 Java translation at `game_data_utils_clone_game_data`

We diverge here, not deeper, because:
- `gameDataToBytes` / `createGameDataFromBytes` exist solely to round-trip through
  the JVM serializer; there is no other reason to materialize a byte array.
- The functional contract callers depend on is "give me an independent ^Game_Data
  I can mutate without affecting the original" — *not* "give me bytes."
- A single divergence site is the smallest blast radius.

This is a **third orchestrator-owned infrastructure category**, alongside JDK shims
and json_loader patches. To be added to [llm-instructions.md](llm-instructions.md)
and [resume-prompt.md](resume-prompt.md) as "Serialization-shim divergence" so
future agents don't "fix" it back to Java-faithful.

## Three-stage prototype, simplest first

### Stage 1: shallow-clone probe — COMPLETE (reverted)

**Result (2026-05-07):** Replacing the body with a shallow memcpy
(`clone := new(Game_Data); clone^ = data^`) caused snap 0013 to
**SIGSEGV** during the AI's simulation walk (down from
"PUs=24 assertion fail"). This is a *regression* — the assertion
failure was deterministic and 50/52 baseline was preserved; the segfault
crashes the whole test binary at snap 0013, leaving 0014–0052 unrun.

### Stage 2-lite probe (2026-05-07, session 2) — COMPLETE, reverted

Tried: clone player_list + per-player Game_Player + per-player
Resource_Collection, share everything else. Iterated PROBE_AI_LOOP
through `abstract_pro_ai_purchase` → `pro_purchase_ai_purchase`.

**Findings (all reverted to keep 50/52 baseline):**

1. **Cloning Game_Players breaks pointer equality with `Game_Step.player_id`.**
   `abstract_pro_ai_get_game_steps_for_player` filters via
   `game_player == game_step_get_player_id(step)` against the SHARED
   step. Cloned `player_copy` ≠ original `player` → returns empty
   list → AI loop never runs purchase. Must either share Game_Player
   pointers OR also clone Game_Sequence and re-link
   `Game_Step.player_id`.

2. **Discovered I_Delegate_Bridge dispatcher bug.** `i_delegate_bridge_get_*`
   blindly do `cast(^Default_Delegate_Bridge)self`, ignoring proc-fields.
   The AI's `bridge := new(I_Delegate_Bridge)` (with proc-fields wired
   for `get_data`, `get_game_player`, `add_change`) cannot be dispatched
   safely. **Tried fix:** embed
   `using i_delegate_bridge: I_Delegate_Bridge` as first field of
   `Default_Delegate_Bridge` + add proc-field-priority checks in
   dispatchers. **Result:** unblocks AI bridge construction (no
   segfault), but PERTURBS snap 0014 from `alreadyMoved 0!=2` to
   `0!=3` — some downstream code reads laundered struct fields and
   sizeof(I_Delegate_Bridge) shift broke offsets. Reverted.

3. **Even with shallow share + dispatcher fix, snap 0014 was
   perturbed independently** because
   `abstract_delegate_set_delegate_bridge_and_player_no_websocket(
       &move_del.abstract_delegate, bridge)` MUTATES the shared
   `move_del.bridge` field. `move_del` comes from
   `data.delegates[name]` which is shared. **A real clone must clone
   delegates too.**

4. **AI's `pro_purchase_utils_find_purchase_territories` returns 0
   for Russians** even when given the full graph. Russians own 11
   territories but the function filters them all out. Either
   `ra.placement_any_territory` is false and no factory match, OR
   the move filter rejects. **Separate logical bug** — even a
   perfect clone wouldn't fix snap 0013 by itself.

5. **Pivot claim CONFIRMED.** `pro_purchase_ai_purchase(...&data.game_state)`
   at `abstract_pro_ai.odin` line ~701 uses ORIGINAL `data`, not
   `data_copy`. Clone is for simulation only.

**Conclusions for Stage 2 (full):**
- Cloning must include: Game_Data, player_list, per-player
  Game_Player + Resource_Collection, **delegates map**, **Game_Sequence**.
  Sequence steps reference Game_Players → after cloning, must
  re-link each step's `player_id` to the cloned player by name lookup.
- Must fix `Default_Delegate_Bridge` embed perturbation BEFORE
  re-applying it: investigate WHY sizeof(I_Delegate_Bridge) shift
  broke snap 0014. Find offending site (probably some code reads
  Default_Delegate_Bridge fields via offset-arithmetic or via
  `cast(^I_Delegate_Bridge)default_bridge_ptr` followed by direct
  field access not via dispatcher). Fix it, re-apply embed.
- Plan to also debug `find_purchase_territories` independently
  (snap 0013 will still fail without that fix).

### Stage 2 (was: CBOR + relink) — re-scoped after Stage 2-lite findings

**Conclusion:** AI's `abstract_pro_ai_purchase` mutates through the
shared sub-pointers (likely `Player_List`, `Game_Map.territories`,
`History`, or one of the per-player resource maps). A shallow clone
sharing inner state is incompatible with the simulation's mutation
patterns. Stage 2 (independent allocations for the mutated subgraph)
is required.

**Reverted to:** the Java-faithful nil-returning shim. Baseline is back
to 50/52 (snaps 0013 + 0014 both assertion-fail, no segfault).

**Diagnostic value retained:** we now know the simulation actually
needs a **functionally-independent graph** for the subset of fields it
mutates. We do NOT need to clone immutable static data (Unit_Type,
Resource definitions, etc.) — sharing those is fine.

### Stage 2: CBOR + relink post-pass (~half day if everything cooperates)

**Stop and ask if Stage 2 hits >1 day** — that's a signal to switch to Stage 3.

## Stage 2 implementation guide (start here in fresh session)

### Recommended approach: Stage 2-lite first, then expand

Given Stage 1's segfault told us the AI needs an independent graph but
NOT necessarily of every field, try a **scoped deep-clone** before the
full CBOR investment:

**Step 1: Identify what AI actually mutates.** Read
[odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin](odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin)
`abstract_pro_ai_purchase` (line ~534) and follow each call. Specifically
trace what mutates `data_copy` between line ~600 (`data_copy := ...`) and
the `pro_purchase_ai_purchase` call. Likely candidates:
  - `pro_data_initialize_simulation(self.pro_data, self, data_copy, player)`
  - `game_step_get_*` walks
  - any `i_delegate.start(...)` dispatched on the clone's delegates

**Step 2: Try minimal clone — just allocate independent top-level struct + Player_List + History.**
Most of Game_Data's fields are immutable static data (Unit_Type_List,
Resource_List, Production_Rule_List, Game_Map territories' static
attrs, etc.) — the AI sim should be safe sharing those. Likely
mutated: `players[*].resources`, `units_list`, `delegates`, maybe
`history`. Start with cloning ONLY the player resource maps and see
if snap 0013 advances.

```odin
game_data_utils_clone_game_data :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> ^Game_Data {
    _ = options
    if data == nil { return nil }
    clone := new(Game_Data)
    clone^ = data^
    // Independent player_list with independent resource maps:
    if data.player_list != nil {
        new_pl := new(Player_List)
        new_pl^ = data.player_list^
        new_pl.players = make(map[string]^Game_Player)
        for k, gp in data.player_list.players {
            new_gp := new(Game_Player)
            new_gp^ = gp^
            // Clone the resource map (PUs is here):
            new_gp.resources_held = make(map[^Resource]i32)
            for r, n in gp.resources_held { new_gp.resources_held[r] = n }
            new_pl.players[k] = new_gp
        }
        clone.player_list = new_pl
    }
    return clone
}
```

(field names are guesses — verify against the actual struct in
[odin_flat/games__strategy__engine__data__player_list.odin](odin_flat/games__strategy__engine__data__player_list.odin)
and `game_player.odin` first).

**Step 3: Run snap suite.** Three outcomes:
- Still segfault → which field? Add probe before the segfault site,
  identify the field, clone that one too. Iterate.
- Still PUs=24 → AI's purchase output writes back through the
  ORIGINAL `data` (not the clone). Look at
  `pro_purchase_ai_purchase(self.purchase_ai, purchase_delegate, &data.game_state)`
  — note it passes `&data.game_state`, NOT the clone. The clone may
  exist purely to let the simulation evaluate hypothetical futures
  without affecting the original; the actual purchase is dispatched
  via `purchase_delegate` against the live `data`. In that case the
  clone could be a no-op and we should look at WHY the purchase
  delegate isn't actually purchasing anything.
- New diff → progress! Keep drilling.

### If Stage 2-lite doesn't work: full CBOR + relink

**Idea:** use Odin stdlib `core:encoding/cbor` for the deep-walk, then mechanically
rebind cross-list pointers by name using the same patterns `json_loader.odin` already
implements.

**Implementation sketch** (place in
[odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin)):

```odin
import "core:encoding/cbor"

game_data_utils_clone_game_data :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> ^Game_Data {
    if data == nil { return nil }
    bytes, marshal_err := cbor.marshal(data^)
    if marshal_err != nil { return nil }
    defer delete(bytes)
    clone := new(Game_Data)
    if unmarshal_err := cbor.unmarshal(bytes, clone); unmarshal_err != nil {
        free(clone); return nil
    }
    game_data_utils_relink_clone(clone)
    return clone
}
```

**Relink pass** (`game_data_utils_relink_clone`): walk the cloned `Game_Data` and
replace cross-list `^Game_Player`, `^Territory`, `^Unit_Type`, `^Resource`,
`^Production_Rule`, `^Production_Frontier`, `^Repair_Frontier`,
`^Relationship_Type`, `^Technology` with their counterparts in the cloned master
lists (looked up by name). Reuse json_loader's helpers. The pattern is identical
to last session's `productionFrontier` post-pass at
[json_loader.odin](triplea/conversion/odin_tests/test_common/json_loader.odin#L437)
but applied across every cross-reference category.

**Risks / caveats (verified or anticipated):**
- **Proc-typed fields (vtables):** every "interface" struct in odin_flat/
  has proc fields (e.g. `I_Delegate.start: proc(^I_Delegate)`,
  `Game_State.get_map: proc(^Game_State) -> ^Game_Map`). CBOR cannot
  serialize procs. Mitigation: marshal will likely error or write
  zero; on unmarshal these fields are nil. Either:
    (a) tag with `cbor:"-"` and re-call constructors in relink, OR
    (b) raw-copy proc fields from original to clone after unmarshal.
  Option (b) is simpler — proc values are just function pointers;
  copying them by hand is safe.
- **Cycles:** Game_Data has heavy back-references. Examples confirmed:
  `Player_List.data → Game_Data` (back-ref);
  `Game_Map.data → Game_Data`; many attachables hold
  `^Game_Data_Component` whose embedded `game_data` points back. CBOR
  stdlib does NOT handle cycles. Stack overflow on marshal is the
  expected failure mode. Mitigation: tag every "back-ref to Game_Data"
  field with `cbor:"-"` and rebind in a single post-pass that walks
  the clone and writes `obj.game_data_component.game_data = clone`
  on every Game_Data_Component-embedding object (that pattern already
  exists implicitly in json_loader; see repo memory note about
  `GamePlayer.game_data_component.game_data is nil`).
- **Maps with pointer keys** (`map[^Resource]i32`, `map[^Unit]struct{}`,
  `map[^Game_Player]struct{}`): CBOR will marshal these as some
  representation but the keys are pointers, so unmarshal gives back
  pointers into freshly-allocated stand-in objects, not the cloned
  master list. Mitigation: in the relink pass, rebuild every such map
  by name lookup. Pattern: walk the original map's keys, find each
  one's string name (e.g. `r.name`), look up the cloned counterpart
  in the cloned master list (`clone.resource_list.resources[name]`),
  insert into a fresh map with the new key.
- **Allocator hygiene:** every `cbor.unmarshal` allocation must use
  `context.allocator` consistently; on failure path, leak/double-free
  risk. Use `context.temp_allocator` for the bytes buffer if possible.
- **Tag syntax verification:** confirm Odin's `core:encoding/cbor` tag
  syntax actually supports field skipping. Check the cbor package
  docs / source at
  `/nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/share/core/encoding/cbor/`
  before committing to it. If it doesn't, fall back to JSON
  (`core:encoding/json` reportedly supports `json:"-"` skip tags).

**Stop and ask if Stage 2 hits >1 day** — that's a signal to switch to Stage 3.

### Stage 3: manual per-struct *_clone procs (last resort)

For each top-level Game_Data field (~30 of them), write a `<type>_clone(src) -> dst`
proc that allocates a new instance, copies primitive fields, recursively clones
sub-collections, and leaves cross-list pointers nil for the relink pass to fill.

Most code; fully predictable; no stdlib surprises. Estimated 500–1500 lines of
straightforward boilerplate. Suitable for fan-out to subagents (one struct per
subagent, "implement `<type>_clone` body").

## Key facts about Game_Data layout (verified)

From [odin_flat/games__strategy__engine__data__game_data.odin](odin_flat/games__strategy__engine__data__game_data.odin):

```odin
Game_Data :: struct {
    using game_state:               Game_State,    // first field — &gd.game_state IS ^Game_Data
    game_name:                      string,
    game_version:                   ^Version,
    dice_sides:                     i32,
    force_in_swing_event_thread:    bool,
    alliances:                      ^Alliance_Tracker,
    relationships:                  ^Relationship_Tracker,
    game_map:                       ^Game_Map,
    player_list:                    ^Player_List,           // <-- has resources_held per player
    production_frontier_list:       ^Production_Frontier_List,
    production_rule_list:           ^Production_Rule_List,
    repair_frontier_list:           ^Repair_Frontier_List,
    repair_rules:                   ^Repair_Rules,
    resource_list:                  ^Resource_List,
    sequence:                       ^Game_Sequence,
    unit_type_list:                 ^Unit_Type_List,
    relationship_type_list:         ^Relationship_Type_List,
    properties:                     ^Game_Properties,
    units_list:                     ^Units_List,            // <-- contains all live ^Unit
    technology_frontier:            ^Technology_Frontier,
    loader:                         ^I_Game_Loader,
    territory_effect_list:          map[string]^Territory_Effect,
    battle_records_list:            ^Battle_Records_List,
    territory_listeners:            [dynamic]^Territory_Listener,
    data_change_listeners:          [dynamic]^Game_Data_Change_Listener,
    delegates:                      map[string]^I_Delegate,
    game_history:                   ^History,
    state:                          ^Game_Data_State,
    attachment_order_and_values:    [dynamic]^Tuple(...),
    game_data_event_listeners:      ^Game_Data_Event_Listeners,
}
```

Critical observations:
- `using game_state: Game_State` — Game_State has proc-typed vtable fields
  that are wired by the `game_data_v_*` shims at the top of the file.
  These wirings live ON THE CLONE if memcpy'd; verify they still work.
  If not, re-call them after clone.
- The Java `data.acquireWriteLock()` call in `saveGameUncompressed` is a
  no-op in Odin (single-threaded). Safe to drop.
- `Game_Data.player_list.players: map[string]^Game_Player` — string key,
  pointer value. Easy to clone (string keys survive marshal cleanly).
- `Game_Player.resources_held: map[^Resource]i32` — POINTER KEY. Must
  rebuild after clone via name-based relookup against
  `clone.resource_list`.

## Pivot opportunity: maybe the clone doesn't matter

While reading `abstract_pro_ai_purchase` body, look carefully at:

```odin
// Around line 600 in abstract_pro_ai.odin:
data_copy := abstract_pro_ai_copy_data(self, data)
if data_copy == nil { return }
// ... simulation walk uses data_copy ...
self.stored_purchase_territories = pro_purchase_ai_purchase(
    self.purchase_ai,
    purchase_delegate,
    &data.game_state,    // <-- ORIGINAL data, not data_copy!
)
```

The `pro_purchase_ai_purchase` call uses `&data.game_state` (the original).
This means the simulation runs against `data_copy`, but the actual purchase
delegate dispatch happens against the original. Russians.PUs is mutated by
the purchase delegate's `purchase()` body, not by the simulation.

**Hypothesis to test FIRST in fresh session before any CBOR work:**

If the clone is purely for "evaluating hypothetical futures during
simulation", a Stage 2-lite clone (independent player resources +
units_list) may be sufficient. The actual purchase happens against the
original. So fix the segfault Stage 1 caused, and the AI may purchase
correctly via the live `data` path.

To verify: add a probe inside `pro_purchase_ai_purchase` to confirm
it's reached even with `data_copy = nil` short-circuit. (It currently
isn't reached because of the early return.) Or just pursue the
Stage 2-lite step above and check whether snap 0013 advances.

## Documentation: add "Serialization shim divergence" policy

Update [llm-instructions.md](llm-instructions.md) and the orchestrator section of
[resume-prompt.md](resume-prompt.md) with a new policy block:

> **Serialization-shim divergence (orchestrator-owned).**
> JVM-native reflective serialization (`ObjectOutputStream`, `ObjectInputStream`,
> `writeObject`, `readObject`, `Serializable`) has no Odin equivalent. Where Java
> code uses these to clone or transmit `Game_Data`, the Odin port substitutes a
> functionally-equivalent in-memory deep-clone (currently CBOR-backed; see
> `game_data_utils_clone_game_data`). The byte-array intermediate is a
> diagnostic-only side effect; callers depend on the resulting `^Game_Data`, not
> the bytes.
>
> **Do not "fix" this back to Java-faithful.** No equivalent runtime exists.
> When porting a Java method that calls `writeObject`/`readObject`, treat those
> calls as opaque and route through `game_data_utils_clone_game_data` (or the
> `translateIntoOtherGameData` analog) instead of trying to model
> `Object_Output_Stream` semantics.

Add a tracking entry in [/memories/repo/phase-c-state.md](memories/repo/phase-c-state.md)
referencing this plan file once a stage actually lands.

## File-by-file checklist

- [ ] Stage 1: edit
  [odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin)
  — replace `game_data_utils_clone_game_data` body. Leave a comment block citing
  this plan file.
- [ ] Run snap suite, record `Russians.PUs` value before/after.
- [ ] If unblocked: mark
  `proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase` green via
  `scripts/mark_test_status.py`.
- [ ] If not unblocked: implement Stage 2 (CBOR + relink). Add `import "core:encoding/cbor"`
  to game_data_utils.odin (first such import in odin_flat/ — verify Odin compiler
  doesn't complain).
- [ ] Update [llm-instructions.md](llm-instructions.md) with the policy block above.
- [ ] Update [resume-prompt.md](resume-prompt.md) with a one-liner pointer to the
  policy in `llm-instructions.md`.
- [ ] Record landed implementation in
  [/memories/repo/phase-c-state.md](memories/repo/phase-c-state.md) and
  [/memories/session/triplea-port-progress.md](memories/session/triplea-port-progress.md).

## Open questions for future sessions

1. Are there other Java methods that depend on `cloneGameData` returning a
   *byte-faithful* serialization (e.g. for save-game writing)? Spot-check
   callers of `cloneGameData` and `gameDataToBytes`. The AI snapshot harness
   does NOT invoke save-game, but a future test might.
2. Does `translateIntoOtherGameData` need the same treatment? It's currently a
   no-op stub that returns the input unchanged. Out of scope until a snap fails
   on it.
3. Do the `Options { withDelegates, withHistory, withAttachmentXmlData }` flags
   need honoring? AI's call uses defaults (all false). Stage 1/2 ignore the flags.
   Revisit if a downstream test depends on flag behavior.

## Resume hints (for a fresh chat session)

The two open red `test_status` rows are:
- `proc:games.strategy.engine.framework.ServerGame#runNextStep()` (umbrella, snap 0013/0014)
- `proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase(...)` (snap 0013 specific)

### First 10 minutes of fresh session

1. Run baseline check (canonical command from top of this file). Confirm
   you see `Snapshot 0013 FAILED: ... 24 != 0` and `Snapshot 0014 FAILED:
   ... alreadyMoved 0.000 != 2.000`. If not, something has drifted —
   investigate before any new changes.
2. Read [odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin](odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin)
   `abstract_pro_ai_purchase` body in full. Specifically verify the
   "pivot opportunity" claim above — does
   `pro_purchase_ai_purchase` actually take `&data.game_state` or
   `&data_copy.game_state`? The plan asserts the former but verify
   in source. If verified, **prefer Stage 2-lite** over full CBOR.
3. Read [odin_flat/games__strategy__engine__data__player_list.odin](odin_flat/games__strategy__engine__data__player_list.odin)
   and `game_player.odin` to confirm field names used in the Stage
   2-lite sketch. The names `resources_held`, `players` are guesses.
4. Implement Stage 2-lite per the sketch above. Run baseline. Iterate.
5. If Stage 2-lite hits a wall (e.g. "still segfaults at a different
   field"), incrementally add more cloned subtrees (units_list, history,
   delegates) BEFORE pivoting to full CBOR.

### Avoid these traps

- **Do NOT pivot to snap 0014 to "make progress"** — keep this thread
  focused. Snap 0014 is undrilled and likely takes its own multi-step
  investigation in the Move_Delegate path.
- **Do NOT reformulate `Object_Input_Stream` to "really work"** — that's
  the ad-hoc reflective-serializer rabbit hole this plan exists to avoid.
- **Do NOT add field-skip tags speculatively** — verify Odin's CBOR/JSON
  package supports them by reading
  `/nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/share/core/encoding/cbor/`
  source first.
- **Do NOT mark
  `proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase` green
  unless snap 0013 actually passes** with no probes/instrumentation
  active. Per Phase C doctrine (`llm-instructions.md` §"How to classify
  a yellow proc"), crash-only / non-nil tests don't count.

### File checklist (Stage 2)

- [ ] Verify `pro_purchase_ai_purchase`'s actual data argument (read source).
- [ ] Verify field names in Player_List / Game_Player structs.
- [ ] Implement Stage 2-lite in
  [odin_flat/games__strategy__engine__framework__game_data_utils.odin](odin_flat/games__strategy__engine__framework__game_data_utils.odin).
- [ ] Run snap suite. Iterate on shape of clone until snap 0013 advances.
- [ ] If snap 0013 passes: mark
  `proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase` green via
  `scripts/mark_test_status.py`.
- [ ] Update [llm-instructions.md](llm-instructions.md) with the
  Serialization-shim divergence policy block.
- [ ] Update [resume-prompt.md](resume-prompt.md) with a one-liner
  pointer to the policy.
- [ ] Record landed implementation in
  [/memories/repo/phase-c-state.md](memories/repo/phase-c-state.md)
  and [/memories/session/triplea-port-progress.md](memories/session/triplea-port-progress.md).

Snap 0014 (`unit.alreadyMoved 0 != 2`) is a separate, undrilled red — likely in
the Move_Delegate/move_unit path. Do not interleave with this plan.

## Cross-references

- Prior session memory:
  [/memories/session/triplea-port-progress.md](memories/session/triplea-port-progress.md)
- Phase C state:
  [/memories/repo/phase-c-state.md](memories/repo/phase-c-state.md)
- Repo memory note about `GamePlayer.game_data_component.game_data` back-ref —
  relevant to the cycle-mitigation strategy in Stage 2 (relink pass must restore
  these back-refs).
- Phase C doctrine: [llm-instructions.md](llm-instructions.md) §"Layered drill-down debugging"
- Java source under analysis:
  [triplea/game-app/game-core/src/main/java/games/strategy/engine/framework/GameDataUtils.java](triplea/game-app/game-core/src/main/java/games/strategy/engine/framework/GameDataUtils.java)

