package game

import "core:fmt"

Move_Delegate :: struct {
	using abstract_move_delegate: Abstract_Move_Delegate,
	need_to_initialize: bool,
	need_to_do_rockets: bool,
	pus_lost: map[^Territory]i32,
}

// games.strategy.triplea.delegate.MoveDelegate#lambda$delegateCurrentlyRequiresUserInput$0
// Java: t -> t.anyUnitsMatch(moveableUnitOwnedByMe)
// Captures the `moveableUnitOwnedByMe` Predicate<Unit> from the enclosing
// delegateCurrentlyRequiresUserInput method. Per the rawptr-ctx convention,
// the captured predicate is carried as a (fn, ctx) pair.
Move_Delegate_Delegate_Currently_Requires_User_Input_0_Ctx :: struct {
	moveable_unit_owned_by_me:     proc(rawptr, ^Unit) -> bool,
	moveable_unit_owned_by_me_ctx: rawptr,
}

move_delegate_lambda_delegate_currently_requires_user_input_0 :: proc(ctx: rawptr, t: ^Territory) -> bool {
	c := cast(^Move_Delegate_Delegate_Currently_Requires_User_Input_0_Ctx)ctx
	return territory_any_units_match(t, c.moveable_unit_owned_by_me, c.moveable_unit_owned_by_me_ctx)
}

// games.strategy.triplea.delegate.MoveDelegate#pusLost(games.strategy.engine.data.Territory,int)
// Java: pusLost.add(t, amt);
// `pus_lost` is `map[^Territory]i32`; Java IntegerMap.add adds amt to the
// existing value (defaulting to 0 when absent).
move_delegate_pus_lost :: proc(self: ^Move_Delegate, t: ^Territory, amt: i32) {
	self.pus_lost[t] = self.pus_lost[t] + amt
}

// games.strategy.triplea.delegate.MoveDelegate#loadState(java.io.Serializable)
// Java:
//   final MoveExtendedDelegateState s = (MoveExtendedDelegateState) state;
//   super.loadState(s.superState);
//   needToInitialize = s.needToInitialize;
//   needToDoRockets = s.needToDoRockets;
//   pusLost = s.pusLost;
// `super.loadState` dispatches to AbstractMoveDelegate.loadState; the saved
// `superState` was produced by AbstractMoveDelegate.saveState and is therefore
// an Abstract_Move_Extended_Delegate_State (stored as rawptr in the state).
// `pus_lost` lives as `map[^Territory]i32` on Move_Delegate but is serialized
// as ^Integer_Map; rebuild the in-memory map from the saved Integer_Map.
move_delegate_load_state :: proc(self: ^Move_Delegate, state: ^Move_Extended_Delegate_State) {
	abstract_move_delegate_load_state(
		&self.abstract_move_delegate,
		(^Abstract_Move_Extended_Delegate_State)(state.super_state),
	)
	self.need_to_initialize = state.need_to_initialize
	self.need_to_do_rockets = state.need_to_do_rockets
	clear(&self.pus_lost)
	if state.pus_lost != nil {
		for k, v in state.pus_lost.map_values {
			self.pus_lost[(^Territory)(k)] = v
		}
	}
}

// games.strategy.triplea.delegate.MoveDelegate#<init>()
// Java has no explicit constructor; field initializers set
// `needToInitialize = true`, `needToDoRockets = true`, and
// `pusLost = new IntegerMap<>()`. The implicit super() call into
// AbstractMoveDelegate initializes `movesToUndo = new ArrayList<>()`
// (mirrored here on the embedded Abstract_Move_Delegate).
move_delegate_new :: proc() -> ^Move_Delegate {
	self := new(Move_Delegate)
	self.moves_to_undo = make([dynamic]^Undoable_Move)
	self.need_to_initialize = true
	self.need_to_do_rockets = true
	self.pus_lost = make(map[^Territory]i32)
	// Wire the Abstract_Move_Delegate vtable slot for `pusAlreadyLost`
	// (Java: `return pusLost.getInt(t);`). Forwards to the per-type
	// `move_delegate_pus_already_lost` body via the embedded layout.
	self.abstract_move_delegate.pus_already_lost = proc(amd: ^Abstract_Move_Delegate, t: ^Territory) -> i32 {
		md := cast(^Move_Delegate)amd
		return move_delegate_pus_already_lost(md, t)
	}
	self.start = move_delegate_v_start
	// move_delegate_end intentionally not wired yet — touches reset-state
	// machinery that depends on bridge wiring not yet ported.
	return self
}

@(private = "file")
move_delegate_v_start :: proc(self: ^I_Delegate) {
	move_delegate_start(cast(^Move_Delegate)self)
}

@(private = "file")
move_delegate_v_end :: proc(self: ^I_Delegate) {
	move_delegate_end(cast(^Move_Delegate)self)
}

// games.strategy.triplea.delegate.MoveDelegate#pusAlreadyLost(Territory)
// Direct concrete-typed lookup — Java: `return pusLost.getInt(t);`.
// Odin map lookup defaults to zero when absent, mirroring IntegerMap.getInt.
move_delegate_pus_already_lost :: proc(self: ^Move_Delegate, t: ^Territory) -> i32 {
	if v, ok := self.pus_lost[t]; ok {
		return v
	}
	return 0
}

// games.strategy.triplea.delegate.MoveDelegate#getEmptyNeutral(games.strategy.engine.data.Route)
// Java:
//   final Predicate<Territory> emptyNeutral =
//       Matches.territoryIsEmpty().and(Matches.territoryIsNeutralButNotWater());
//   return route.getMatches(emptyNeutral);
// Both source predicates are non-capturing (their rawptr ctx is nil),
// so we compose them inline as a plain proc(^Territory) -> bool that
// route_get_matches accepts directly.
move_delegate_lambda_get_empty_neutral_pred :: proc(t: ^Territory) -> bool {
	if !matches_pred_territory_is_empty(nil, t) {
		return false
	}
	return matches_pred_territory_is_neutral_but_not_water(nil, t)
}

move_delegate_get_empty_neutral :: proc(route: ^Route) -> [dynamic]^Territory {
	return route_get_matches(route, move_delegate_lambda_get_empty_neutral_pred)
}

// games.strategy.triplea.delegate.MoveDelegate#saveState()
// Java:
//   final MoveExtendedDelegateState state = new MoveExtendedDelegateState();
//   state.superState = super.saveState();
//   state.needToInitialize = needToInitialize;
//   state.needToDoRockets = needToDoRockets;
//   state.pusLost = pusLost;
//   return state;
// `super.saveState()` dispatches to AbstractMoveDelegate.saveState, which
// returns an Abstract_Move_Extended_Delegate_State stored as rawptr in the
// outer state. `pus_lost` lives in memory as `map[^Territory]i32` but the
// extended-state field is `^Integer_Map`; rebuild the Integer_Map from the
// in-memory map so loadState can round-trip it.
move_delegate_save_state :: proc(self: ^Move_Delegate) -> ^Move_Extended_Delegate_State {
	state := move_extended_delegate_state_new()
	state.super_state = rawptr(abstract_move_delegate_save_state(&self.abstract_move_delegate))
	state.need_to_initialize = self.need_to_initialize
	state.need_to_do_rockets = self.need_to_do_rockets
	state.pus_lost = integer_map_new()
	for k, v in self.pus_lost {
		state.pus_lost.map_values[rawptr(k)] = v
	}
	return state
}

// games.strategy.triplea.delegate.MoveDelegate#getResetUnitStateChange(games.strategy.engine.data.GameState)
// Java: walks every unit in `data.getUnits()` and, for each non-default
// piece of per-turn state, appends a property-reset Change to a
// CompositeChange (alreadyMoved=0, wasInCombat=false, submerged=false,
// airborne=false, launched=0, unloaded=[], wasLoadedThisTurn=false,
// unloadedTo=null, wasUnloadedInCombatPhase=false, wasAmphibious=false,
// chargedFlatFuelCost=false). The Odin port mirrors this exactly,
// boxing each new value into a heap allocation so the rawptr-typed
// `change_factory_unit_property_change` can carry it through to the
// per-property setter (see unit.odin Unit_Property_Name dispatch).
move_delegate_get_reset_unit_state_change :: proc(data: ^Game_State) -> ^Change {
	change := composite_change_new()
	prop_already_moved := Unit_Property_Name.Already_Moved
	prop_was_in_combat := Unit_Property_Name.Was_In_Combat
	prop_submerged := Unit_Property_Name.Submerged
	prop_airborne := Unit_Property_Name.Airborne
	prop_launched := Unit_Property_Name.Launched
	prop_unloaded := Unit_Property_Name.Unloaded
	prop_loaded_this_turn := Unit_Property_Name.Loaded_This_Turn
	prop_unloaded_to := Unit_Property_Name.Unloaded_To
	prop_unloaded_in_combat_phase := Unit_Property_Name.Unloaded_In_Combat_Phase
	prop_unloaded_amphibious := Unit_Property_Name.Unloaded_Amphibious
	prop_charged_flat_fuel_cost := Unit_Property_Name.Charged_Flat_Fuel_Cost
	for _, unit in game_state_get_units(data).units {
		if unit_get_already_moved(unit) != 0 {
			boxed := new(f64)
			boxed^ = 0
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_already_moved),
				),
			)
		}
		if unit_get_was_in_combat(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_was_in_combat),
				),
			)
		}
		if unit_get_submerged(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_submerged),
				),
			)
		}
		if unit_get_airborne(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_airborne),
				),
			)
		}
		if unit_get_launched(unit) != 0 {
			boxed := new(i32)
			boxed^ = 0
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_launched),
				),
			)
		}
		if len(unit_get_unloaded(unit)) > 0 {
			boxed := new([dynamic]^Unit)
			boxed^ = make([dynamic]^Unit)
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_unloaded),
				),
			)
		}
		if unit_get_was_loaded_this_turn(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_loaded_this_turn),
				),
			)
		}
		if unit_get_unloaded_to(unit) != nil {
			boxed := new(^Territory)
			boxed^ = nil
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_unloaded_to),
				),
			)
		}
		if unit_get_was_unloaded_in_combat_phase(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_unloaded_in_combat_phase),
				),
			)
		}
		if unit_get_was_amphibious(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_unloaded_amphibious),
				),
			)
		}
		if unit_get_charged_flat_fuel_cost(unit) {
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change(
					unit,
					rawptr(boxed),
					unit_property_name_to_string(&prop_charged_flat_fuel_cost),
				),
			)
		}
	}
	return &change.change
}

// games.strategy.triplea.delegate.MoveDelegate#resetBonusMovement
// Private instance method: build a CompositeChange that zeros
// `bonusMovement` for every unit currently holding a non-zero bonus.
move_delegate_reset_bonus_movement :: proc(self: ^Move_Delegate) -> ^Change {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	change := composite_change_new()
	prop_bonus_movement := Unit_Property_Name.Bonus_Movement
	for _, u in game_state_get_units(data).units {
		if unit_get_bonus_movement(u) != 0 {
			boxed := new(i32)
			boxed^ = 0
			composite_change_add(
				change,
				change_factory_unit_property_change(
					u,
					rawptr(boxed),
					unit_property_name_to_string(&prop_bonus_movement),
				),
			)
		}
	}
	return &change.change
}

// games.strategy.triplea.delegate.MoveDelegate#giveBonusMovementToUnits(
//     games.strategy.engine.data.GamePlayer,
//     games.strategy.engine.data.GameState,
//     games.strategy.engine.data.Territory)
// For every unit `u` in `t` that can be given bonus movement by facilities
// in its territory and is allied to `player`, find the largest bonus
// granted by allied bonus-givers either in `t` itself, in adjacent land
// territories (when `u` is a sea unit), or in adjacent water territories
// (when `u` is a land unit), via UnitAttachment.givesMovement[u.type].
// Apply Math.max with `-(unitAttachment.movement(player))` so the bonus
// can never reduce a unit's effective movement below zero, then emit a
// BONUS_MOVEMENT property change. Java's Predicate.and() composition is
// inlined here as boolean conjunctions over the (proc, ctx) match pairs.
move_delegate_give_bonus_movement_to_units :: proc(
	player: ^Game_Player,
	data: ^Game_State,
	t: ^Territory,
) -> ^Change {
	change := composite_change_new()
	prop_bonus_movement := Unit_Property_Name.Bonus_Movement
	can_be_given_p, can_be_given_c :=
		matches_unit_can_be_given_bonus_movement_by_facilities_in_its_territory(t, player)
	is_unit_allied_p, is_unit_allied_c := matches_is_unit_allied(player)
	allied_unit_p, allied_unit_c := matches_allied_unit(player)
	is_sea_p, is_sea_c := matches_unit_is_sea()
	is_land_p, is_land_c := matches_unit_is_land()
	for u in t.unit_collection.units {
		if !can_be_given_p(can_be_given_c, u) {
			continue
		}
		if !is_unit_allied_p(is_unit_allied_c, u) {
			continue
		}
		bonus_movement: i32 = min(i32)
		gives_bonus_to_unit_p, gives_bonus_to_unit_c :=
			matches_unit_can_give_bonus_movement_to_this_unit(u)
		gives_bonus_units: [dynamic]^Unit
		// givesBonusUnit = alliedUnit(player).and(unitCanGiveBonusMovementToThisUnit(u))
		for cand in t.unit_collection.units {
			if allied_unit_p(allied_unit_c, cand) &&
			   gives_bonus_to_unit_p(gives_bonus_to_unit_c, cand) {
				append(&gives_bonus_units, cand)
			}
		}
		if is_sea_p(is_sea_c, u) {
			// givesBonusUnitLand = givesBonusUnit.and(unitIsLand())
			territory_is_land_p, territory_is_land_c := matches_territory_is_land()
			neighbors := game_map_get_neighbors_predicate(
				game_state_get_map(data),
				t,
				territory_is_land_p,
				territory_is_land_c,
			)
			for current in neighbors {
				for cand in current.unit_collection.units {
					if allied_unit_p(allied_unit_c, cand) &&
					   gives_bonus_to_unit_p(gives_bonus_to_unit_c, cand) &&
					   is_land_p(is_land_c, cand) {
						append(&gives_bonus_units, cand)
					}
				}
			}
		} else if is_land_p(is_land_c, u) {
			// givesBonusUnitSea = givesBonusUnit.and(unitIsSea())
			territory_is_water_p, territory_is_water_c := matches_territory_is_water()
			neighbors := game_map_get_neighbors_predicate(
				game_state_get_map(data),
				t,
				territory_is_water_p,
				territory_is_water_c,
			)
			for current in neighbors {
				for cand in current.unit_collection.units {
					if allied_unit_p(allied_unit_c, cand) &&
					   gives_bonus_to_unit_p(gives_bonus_to_unit_c, cand) &&
					   is_sea_p(is_sea_c, cand) {
						append(&gives_bonus_units, cand)
					}
				}
			}
		}
		for bonus_giver in gives_bonus_units {
			gm := unit_attachment_get_gives_movement(unit_get_unit_attachment(bonus_giver))
			temp_bonus := gm[unit_get_type(u)]
			if temp_bonus > bonus_movement {
				bonus_movement = temp_bonus
			}
		}
		if bonus_movement != min(i32) && bonus_movement != 0 {
			max_neg := -unit_attachment_get_movement(unit_get_unit_attachment(u), player)
			if max_neg > bonus_movement {
				bonus_movement = max_neg
			}
			boxed := new(i32)
			boxed^ = bonus_movement
			composite_change_add(
				change,
				change_factory_unit_property_change(
					u,
					rawptr(boxed),
					unit_property_name_to_string(&prop_bonus_movement),
				),
			)
		}
	}
	return &change.change
}

// games.strategy.triplea.delegate.MoveDelegate#getLargestRepairRateForThisUnit(
//     games.strategy.engine.data.Unit,
//     games.strategy.engine.data.Territory,
//     games.strategy.engine.data.GameState)
// "This has to be the exact same as Matches.UnitCanBeRepairedByFacilitiesInItsTerritory()."
// If the property `TWO_HIT_POINT_UNITS_REQUIRE_REPAIR_FACILITIES` is off,
// every unit repairs at rate 1. Otherwise scan the unit's territory for
// allied repair-capable units that can repair this unit (via Matches);
// when the unit is sea, also scan adjacent land territories for allied
// land repair facilities, and when it is land, scan adjacent water
// territories for allied sea repair facilities. Return the maximum
// per-unit-type repair value from `UnitAttachment.repairsUnits`.
move_delegate_get_largest_repair_rate_for_this_unit :: proc(
	unit_to_be_repaired: ^Unit,
	territory_unit_is_in: ^Territory,
	data: ^Game_State,
) -> i32 {
	if !properties_get_two_hit_point_units_require_repair_facilities(
		game_state_get_properties(data),
	) {
		return 1
	}
	owner := unit_get_owner(unit_to_be_repaired)
	allied_p, allied_c := matches_allied_unit(owner)
	repair_others_p, repair_others_c := matches_unit_can_repair_others()
	repair_this_in_t_p, repair_this_in_t_c :=
		matches_unit_can_repair_this_unit(unit_to_be_repaired, territory_unit_is_in)
	is_sea_p, is_sea_c := matches_unit_is_sea()
	is_land_p, is_land_c := matches_unit_is_land()
	repair_units_for_this_unit: map[^Unit]struct{}
	for u in territory_unit_is_in.unit_collection.units {
		if allied_p(allied_c, u) &&
		   repair_others_p(repair_others_c, u) &&
		   repair_this_in_t_p(repair_this_in_t_c, u) {
			repair_units_for_this_unit[u] = {}
		}
	}
	if is_sea_p(is_sea_c, unit_to_be_repaired) {
		territory_is_land_p, territory_is_land_c := matches_territory_is_land()
		neighbors := game_map_get_neighbors_predicate(
			game_state_get_map(data),
			territory_unit_is_in,
			territory_is_land_p,
			territory_is_land_c,
		)
		for current in neighbors {
			repair_this_in_n_p, repair_this_in_n_c :=
				matches_unit_can_repair_this_unit(unit_to_be_repaired, current)
			for u in current.unit_collection.units {
				if allied_p(allied_c, u) &&
				   repair_others_p(repair_others_c, u) &&
				   repair_this_in_n_p(repair_this_in_n_c, u) &&
				   is_land_p(is_land_c, u) {
					repair_units_for_this_unit[u] = {}
				}
			}
		}
	} else if is_land_p(is_land_c, unit_to_be_repaired) {
		territory_is_water_p, territory_is_water_c := matches_territory_is_water()
		neighbors := game_map_get_neighbors_predicate(
			game_state_get_map(data),
			territory_unit_is_in,
			territory_is_water_p,
			territory_is_water_c,
		)
		for current in neighbors {
			repair_this_in_n_p, repair_this_in_n_c :=
				matches_unit_can_repair_this_unit(unit_to_be_repaired, current)
			for u in current.unit_collection.units {
				if allied_p(allied_c, u) &&
				   repair_others_p(repair_others_c, u) &&
				   repair_this_in_n_p(repair_this_in_n_c, u) &&
				   is_sea_p(is_sea_c, u) {
					repair_units_for_this_unit[u] = {}
				}
			}
		}
	}
	largest: i32 = 0
	for u in repair_units_for_this_unit {
		ru := unit_attachment_get_repairs_units(unit_get_unit_attachment(u))
		repair := ru[unit_get_type(unit_to_be_repaired)]
		if largest < repair {
			largest = repair
		}
	}
	return largest
}

// games.strategy.triplea.delegate.MoveDelegate#delegateCurrentlyRequiresUserInput()
// Java:
//   final Predicate<Unit> moveableUnitOwnedByMe =
//       PredicateBuilder.of(Matches.unitIsOwnedBy(player))
//           .and(Matches.unitHasMovementLeft()
//                .or(Matches.unitIsLand().and(Matches.unitIsBeingTransported())))
//           .andIf(GameStepPropertiesHelper.isCombatMove(getData()),
//                  Matches.unitCanNotMoveDuringCombatMove().negate())
//           .build();
//   return !getData().getMap().getTerritories().isEmpty()
//       && getData().getMap().getTerritories().stream()
//             .anyMatch(t -> t.anyUnitsMatch(moveableUnitOwnedByMe));
// The Java predicate captures `player` (and conditionally the combat-move
// flag) so we materialize it as a (proc, ctx) pair following the rawptr
// convention; the territory-stream lambda is the existing
// `move_delegate_lambda_delegate_currently_requires_user_input_0`.
Move_Delegate_Moveable_Unit_Owned_By_Me_Ctx :: struct {
	owned_p:                proc(rawptr, ^Unit) -> bool,
	owned_c:                rawptr,
	has_movement_p:         proc(rawptr, ^Unit) -> bool,
	has_movement_c:         rawptr,
	is_land_p:              proc(rawptr, ^Unit) -> bool,
	is_land_c:              rawptr,
	is_being_transported_p: proc(rawptr, ^Unit) -> bool,
	is_being_transported_c: rawptr,
	is_combat_move:         bool,
	cannot_move_combat_p:   proc(rawptr, ^Unit) -> bool,
	cannot_move_combat_c:   rawptr,
}

move_delegate_moveable_unit_owned_by_me_pred :: proc(ctx: rawptr, u: ^Unit) -> bool {
	c := cast(^Move_Delegate_Moveable_Unit_Owned_By_Me_Ctx)ctx
	if !c.owned_p(c.owned_c, u) {
		return false
	}
	// hasMovementLeft OR (isLand AND isBeingTransported)
	if !(c.has_movement_p(c.has_movement_c, u) ||
		   (c.is_land_p(c.is_land_c, u) &&
			   c.is_being_transported_p(c.is_being_transported_c, u))) {
		return false
	}
	// .andIf(isCombatMove, unitCanNotMoveDuringCombatMove().negate())
	if c.is_combat_move {
		if c.cannot_move_combat_p(c.cannot_move_combat_c, u) {
			return false
		}
	}
	return true
}

move_delegate_delegate_currently_requires_user_input :: proc(self: ^Move_Delegate) -> bool {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	inner := new(Move_Delegate_Moveable_Unit_Owned_By_Me_Ctx)
	inner.owned_p, inner.owned_c = matches_unit_is_owned_by(self.player)
	inner.has_movement_p, inner.has_movement_c = matches_unit_has_movement_left()
	inner.is_land_p, inner.is_land_c = matches_unit_is_land()
	inner.is_being_transported_p, inner.is_being_transported_c =
		matches_unit_is_being_transported()
	inner.is_combat_move = game_step_properties_helper_is_combat_move(data)
	inner.cannot_move_combat_p, inner.cannot_move_combat_c =
		matches_unit_can_not_move_during_combat_move()

	outer := new(Move_Delegate_Delegate_Currently_Requires_User_Input_0_Ctx)
	outer.moveable_unit_owned_by_me = move_delegate_moveable_unit_owned_by_me_pred
	outer.moveable_unit_owned_by_me_ctx = rawptr(inner)

	territories := game_map_get_territories(game_state_get_map(&data.game_state))
	if len(territories) == 0 {
		return false
	}
	for t in territories {
		if move_delegate_lambda_delegate_currently_requires_user_input_0(rawptr(outer), t) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.MoveDelegate#giveBonusMovement(IDelegateBridge, GamePlayer)
// Java:
//   final GameState data = bridge.getData();
//   final CompositeChange change = new CompositeChange();
//   for (final Territory t : data.getMap().getTerritories()) {
//     change.add(giveBonusMovementToUnits(player, data, t));
//   }
//   return change;
// Static; bridge.getData() returns ^Game_Data which embeds Game_State.
move_delegate_give_bonus_movement :: proc(
	bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
) -> ^Change {
	data := i_delegate_bridge_get_data(bridge)
	change := composite_change_new()
	for t in game_map_get_territories(game_state_get_map(&data.game_state)) {
		composite_change_add(
			change,
			move_delegate_give_bonus_movement_to_units(player, &data.game_state, t),
		)
	}
	return &change.change
}

// games.strategy.triplea.delegate.MoveDelegate#repairedChangeInto(
//     java.util.Set, games.strategy.engine.data.Territory,
//     games.strategy.engine.delegate.IDelegateBridge)
// Java:
//   final List<Unit> changesIntoUnits =
//       CollectionUtils.getMatches(units,
//           Matches.unitWhenHitPointsRepairedChangesInto());
//   ... walk each, look up tuple in unitAttachment.whenHitPointsRepairedChangesInto,
//       optionally translate attributes, accumulate add/remove lists.
// Static; receives a `Set<Unit>` which Odin renders as `map[^Unit]struct{}`.
move_delegate_repaired_change_into :: proc(
	units: map[^Unit]struct {},
	territory: ^Territory,
	bridge: ^I_Delegate_Bridge,
) {
	changes_into_p, changes_into_c := matches_unit_when_hit_points_repaired_changes_into()
	changes_into_units: [dynamic]^Unit
	for u, _ in units {
		if changes_into_p(changes_into_c, u) {
			append(&changes_into_units, u)
		}
	}
	changes := composite_change_new()
	units_to_remove: [dynamic]^Unit
	units_to_add: [dynamic]^Unit
	for unit in changes_into_units {
		m := unit_attachment_get_when_hit_points_repaired_changes_into(
			unit_get_unit_attachment(unit),
		)
		hits := unit_get_hits(unit)
		tup, ok := m[hits]
		if !ok {
			continue
		}
		translate_attributes := tuple_get_first(tup)
		unit_type := tuple_get_second(tup)
		to_add := unit_type_create_2(unit_type, 1, unit_get_owner(unit))
		if translate_attributes {
			translate := unit_utils_translate_attributes_to_other_units(
				unit,
				to_add,
				territory,
			)
			composite_change_add(changes, translate)
		}
		append(&units_to_remove, unit)
		for u in to_add {
			append(&units_to_add, u)
		}
	}
	if len(units_to_remove) > 0 {
		i_delegate_bridge_add_change(bridge, &changes.change)
		writer := i_delegate_bridge_get_history_writer(bridge)
		remove_text := fmt.aprintf(
			"%s removed in %s",
			my_formatter_units_to_text(units_to_remove),
			territory.named.base.name,
		)
		i_delegate_history_writer_add_child_to_event(writer, remove_text, rawptr(&units_to_remove))
		i_delegate_bridge_add_change(
			bridge,
			change_factory_remove_units(cast(^Unit_Holder)territory, units_to_remove),
		)
		add_text := fmt.aprintf(
			"%s added in %s",
			my_formatter_units_to_text(units_to_add),
			territory.named.base.name,
		)
		i_delegate_history_writer_add_child_to_event(writer, add_text, rawptr(&units_to_add))
		i_delegate_bridge_add_change(
			bridge,
			change_factory_add_units(cast(^Unit_Holder)territory, units_to_add),
		)
	}
}

// games.strategy.triplea.delegate.MoveDelegate#resetUnitStateAndDelegateState()
// Java:
//   pusLost.clear();
//   final Change change = getResetUnitStateChange(getData());
//   if (!change.isEmpty()) {
//     bridge.getHistoryWriter().startEvent(CLEANING_UP_DURING_MOVEMENT_PHASE);
//     bridge.addChange(change);
//   }
// CLEANING_UP_DURING_MOVEMENT_PHASE = "Cleaning up during movement phase".
move_delegate_reset_unit_state_and_delegate_state :: proc(self: ^Move_Delegate) {
	clear(&self.pus_lost)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	change := move_delegate_get_reset_unit_state_change(&data.game_state)
	if !change_is_empty(change) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			"Cleaning up during movement phase",
		)
		i_delegate_bridge_add_change(self.bridge, change)
	}
}

// games.strategy.triplea.delegate.MoveDelegate#removeMovementFromAirOnDamagedAlliedCarriers(
//     IDelegateBridge, GamePlayer)
// Java:
//   crippledAlliedCarriersMatch =
//     isUnitAllied(player).and(unitIsOwnedBy(player).negate())
//                         .and(unitIsCarrier())
//                         .and(unitHasWhenCombatDamagedEffect(UNITS_MAY_NOT_LEAVE_ALLIED_CARRIER))
//   ownedFightersMatch =
//     unitIsOwnedBy(player).and(unitIsAir()).and(unitCanLandOnCarrier())
//                          .and(unitHasMovementLeft())
//   For each territory: skip if no owned fighters, then for each fighter
//   whose `transportedBy` is one of the crippled allied carriers in that
//   territory, mark its movement as exhausted via `markNoMovementChange`.
// Static method.
move_delegate_remove_movement_from_air_on_damaged_allied_carriers :: proc(
	bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
) {
	data := i_delegate_bridge_get_data(bridge)
	allied_p, allied_c := matches_is_unit_allied(player)
	owned_p, owned_c := matches_unit_is_owned_by(player)
	carrier_p, carrier_c := matches_unit_is_carrier()
	leave_filter_p, leave_filter_c := matches_unit_has_when_combat_damaged_effect_filter(
		"unitsMayNotLeaveAlliedCarrier",
	)
	air_p, air_c := matches_unit_is_air()
	land_on_carrier_p, land_on_carrier_c := matches_unit_can_land_on_carrier()
	has_movement_p, has_movement_c := matches_unit_has_movement_left()
	change := composite_change_new()
	for t in game_map_get_territories(game_state_get_map(&data.game_state)) {
		owned_fighters: [dynamic]^Unit
		for u in t.unit_collection.units {
			if owned_p(owned_c, u) &&
			   air_p(air_c, u) &&
			   land_on_carrier_p(land_on_carrier_c, u) &&
			   has_movement_p(has_movement_c, u) {
				append(&owned_fighters, u)
			}
		}
		if len(owned_fighters) == 0 {
			continue
		}
		crippled_allied_carriers: map[^Unit]struct {}
		for u in t.unit_collection.units {
			if allied_p(allied_c, u) &&
			   !owned_p(owned_c, u) &&
			   carrier_p(carrier_c, u) &&
			   leave_filter_p(leave_filter_c, u) {
				crippled_allied_carriers[u] = {}
			}
		}
		if len(crippled_allied_carriers) == 0 {
			continue
		}
		for fighter in owned_fighters {
			tb := unit_get_transported_by(fighter)
			if tb != nil {
				if _, in_set := crippled_allied_carriers[tb]; in_set {
					composite_change_add(
						change,
						change_factory_mark_no_movement_change(fighter),
					)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
}

// games.strategy.triplea.delegate.MoveDelegate#repairMultipleHitPointUnits(
//     IDelegateBridge, GamePlayer)
// Java: scan every territory for damaged multi-HP units (filtered by
// owner / repair-facility properties), compute each unit's repair amount
// via getLargestRepairRateForThisUnit, build an Integer_Map<Unit> of new
// hit values plus a set of affected territories, emit a single
// "N unit(s) repaired." history event, then unitsHit change. Carriers
// that become fully repaired and bear UNITS_MAY_NOT_LEAVE_ALLIED_CARRIER
// have their dependent allied air cleared via TransportTracker, and any
// repaired unit that should change into a different unit type is run
// through repairedChangeInto. Static method.
move_delegate_repair_multiple_hit_point_units :: proc(
	bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
) {
	data := i_delegate_bridge_get_data(bridge)
	repair_only_own := properties_get_battleships_repair_at_beginning_of_round(
		game_state_get_properties(&data.game_state),
	)
	multi_hp_p, multi_hp_c := matches_unit_has_more_than_one_hit_point_total()
	taken_dmg_p, taken_dmg_c := matches_unit_has_taken_some_damage()
	owned_p, owned_c := matches_unit_is_owned_by(player)
	require_facilities := properties_get_two_hit_point_units_require_repair_facilities(
		game_state_get_properties(&data.game_state),
	)
	damaged_map: map[^Territory]map[^Unit]struct {}
	for current in game_map_get_territories(game_state_get_map(&data.game_state)) {
		damaged: map[^Unit]struct {}
		if !require_facilities {
			for u in current.unit_collection.units {
				if !(multi_hp_p(multi_hp_c, u) && taken_dmg_p(taken_dmg_c, u)) {
					continue
				}
				if repair_only_own && !owned_p(owned_c, u) {
					continue
				}
				damaged[u] = {}
			}
		} else {
			repair_here_p, repair_here_c :=
				matches_unit_can_be_repaired_by_facilities_in_its_territory(current, player)
			for u in current.unit_collection.units {
				if multi_hp_p(multi_hp_c, u) &&
				   taken_dmg_p(taken_dmg_c, u) &&
				   owned_p(owned_c, u) &&
				   repair_here_p(repair_here_c, u) {
					damaged[u] = {}
				}
			}
		}
		if len(damaged) > 0 {
			damaged_map[current] = damaged
		}
	}
	if len(damaged_map) == 0 {
		return
	}
	fully_repaired: map[^Unit]^Territory
	new_hits_map := new(Integer_Map_Unit)
	new_hits_map.entries = make(map[^Unit]i32)
	territories_to_notify_set: map[^Territory]struct {}
	for territory, units in damaged_map {
		for u, _ in units {
			repair_amount := move_delegate_get_largest_repair_rate_for_this_unit(
				u,
				territory,
				&data.game_state,
			)
			current_hits := unit_get_hits(u)
			candidate := current_hits - repair_amount
			new_hits: i32 = 0
			if candidate < current_hits {
				new_hits = candidate
			} else {
				new_hits = current_hits
			}
			if new_hits < 0 {
				new_hits = 0
			}
			if new_hits != current_hits {
				new_hits_map.entries[u] = new_hits
				territories_to_notify_set[territory] = {}
			}
			if new_hits <= 0 {
				fully_repaired[u] = territory
			}
		}
	}
	repaired_keys: [dynamic]^Unit
	for u, _ in new_hits_map.entries {
		append(&repaired_keys, u)
	}
	territories_to_notify: [dynamic]^Territory
	for t, _ in territories_to_notify_set {
		append(&territories_to_notify, t)
	}
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(bridge),
		fmt.aprintf(
			"%d %s repaired.",
			len(new_hits_map.entries),
			my_formatter_pluralize("unit"),
		),
		rawptr(&repaired_keys),
	)
	i_delegate_bridge_add_change(
		bridge,
		change_factory_units_hit(new_hits_map, territories_to_notify),
	)

	// Carriers that just got fully repaired and bear the
	// UNITS_MAY_NOT_LEAVE_ALLIED_CARRIER effect: clear their allied air's
	// transportedBy so the air can leave on its own.
	leave_filter_p, leave_filter_c := matches_unit_has_when_combat_damaged_effect_filter(
		"unitsMayNotLeaveAlliedCarrier",
	)
	damaged_carriers: [dynamic]^Unit
	for u, _ in fully_repaired {
		if leave_filter_p(leave_filter_c, u) {
			append(&damaged_carriers, u)
		}
	}
	clear_allied_air := composite_change_new()
	for carrier in damaged_carriers {
		one_carrier: [dynamic]^Unit
		append(&one_carrier, carrier)
		change := transport_tracker_clear_transported_by_for_allied_air_on_carrier(
			one_carrier,
			fully_repaired[carrier],
			unit_get_owner(carrier),
			&data.game_state,
		)
		if !composite_change_is_empty(change) {
			composite_change_add(clear_allied_air, &change.change)
		}
	}
	if !composite_change_is_empty(clear_allied_air) {
		i_delegate_bridge_add_change(bridge, &clear_allied_air.change)
	}

	// Any repaired unit that should change unit type when its hit-points
	// recover.
	for territory, units in damaged_map {
		move_delegate_repaired_change_into(units, territory, bridge)
	}
}

// games.strategy.triplea.delegate.MoveDelegate#resetAndGiveBonusMovement()
// Java:
//   addedHistoryEvent = false
//   changeReset = resetBonusMovement()
//   if (!changeReset.isEmpty()) {
//     bridge.getHistoryWriter().startEvent("Resetting and Giving Bonus Movement to Units")
//     bridge.addChange(changeReset)
//     addedHistoryEvent = true
//   }
//   if (Properties.getUnitsMayGiveBonusMovement(getData().getProperties())) {
//     changeBonus = giveBonusMovement(bridge, player)
//   }
//   if (changeBonus != null && !changeBonus.isEmpty()) {
//     if (!addedHistoryEvent) bridge.getHistoryWriter().startEvent(...)
//     bridge.addChange(changeBonus)
//   }
// Private instance method.
move_delegate_reset_and_give_bonus_movement :: proc(self: ^Move_Delegate) {
	added_history_event := false
	change_reset := move_delegate_reset_bonus_movement(self)
	if !change_is_empty(change_reset) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			"Resetting and Giving Bonus Movement to Units",
		)
		i_delegate_bridge_add_change(self.bridge, change_reset)
		added_history_event = true
	}
	change_bonus: ^Change = nil
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if properties_get_units_may_give_bonus_movement(
		game_state_get_properties(&data.game_state),
	) {
		change_bonus = move_delegate_give_bonus_movement(self.bridge, self.player)
	}
	if change_bonus != nil && !change_is_empty(change_bonus) {
		if !added_history_event {
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(self.bridge),
				"Resetting and Giving Bonus Movement to Units",
			)
		}
		i_delegate_bridge_add_change(self.bridge, change_bonus)
	}
}

// games.strategy.triplea.delegate.MoveDelegate#removeAirThatCantLand()
// Java:
//   final GameData data = getData();
//   final boolean lhtrCarrierProd =
//       Properties.getLhtrCarrierProductionRules(data.getProperties())
//           || Properties.getLandExistingFightersOnNewCarriers(data.getProperties());
//   boolean hasProducedCarriers = false;
//   for (final GamePlayer p : GameStepPropertiesHelper.getCombinedTurns(data, player)) {
//     if (p.anyUnitsMatch(Matches.unitIsCarrier())) { hasProducedCarriers = true; break; }
//   }
//   final AirThatCantLandUtil util = new AirThatCantLandUtil(bridge);
//   util.removeAirThatCantLand(player, lhtrCarrierProd && hasProducedCarriers);
//   for (final GamePlayer player : data.getPlayerList()) {
//     if (!player.equals(this.player)) {
//       util.removeAirThatCantLand(
//           player,
//           ((player.anyUnitsMatch(Matches.unitIsCarrier()) || hasProducedCarriers) && lhtrCarrierProd));
//     }
//   }
//
// `p.anyUnitsMatch(Matches.unitIsCarrier())` is the UnitHolder default
// method (GamePlayer is a UnitHolder via its embedded UnitCollection).
// Matches.unitIsCarrier returns the rawptr-style (fn, ctx) Predicate
// pair, which is incompatible with the no-ctx `unit_holder_any_units_match`
// signature, so the carrier check is inlined as a manual scan over the
// player's held units — mirroring the same pattern used in
// air_that_cant_land_util_get_territories_where_air_cant_land.
move_delegate_remove_air_that_cant_land :: proc(self: ^Move_Delegate) {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	props := game_data_get_properties(data)
	lhtr_carrier_prod :=
		properties_get_lhtr_carrier_production_rules(props) ||
		properties_get_land_existing_fighters_on_new_carriers(props)
	has_produced_carriers := false
	is_carrier_pred, is_carrier_ctx := matches_unit_is_carrier()
	combined := game_step_properties_helper_get_combined_turns(data, self.player)
	defer delete(combined)
	for p in combined {
		held := unit_holder_get_units(cast(^Unit_Holder)p)
		any_carrier := false
		for u in held {
			if is_carrier_pred(is_carrier_ctx, u) {
				any_carrier = true
				break
			}
		}
		delete(held)
		if any_carrier {
			has_produced_carriers = true
			break
		}
	}
	util := air_that_cant_land_util_new(self.bridge)
	air_that_cant_land_util_remove_air_that_cant_land(
		util,
		self.player,
		lhtr_carrier_prod && has_produced_carriers,
	)
	// if edit mode has been on, we need to clean up after all players
	for player in player_list_get_players(game_data_get_player_list(data)) {
		if player == self.player {
			continue
		}
		held := unit_holder_get_units(cast(^Unit_Holder)player)
		any_carrier := false
		for u in held {
			if is_carrier_pred(is_carrier_ctx, u) {
				any_carrier = true
				break
			}
		}
		delete(held)
		air_that_cant_land_util_remove_air_that_cant_land(
			util,
			player,
			(any_carrier || has_produced_carriers) && lhtr_carrier_prod,
		)
	}
}

// IRemotePlayer methods that aren't carried by the Odin Player vtable.
// The only Player implementation reachable in the AI snapshot harness
// is AbstractAi (Java AbstractAi#confirmMoveKamikaze == false,
// AbstractAi#confirmMoveInFaceOfAa == true). Inline those defaults so
// we can faithfully model the Java control flow without extending the
// Player struct from this file.
move_delegate_remote_confirm_move_kamikaze :: proc(remote: ^Player) -> bool {
	_ = remote
	return false
}

move_delegate_remote_confirm_move_in_face_of_aa :: proc(
	remote: ^Player,
	aa_firing_territories: [dynamic]^Territory,
) -> bool {
	_ = remote
	_ = aa_firing_territories
	return true
}

// games.strategy.triplea.delegate.MoveDelegate#performMove(games.strategy.engine.data.MoveDescription)
// Java:
//   public Optional<String> performMove(final MoveDescription move) {
//     final GameData data = getData();
//     final GamePlayer player = getUnitsOwner(move.getUnits());
//     final MoveValidationResult result =
//         new MoveValidator(data, GameStepPropertiesHelper.isNonCombatMove(data, false))
//             .validateMove(move, player, movesToUndo);
//     ...
//     return Optional.empty();
//   }
//
// Optional<String> is modeled as a plain `string` per the convention
// adopted across the port (see pro_move_utils.do_move and
// move_validator.validate_*): "" means Optional.empty(), any
// non-empty string means Optional.of(<error>).
move_delegate_perform_move :: proc(self: ^Move_Delegate, move: ^Move_Description) -> string {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	// In edit mode the unit owner can differ from the current player.
	player := abstract_move_delegate_get_units_owner(
		&self.abstract_move_delegate,
		move.units,
	)
	validator := move_validator_new(
		data,
		game_step_properties_helper_is_non_combat_move(data, false),
	)
	result := move_validator_validate_move(
		validator,
		move,
		player,
		self.moves_to_undo,
	)
	num_problems := move_validation_result_get_total_warning_count(result)
	if !move_validation_result_has_error(result) {
		num_problems -= 1
	}
	num_errors_msg: string = ""
	if num_problems > 0 {
		num_errors_msg = fmt.aprintf(
			"; %d %s not shown",
			num_problems,
			my_formatter_pluralize_quantity("error", i32(num_problems)),
		)
	}
	if move_validation_result_has_error(result) {
		return fmt.aprintf(
			"%s%s",
			move_validation_result_get_error(result),
			num_errors_msg,
		)
	}
	if move_validation_result_has_disallowed_units(result) {
		return fmt.aprintf(
			"%s%s",
			move_validation_result_get_disallowed_unit_warning(result, 0),
			num_errors_msg,
		)
	}

	is_kamikaze := false
	get_kamikaze_air := properties_get_kamikaze_airplanes(game_data_get_properties(data))
	kamikaze_units: [dynamic]^Unit = make([dynamic]^Unit)

	// Confirm kamikaze moves and remove them from unresolved units.
	any_kamikaze := false
	if !get_kamikaze_air {
		is_kamikaze_pred, is_kamikaze_ctx := matches_unit_is_kamikaze()
		for u in move.units {
			if is_kamikaze_pred(is_kamikaze_ctx, u) {
				any_kamikaze = true
				break
			}
		}
	}
	if get_kamikaze_air || any_kamikaze {
		delete(kamikaze_units)
		kamikaze_units = move_validation_result_get_unresolved_units(
			result,
			NOT_ALL_AIR_UNITS_CAN_LAND,
		)
		remote := i_delegate_bridge_get_remote_player(self.bridge)
		if len(kamikaze_units) != 0 && move_delegate_remote_confirm_move_kamikaze(remote) {
			is_kamikaze_pred, is_kamikaze_ctx := matches_unit_is_kamikaze()
			for unit in kamikaze_units {
				if get_kamikaze_air || is_kamikaze_pred(is_kamikaze_ctx, unit) {
					move_validation_result_remove_unresolved_unit(
						result,
						NOT_ALL_AIR_UNITS_CAN_LAND,
						unit,
					)
					is_kamikaze = true
				}
			}
		}
	}
	if move_validation_result_has_unresolved_units(result) {
		return fmt.aprintf(
			"%s%s",
			move_validation_result_get_unresolved_unit_warning(result, 0),
			num_errors_msg,
		)
	}

	// Allow user to cancel move if AA guns will fire.
	aa_in_move_util := aa_in_move_util_new()
	aa_in_move_util_initialize(aa_in_move_util, self.bridge)
	aa_firing_territories := aa_in_move_util_get_territories_where_aa_will_fire(
		aa_in_move_util,
		move_description_get_route(move),
		move.units,
	)
	if len(aa_firing_territories) != 0 {
		remote := i_delegate_bridge_get_remote_player(self.bridge)
		if !move_delegate_remote_confirm_move_in_face_of_aa(remote, aa_firing_territories) {
			return ""
		}
	}

	// Do the move.
	route := move_description_get_route(move)
	current_move := undoable_move_new(move.units, route)
	transcript_text := fmt.aprintf(
		"%s moved from %s to %s",
		my_formatter_units_to_text_no_owner(move.units, nil),
		territory_get_name(route_get_start(route)),
		territory_get_name(route_get_end(route)),
	)
	writer := i_delegate_bridge_get_history_writer(self.bridge)
	i_delegate_history_writer_start_event(
		writer,
		transcript_text,
		rawptr(undoable_move_get_description_object(current_move)),
	)
	if is_kamikaze {
		// Java: writer.addChildToEvent(
		//     "This was a kamikaze move, for at least some of the units",
		//     kamikazeUnits);
		// I_Delegate_History_Writer's Odin vtable models only startEvent
		// (see i_delegate_history_writer.odin); addChildToEvent is not
		// modeled. Statically this branch is unreachable in the AI
		// snapshot run because confirmMoveKamikaze defaults to false
		// (AbstractAi#103, mirrored in
		// move_delegate_remote_confirm_move_kamikaze above).
		_ = kamikaze_units
	}
	self.temp_move_performer = move_performer_new()
	move_performer_initialize(self.temp_move_performer, &self.abstract_move_delegate)
	move_performer_move_units(self.temp_move_performer, move, player, current_move)
	self.temp_move_performer = nil
	return ""
}

// AND/OR-chained Predicate<TriggerAttachment> used by MoveDelegate.start():
//   moveCombatDelegateBeforeBonusTriggerMatch =
//     availableUses
//       .and(whenOrDefaultMatch(null, null))
//       .and(notificationMatch
//         .or(playerPropertyMatch).or(relationshipTypePropertyMatch)
//         .or(territoryPropertyMatch).or(territoryEffectPropertyMatch)
//         .or(removeUnitsMatch).or(changeOwnershipMatch))
//   moveCombatDelegateAfterBonusTriggerMatch =
//     availableUses
//       .and(whenOrDefaultMatch(null, null))
//       .and(placeMatch())
//   moveCombatDelegateAllTriggerMatch = before.or(after)
//
// Only `whenOrDefaultMatch` carries a captured (proc, rawptr) pair; every
// other factory returns a non-capturing bare proc. The shared ctx
// therefore stores only the when-pair.
Move_Delegate_Ctx_start_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

move_delegate_lambda_start_before_bonus_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Move_Delegate_Ctx_start_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	if abstract_trigger_attachment_lambda_notification_match_4(t) {
		return true
	}
	if trigger_attachment_lambda_player_property_match(t) {
		return true
	}
	if trigger_attachment_lambda_relationship_type_property_match(t) {
		return true
	}
	if trigger_attachment_lambda_territory_property_match(t) {
		return true
	}
	if trigger_attachment_lambda_territory_effect_property_match(t) {
		return true
	}
	if trigger_attachment_lambda_remove_units_match(t) {
		return true
	}
	return trigger_attachment_lambda_change_ownership_match(t)
}

move_delegate_lambda_start_after_bonus_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Move_Delegate_Ctx_start_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	return trigger_attachment_lambda_place_match(t)
}

move_delegate_lambda_start_all_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	if move_delegate_lambda_start_before_bonus_trigger_match(ctx_ptr, t) {
		return true
	}
	return move_delegate_lambda_start_after_bonus_trigger_match(ctx_ptr, t)
}

// games.strategy.triplea.delegate.MoveDelegate#start()
// Java body translated branch-for-branch. On the first invocation per turn
// (`needToInitialize`):
//   - On a combat-move step with triggers enabled, fire every available
//     before-bonus territory/property/notification/etc. trigger attached
//     to `player`.
//   - If the step asks for repair, run `repairMultipleHitPointUnits`.
//   - If the step asks for bonus movement, run
//     `resetAndGiveBonusMovement`.
//   - Always strip movement from owned air sitting on damaged allied
//     carriers.
//   - On a combat-move step with triggers, fire after-bonus place
//     triggers.
//   - If the step asks for unit-state reset at start, run it.
move_delegate_start :: proc(self: ^Move_Delegate) {
	abstract_move_delegate_start(&self.abstract_move_delegate)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if self.need_to_initialize {
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
		match_ctx := new(Move_Delegate_Ctx_start_trigger_match)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx

		tested_conditions: map[^I_Condition]bool
		have_tested_conditions := false

		if game_step_properties_helper_is_combat_move(data) &&
		   properties_get_triggers(game_data_get_properties(data)) {
			players_set := make(map[^Game_Player]struct {})
			defer delete(players_set)
			players_set[self.player] = {}

			to_fire_possible := trigger_attachment_collect_for_all_triggers_matching(
				players_set,
				move_delegate_lambda_start_all_trigger_match,
				rawptr(match_ctx),
			)
			if len(to_fire_possible) != 0 {
				tested_conditions = trigger_attachment_collect_tests_for_all_triggers_simple(
					to_fire_possible,
					self.bridge,
				)
				have_tested_conditions = true

				to_fire_before_bonus := trigger_attachment_collect_for_all_triggers_matching(
					players_set,
					move_delegate_lambda_start_before_bonus_trigger_match,
					rawptr(match_ctx),
				)
				if len(to_fire_before_bonus) != 0 {
					satisfied_pred, satisfied_ctx := abstract_trigger_attachment_is_satisfied_match(
						tested_conditions,
					)
					to_fire_tested_and_satisfied := make(map[^Trigger_Attachment]struct {})
					defer delete(to_fire_tested_and_satisfied)
					for t in to_fire_before_bonus {
						if satisfied_pred(satisfied_ctx, t) {
							to_fire_tested_and_satisfied[t] = {}
						}
					}
					fire_trigger_params := fire_trigger_params_new(
						"", "", true, true, true, true,
					)
					trigger_attachment_trigger_notifications(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_player_property_change(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_relationship_type_property_change(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_territory_property_change(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_territory_effect_property_change(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_change_ownership(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
					trigger_attachment_trigger_unit_removal(
						to_fire_tested_and_satisfied,
						self.bridge,
						fire_trigger_params,
					)
				}
			}
		}

		if game_step_properties_helper_is_repair_units(data) {
			move_delegate_repair_multiple_hit_point_units(self.bridge, self.player)
		}

		if game_step_properties_helper_is_give_bonus_movement(data) {
			move_delegate_reset_and_give_bonus_movement(self)
		}

		move_delegate_remove_movement_from_air_on_damaged_allied_carriers(
			self.bridge,
			self.player,
		)

		if game_step_properties_helper_is_combat_move(data) &&
		   properties_get_triggers(game_data_get_properties(data)) {
			players_set := make(map[^Game_Player]struct {})
			defer delete(players_set)
			players_set[self.player] = {}

			to_fire_after_bonus := trigger_attachment_collect_for_all_triggers_matching(
				players_set,
				move_delegate_lambda_start_after_bonus_trigger_match,
				rawptr(match_ctx),
			)
			if len(to_fire_after_bonus) != 0 {
				if !have_tested_conditions {
					tested_conditions = trigger_attachment_collect_tests_for_all_triggers_simple(
						to_fire_after_bonus,
						self.bridge,
					)
					have_tested_conditions = true
				}
				satisfied_pred, satisfied_ctx := abstract_trigger_attachment_is_satisfied_match(
					tested_conditions,
				)
				to_fire_tested_and_satisfied := make(map[^Trigger_Attachment]struct {})
				defer delete(to_fire_tested_and_satisfied)
				for t in to_fire_after_bonus {
					if satisfied_pred(satisfied_ctx, t) {
						to_fire_tested_and_satisfied[t] = {}
					}
				}
				trigger_attachment_trigger_unit_placement(
					to_fire_tested_and_satisfied,
					self.bridge,
					fire_trigger_params_new("", "", true, true, true, true),
				)
			}
		}

		if game_step_properties_helper_is_reset_unit_state_at_start(data) {
			move_delegate_reset_unit_state_and_delegate_state(self)
		}
		self.need_to_initialize = false
	}
}

// games.strategy.triplea.delegate.MoveDelegate#end()
// Java body translated branch-for-branch:
//   - super.end() (clears moves_to_undo via Abstract_Move_Delegate).
//   - If the step requests it, remove air units that cannot land.
//   - In WW2V1 non-combat, fire rockets exactly once per turn.
//   - If the step asks for end-of-step unit-state reset, run it. Otherwise
//     mark every non-air unit that has moved as having no movement left
//     (air units may move during both CM and NCM, so they're spared).
//   - Re-arm `needToInitialize` and `needToDoRockets` for the next turn.
move_delegate_end :: proc(self: ^Move_Delegate) {
	abstract_move_delegate_end(&self.abstract_move_delegate)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if game_step_properties_helper_is_remove_air_that_can_not_land(data) {
		move_delegate_remove_air_that_cant_land(self)
	}
	if self.need_to_do_rockets &&
	   game_step_properties_helper_is_non_combat_move(data, true) {
		rockets_fire_helper_fire_ww2_v1_if_needed(self.bridge)
		self.need_to_do_rockets = false
	}
	if game_step_properties_helper_is_reset_unit_state_at_end(data) {
		move_delegate_reset_unit_state_and_delegate_state(self)
	} else {
		has_moved_pred, has_moved_ctx := matches_unit_has_moved()
		not_air_pred, not_air_ctx := matches_unit_is_not_air()
		already_moved_non_air_units: [dynamic]^Unit
		defer delete(already_moved_non_air_units)
		for u in units_list_get_units(game_data_get_units(data)) {
			if has_moved_pred(has_moved_ctx, u) && not_air_pred(not_air_ctx, u) {
				append(&already_moved_non_air_units, u)
			}
		}
		i_delegate_bridge_add_change(
			self.bridge,
			change_factory_mark_no_movement_change_collection(already_moved_non_air_units),
		)
	}
	self.need_to_initialize = true
	self.need_to_do_rockets = true
}
