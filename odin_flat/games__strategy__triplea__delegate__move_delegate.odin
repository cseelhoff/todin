package game

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
	return self
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
