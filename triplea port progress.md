# TripleA Java→Odin port progress

Workspace: /home/caleb/todin

## Phase C — snapshot validation
- Baseline: **50/52 PASS** (was ~46/52 entering session)
- Failing snaps: **0013** (Russians.PUs 24 != 0), **0014** (unit.alreadyMoved 0 != 3)

## 2026-05-07 session 3 — Layer 5 (russianPlace end-step crash) FIXED + clone implementation attempted
Re-enabled shallow clone, reproduced russianPlace end-step nil-bridge segfault. Root cause: `data_copy.sequence == data.sequence` so AI's `game_sequence_set_round_and_step` advances the SHARED cursor; outer `server_game_end_step` then dispatches on whatever step cursor ended on (russianPlace), bridge=nil → crash in `abstract_place_delegate_do_after_end`.

Fix landed in `abstract_pro_ai_purchase` (odin_flat/games__strategy__triplea__ai__pro__abstract_pro_ai.odin):
- Save/restore `sequence.current_index`/`round` via `defer` around AI sim loop.
- Save/restore `move_del.abstract_delegate.bridge`/`player` via `defer` around inline bridge assignment.
Both are dead code under nil-return clone shim but ready when shallow/real clone re-enabled.

New layer surfaced (NOT fixed): with shallow clone enabled, snap 0014 stays at `alreadyMoved 0!=3` (was already `0!=3` baseline; "0!=2" in earlier summary was stale). `pro_combat_move_ai_do_combat_move` mutates `Unit.already_moved` on SHARED unit graph during AI sim → STRUCTURAL — needs per-unit clone. Reverted clone to nil-return shim.



## 2026-05-07 — drilled rule_count=0 → Unit_Type kind discriminator gap (REVERTED, harness-incompatible)
With shallow clone enabled, probed `pro_purchase_ai_populate_production_rule_map` for Russians: `pf_rules=13` (production frontier OK), but `land_opts=0 aa_opts=0 air_opts=0 sea_opts=0 factory_opts=0` — the entire `Pro_Purchase_Option_Map` was empty.

Root cause: `pro_purchase_option_map_new` filters rules with `any_named.default_named.named.kind != .Unit_Type`. Probed inside the constructor: every result key has `kind=0` (Named_Kind default), not `Unit_Type=2`. Json_loader's `deserialize_unit_type` doesn't set `ut.named.kind = .Unit_Type` (unlike `deserialize_player` and `deserialize_territory` which do).

**Fix tried:** add `ut.named.kind = .Unit_Type` to deserialize_unit_type in both json_loader copies. **Result: 8 SNAP REGRESSIONS (snap 0015, 0021, 0022, 0023, 0029, 0030, 0037, 0038, 0039, 0045 — all started failing).** Pattern: snaps where AI does purchase/move now actually run AI logic which mutates state in ways the harness's expected-state JSON doesn't match. Snap 0013 stays at 24!=0 even with the fix because the AI sim's combat-move chain segfaults on shared/unbacked refs.

**Conclusion:** the Unit_Type kind discriminator gap is NOT a benign infrastructure fix. Setting it correctly unlocks AI logic across many snapshots, all of which would also need full deep clone (so AI mutations don't leak to the original) AND the snapshot expected-state JSONs need to assume "AI did its turn" for those snaps.

**Reverted.** Baseline preserved at 50/52. Documented as a tightly coupled "kind fix + deep clone + snapshot regenerate" trio that needs to land together, not piecewise.

## 2026-05-07 session 6 — Deep clone implemented + gated behind -define:DEEP_CLONE
**LANDED:** new file `odin_flat/games__strategy__engine__framework__game_data_clone.odin` (~600 LOC). Implements memoized recursive `game_data_deep_clone(src) -> ^Game_Data` with Clone_Ctx + map[rawptr]rawptr translation table. Per-type clones for: Player_List, Game_Player, Resource_Collection, Unit_Collection, Units_List, Unit, Game_Map, Territory, Territory_Attachment, Tech_Attachment, Game_Sequence, Game_Step, Game_Data_State, Tech_Tracker, Game_Properties, Relationship_Tracker, Alliance_Tracker, and 13 concrete delegate types (Move/Special_Move/Purchase/Bid_Purchase/No_Pu_Purchase/Place/Bid_Place/Battle/End_Turn/Technology/Tech_Activation/Initialization/End_Round). All back-refs (Game_Data_Component.game_data, Tech_Tracker.data) updated to clone; cross-references (Unit.{owner,original_owner,transported_by,unloaded_to,originated_from,unloaded[]}, Territory.owner, Territory_Attachment.{original_owner,convoy_attached,change_unit_owners,capture_unit_on_entering_by}, Game_Step.player, Player_List.null_player, Game_Map.{territories,territory_lookup,connections}, Relationship_Tracker.relationships keys, Alliance_Tracker.alliances values, Move_Delegate.pus_lost keys, Technology_Delegate.techs keys, End_Round_Delegate.winners) all rewritten via memoized clone_X helpers.

**GATED:** `game_data_utils_clone_game_data` returns nil by default; with `-define:DEEP_CLONE=true` it calls `game_data_deep_clone`. Default baseline preserved at 50/52.

**ACTIVE BLOCKER (next session):** With `-define:DEEP_CLONE=true`, snap 0013 reaches `pro_combat_move_ai_do_combat_move` → `pro_battle_utils_territory_has_local_land_superiority` → `pro_territory_manager_populate_attack_options` → `find_attack_options.find_land_move_options` → `is_land_move_option` → `route_finder_find_route_by_cost_pair` → BFS → `route_finder_get_neighbors_validating_canals_and_proc` → SEGFAULT on the 5th neighbor's filter call. Filter is `pro_matches_pred_territory_can_move_land_units_through(player, u, start_territory, false, enemy_territories)`. NOT in `move_validator_can_any_units_pass_canal` (verified by short-circuit-return-true patch — same crash). NOT in `relationship_tracker_get_relationship_type` (no nil-relationship probe fired). The crash is INSIDE the predicate body, somewhere after the enemy_territories check and during `pro_matches_territory_can_move_specific_land_unit` evaluation OR `matches_is_territory_allied(player)` evaluation OR `matches_territory_has_no_enemy_units(player)`.

**Next session start point:**
1. `-define:DEEP_CLONE=true` to enable.
2. Add probes inside `pro_matches_pred_territory_can_move_specific_land_unit` (file odin_flat/games__strategy__triplea__ai__pro__util__pro_matches.odin around line 2330) and inside `matches_pred_is_territory_allied` (matches.odin:369) to identify which deref segs.
3. Likely culprits in priority order:
   a. **Game_Player.attachments map** — territories' `attachments["territoryAttachment"]` was rewired to point to clone (line in clone_territory). But Tech_Attachment for players may still point to original via `attachments["techAttachment"]` if json_loader populates that map for players (check `deserialize_player`).
   b. **Territory.unit_collection.holder** — set to cast(^Named_Unit_Holder)dst in clone_territory but only AFTER unit_collection is cloned. The clone_unit_collection itself doesn't update holder. Verify.
   c. **Game_Properties.editable_properties / player_properties** — currently shared (not cloned). If `properties_get_X` calls into them and expects matching player references, would break.
   d. **Unit.type** — shared static (Unit_Type). predicate may walk into `unit_attachment` which is shared. Should be safe.
   e. **Pro_Data internal cached collections** — pro_data.unit_territory_map, pro_data.my_unit_territories, pro_data.purchase_options. Built by `pro_data_initialize_simulation` from cloned data; should be all-cloned. Verify if `purchase_options` (Pro_Purchase_Option_Map) constructor sees any non-cloned refs.

**REPRO command (with DEEP_CLONE on):**
```
cd /home/caleb/todin/triplea && /nix/store/dj690miai5nk9h5d38apq0xp0nq84i02-odin-dev-2026-04/bin/odin test conversion/odin_tests/server_game_run_next_step -collection:flat=/home/caleb/todin/odin_flat -collection:test_common=conversion/odin_tests/test_common -define:ODIN_TEST_TRACK_MEMORY=false -define:DEEP_CLONE=true 2>&1 | tail -30
```

**File index for next session:**
- Deep clone implementation: odin_flat/games__strategy__engine__framework__game_data_clone.odin
- Gate: odin_flat/games__strategy__engine__framework__game_data_utils.odin (`DEEP_CLONE :: #config(DEEP_CLONE, false)`)
- Snapshot loader: triplea/conversion/odin_tests/test_common/json_loader.odin (mirror in templates/)
- Crash site: odin_flat/games__strategy__triplea__ai__pro__util__pro_matches.odin `pro_matches_pred_territory_can_move_land_units_through` (line ~144)
- Predicate target: odin_flat/games__strategy__triplea__delegate__matches.odin `matches_pred_is_territory_allied` (line ~369)

**Step 2 (after crash drilled):** Land `ut.named.kind = .Unit_Type` in deserialize_unit_type (json_loader.odin line 540 + templates copy). This will unlock Pro_Purchase_Option_Map population and progress snap 0013 toward PUs=0.

**Step 3:** Add territory/unit/territory_attachment game_data back-refs in json_loader (only safe AFTER deep clone is healthy).

**Step 4:** Snap regen for any whose expected-state assumed no-op AI.

**Step 5:** `llm-instructions.md` divergence policy.

Tree state at session end: clean, baseline 50/52 with `-define:DEEP_CLONE=false` (default).


Other tried: adding game_data back-refs on Territory, Unit, Territory_Attachment in json_loader. Also caused regressions when combined with kind fix. Reverted.

Net new knowledge: Pro_Purchase_Option_Map is gated on `Named_Kind.Unit_Type` — the json_loader populates name fields but not kind discriminators (except for explicitly-fixed cases like Game_Player and Territory). A future "fix all kind discriminators in json_loader" pass needs to be paired with deep clone before it can land without regressing snapshots.



## 2026-05-07 — drilled find_purchase_territories=0 claim (FALSE) + landed json_loader player back-ref fix
Bisected `pro_purchase_utils_find_purchase_territories` for Russians: returns 3 (Caucasus, Karelia S.S.R., Russia), not 0. The "returns 0" claim from previous plan was wrong/stale.

With shallow clone enabled + my Layer-5 save/restore defers, full pro_purchase_ai_purchase chain runs to completion on Russians (no segfault). `i_purchase_delegate_purchase` dispatches successfully (err="") but `purchase_map.map_values` is EMPTY (rule_count=0). So no PUs spent → snap 0013 stays at PUs 24!=0.

Real chain blocker: AI's `pro_purchase_ai_populate_production_rule_map` produces 0 rules because the underlying purchase logic (purchase_aa_units, purchase_land_units, etc.) doesn't pick any units. Likely root cause: `pro_resource_tracker_new_from_player(self.player)` reads resources but the snapshot-loaded player's `Resource_Collection.game_data_component.game_data` was nil (per existing repo memory).

Fix landed: `deserialize_player` in both json_loader copies now sets:
- `p.named_attachable.default_named.game_data_component.game_data = gd`
- `p.resources.game_data_component.game_data = gd`

This is a pure infrastructure fix (no regression — baseline still 50/52). It unblocks any AI/delegate code path that needs to look up resources by name on a snapshot-loaded player. However it alone does NOT make snap 0013 pass — the AI's purchase decision logic still needs full drill-down to figure out why it picks 0 units.

Snap 0014 is `alreadyMoved 0!=N` (N varies — actual deterministic value but UUID printed varies by map iteration). Still requires full per-unit deep clone.

Next: with clone enabled, drill why `pro_purchase_ai_purchase_land_units` doesn't queue any units (probably more nil-game-data back-refs on unit_attachments / production_rules). Each is independent of clone.



## 2026-05-07 — clone_game_data scoped-clone attempt (REVERTED)
Tried Stage 2-lite+: shallow Game_Data + new Player_List + new per-player Game_Player + new per-player Resource_Collection (cloned resources map). Result: snap 0013 still `PUs 24!=0` (unchanged — find_purchase_territories=0 bug is the real blocker), but snap 0014 REGRESSED from `alreadyMoved 0!=3` to `0!=N` (varies per run, AI sim mutates Unit.already_moved on SHARED units before original move-delegate snapshot). Reverted to nil-return shim.

**Conclusion:** clone_game_data CANNOT be partially implemented without regression. Required scope is full deep clone of Game_Data + Player_List + Game_Players + Resource_Collections + Units_List + every Unit + Game_Map + every Territory + Unit_Collections + Game_Sequence + Game_Steps, with owner pointer relinking. Cascading clone — too large for incremental delivery. Layer 5 + move_del.bridge save/restore defers REMAIN in abstract_pro_ai_purchase, ready to receive a real clone without re-discovering those bugs.

Real next blocker for snap 0013 is the `pro_purchase_utils_find_purchase_territories returns 0` bug from session 2 — independent of clone, drillable now. Snap 0013 won't progress with clone alone.



## test_status counters
- green=41, red=2, yellow=10 (recorded=53)

## Direct fixes applied this session
- **json_loader.odin RTA defaults**: `Relationship_Type_Attachment` objects created via `new()` had string property fields = "" instead of "default" sentinel. Initialized 11 PROPERTY_DEFAULT fields. Fixed snap 0015. Mirrored to `templates/odin_test_common/json_loader.odin`.
- Marked `MustFightBattle#fight(...)` green.
- **json_loader.odin productionFrontier post-pass**: loader was not binding `gp.production_frontier` from the JSON's `productionFrontier: <name>` field. Added a 2nd-pass (after `production_frontier_list` is populated) that walks each player JSON entry, looks up the frontier by name, and assigns `gp.production_frontier` (and `repair_frontier` if present). Mirrored to templates. Without this, `purchase_delegate_can_we_purchase_or_repair` returned false → AI's `start("russianPurchase")` was never dispatched (gated by `delegate_currently_requires_user_input`).

## Snap 0013 root cause IDENTIFIED but NOT FIXED
- After above productionFrontier loader fix: AI's `abstract_pro_ai_purchase` now runs for snap 0013.
- However the body short-circuits at `data_copy := abstract_pro_ai_copy_data(self, data); if data_copy == nil { return }`.
- Root cause: `game_data_utils_clone_game_data` always returns nil because `Object_Input_Stream`/`Object_Output_Stream` are opaque shims (`createGameDataFromBytes` returns nil). This is documented intentional behavior in `odin_flat/games__strategy__engine__framework__game_data_utils.odin` ("opaque-IO regime").
- Java has the same `if (dataCopy == null) return;` guard, but Java's serialization works.
- **To fix**: implement a real (or sufficient) deep-clone of `Game_Data` in the harness so AI's simulation can run. This is a substantial layer-0 infrastructure gap (multi-day effort), not a single-line fix.

## Other failing snap
- 0014: unit.alreadyMoved 0 != 3 — separate red, not drilled. Likely Move_Delegate / move_unit path.

## Stage 1 (shallow-clone probe) — COMPLETE, REVERTED
- Replaced clone body with `clone := new(Game_Data); clone^ = data^` (shared sub-pointers).
- Result: snap 0013 SIGSEGVs during AI sim walk. Worse than baseline (asserts → crashes whole binary).
- Confirms AI mutates through shared sub-pointers. Need independent allocations for at least the mutated subgraph.
- Reverted to nil-returning shim to keep 50/52 stable.
- Plan file: `/home/caleb/todin/serialization-shim-divergence-plan.md` (updated with Stage 1 outcome).

## Stage 2-lite probe (2026-05-07, second drill-down) — REVERTED, but yielded findings
Tried scoped clone (new player_list + per-player Game_Player + per-player Resource_Collection, share everything else). Then iterated with PROBE_AI_LOOP probes through `abstract_pro_ai_purchase` → `pro_purchase_ai_purchase`.

Findings (all reverted to keep 50/52 baseline):
1. **Cloning Game_Players breaks pointer equality with `Game_Step.player_id`.** `abstract_pro_ai_get_game_steps_for_player` filters via `game_player == game_step_get_player_id(step)` against the SHARED step. Cloned player_copy ≠ original player → returns empty → AI loop never runs purchase. Either share Game_Player pointers OR re-link `Game_Step.player_id` after cloning.
2. **Discovered I_Delegate_Bridge dispatcher bug:** `i_delegate_bridge_get_*` blindly do `cast(^Default_Delegate_Bridge)self` ignoring proc-fields. AI's `bridge := new(I_Delegate_Bridge)` with proc-fields wired (`get_data`, `get_game_player`, `add_change`) cannot be dispatched safely. **Tried fix:** embed `using i_delegate_bridge: I_Delegate_Bridge` as first field of Default_Delegate_Bridge + add proc-field-priority in dispatchers. **Result:** unblocks AI bridge construction (no segfault), but PERTURBS snap 0014 from `0!=2` to `0!=3` (some downstream code reads laundered struct fields). Reverted.
3. **Even with shallow share + dispatcher fix, snap 0014 perturbed because** `abstract_delegate_set_delegate_bridge_and_player_no_websocket(&move_del.abstract_delegate, bridge)` MUTATES the shared `move_del.bridge` field (move_del comes from `data.delegates[name]` which is shared). Real clone must clone delegates too.
4. **AI's `pro_purchase_utils_find_purchase_territories` returns 0 for Russians** (probed when shallow-clone got that far). Russians own 11 territories but the function filters out all of them. Either ra.placement_any_territory false AND no factory match, OR move filter rejects. Separate logical bug, may surface independently of clone fix.
5. **Pivot claim CONFIRMED:** `pro_purchase_ai_purchase(... &data.game_state)` uses ORIGINAL data (line 701), not data_copy. The clone is for simulation only.

## Concrete state at end of session
- **Plan file:** `/home/caleb/todin/serialization-shim-divergence-plan.md` (Stage 1 + Stage 2-lite explored)
- **All probes removed.** All clone/dispatcher experiments reverted.
- **Baseline:** 50/52 (snap 0013 PUs 24!=0, snap 0014 alreadyMoved 0!=2). Verified clean.
- **Comment in `game_data_utils_clone_game_data`** updated with Stage 2-lite findings.

## Resume here
Three independent unblocking issues for snap 0013, in increasing depth:

1. **Snap 0014 perturbation by Default_Delegate_Bridge embed** — investigate WHY the embed shifted units[].alreadyMoved expected from 2 to 3. Probably some code reads/writes to Default_Delegate_Bridge fields via offset-arithmetic or via `cast(^I_Delegate_Bridge)default_bridge_ptr` followed by reading I_Delegate_Bridge fields directly (not via dispatcher). The proc-field nil-init shifted by sizeof(I_Delegate_Bridge) bytes. Find the offending site, fix it, re-apply embed. Required infrastructure for AI bridges to work.

2. **Delegate cloning** — when cloning Game_Data, must also clone the `delegates: map[string]^I_Delegate` so `move_del.bridge = ai_bridge` doesn't leak. AND clone Game_Sequence (since steps reference players). Stage 2-lite must expand to: clone player_list + Resource_Collection + delegates + sequence.

3. **find_purchase_territories returning 0 for Russians** — likely orthogonal bug (Russians have factory in Russia but filter excludes). Probe `pro_matches_territory_has_factory_and_is_not_conquered_owned_land(player)` for each owned territory.

Recommended order: fix #1 (small infrastructure), then approach #2 carefully (probably need full CBOR or manual *_clone after all), and surface #3 as it appears.

Alternative: pivot to snap 0014 (`unit.alreadyMoved 0 != 2`) — separate code path, may be simpler.

## Design recommendation for Game_Data deep-clone (awaiting user review)

**Decision needed before implementation.** Discussed the byte-level fidelity question with user; they asked to step back and consider non-byte alternatives.

**Recommendation:**
- KEEP faithful Java-shaped public procs: `game_data_utils_clone_game_data`, `..._clone_game_data_with_history`, `..._translate_into_other_game_data`. Signatures unchanged.
- DIVERGE below: replace internal `gameDataToBytes` + `createGameDataFromBytes` round-trip with a native deep-clone helper `game_data_deep_clone(data, options) -> ^Game_Data`.
- `Object_Input_Stream` / `Object_Output_Stream` shims stay as-is (no longer on clone path).

**Strategy: option C — JSON round-trip via existing json_loader.** Rationale:
1. Reuses json_loader's relink rules (productionFrontier binding, RTA defaults, attachable back-refs) — every json_loader fix benefits clone for free.
2. Identity preservation comes free — json_loader already rebinds names→pointers against master lists, so cloned graph has correct `^Player == ^Player` semantics.
3. Debuggable — JSON intermediate is human-readable, diffable against snapshot before.json.
4. Snapshot symmetry — same format as harness, so any divergence is a real bug not wire-format artifact.

**Implementation work:**
- New: Game_Data → JSON serializer (mechanical inverse of json_loader). Probably 400-800 LOC.
- Reuses: existing json_loader.odin entirely on the read side.
- First cut narrows to AI purchase / EndTurn paths (mirror Java's `Options.forBattleCalculator()` — no history, no attachment-order, no delegates, no battle records). Expand iteratively as needed.

**Alternative options considered:**
- A) Manual per-type deep-clone procs (500-1500 LOC, predictable, no reflection)
- B) CBOR round-trip + relink pass (200-400 LOC, harder to debug, reflection blackbox)
- C) JSON round-trip via existing json_loader (400-800 LOC, max reuse) **← RECOMMENDED**

**Open questions for user:**
1. Scope — only snap 0013/0014 paths, or all clone callers?
2. Mutation — confirm AI's simulation actually mutates the clone (vs. mostly reads)?
3. Identity — confirm relink discipline is acceptable (vs. switching equality checks to name-based)?
4. Approach choice — A, B, or C?

User unavailable when asked; **no implementation work started**. Resume by having user pick approach, then begin Game_Data → JSON serializer if option C is chosen.
