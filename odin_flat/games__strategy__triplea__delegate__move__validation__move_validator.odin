package game

import "core:fmt"

Move_Validator :: struct {
	data:          ^Game_Data,
	is_non_combat: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.move.validation.MoveValidator

// Java: @AllArgsConstructor MoveValidator(GameData data, boolean isNonCombat).
move_validator_new :: proc(data: ^Game_Data, is_non_combat: bool) -> ^Move_Validator {
	self := new(Move_Validator)
	self.data = data
	self.is_non_combat = is_non_combat
	return self
}

// Java: addToMapping computeIfAbsent mapping function:
//   key -> new ArrayList<>()
// Returns a freshly allocated empty dynamic array of ^Unit (caller owns it).
move_validator_lambda_add_to_mapping_10 :: proc(key: ^Unit) -> [dynamic]^Unit {
	_ = key
	return make([dynamic]^Unit)
}

// Java: getBestRoute fallback predicate `it -> true` over Territory.
move_validator_lambda_get_best_route_11 :: proc(it: ^Territory) -> bool {
	_ = it
	return true
}

// Java: validateAirborneMovements over-capacity slice predicate `it -> true`
// over Unit (passed to CollectionUtils.getNMatches).
move_validator_lambda_validate_airborne_movements_12 :: proc(it: ^Unit) -> bool {
	_ = it
	return true
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$enemyDestroyerOnPath$9
// Java: (Predicate<Unit> destroyerMatch, Territory t) -> t.anyUnitsMatch(destroyerMatch)
// The captured Predicate<Unit> is carried as a (fn, ctx) pair per the
// rawptr-ctx convention in llm-instructions.md.
Move_Validator_Enemy_Destroyer_On_Path_9_Ctx :: struct {
	destroyer_match:     proc(rawptr, ^Unit) -> bool,
	destroyer_match_ctx: rawptr,
}

move_validator_lambda_enemy_destroyer_on_path_9 :: proc(ctx: rawptr, t: ^Territory) -> bool {
	c := cast(^Move_Validator_Enemy_Destroyer_On_Path_9_Ctx)ctx
	return territory_any_units_match(t, c.destroyer_match, c.destroyer_match_ctx)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getTerritoryTransportHasUnloadedTo
// Java: scan undoableMoves for the first move that unloaded `transport` and
// return that move's route end territory; null if none.
move_validator_get_territory_transport_has_unloaded_to :: proc(
	undoable_moves: [dynamic]^Undoable_Move,
	transport: ^Unit,
) -> ^Territory {
	for undoable_move in undoable_moves {
		if undoable_move_was_transport_unloaded(undoable_move, transport) {
			return route_get_end(undoable_move_get_route(undoable_move))
		}
	}
	return nil
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$findNonDependentUnits$7
// Java: u -> u.getTransportedBy() != null  (used as a removeIf predicate).
move_validator_lambda_find_non_dependent_units_7 :: proc(u: ^Unit) -> bool {
	return unit_get_transported_by(u) != nil
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$noEnemyUnitsOnPathMiddleSteps$8
// Java: (Predicate<Unit> alliedOrNonCombat, Territory current) ->
//          current.getUnitCollection().allMatch(alliedOrNonCombat)
// The captured Predicate<Unit> is carried as a (fn, ctx) pair per the
// rawptr-ctx convention in llm-instructions.md.
Move_Validator_No_Enemy_Units_On_Path_Middle_Steps_8_Ctx :: struct {
	allied_or_non_combat:     proc(rawptr, ^Unit) -> bool,
	allied_or_non_combat_ctx: rawptr,
}

move_validator_lambda_no_enemy_units_on_path_middle_steps_8 :: proc(
	ctx: rawptr,
	current: ^Territory,
) -> bool {
	c := cast(^Move_Validator_No_Enemy_Units_On_Path_Middle_Steps_8_Ctx)ctx
	uc := territory_get_unit_collection(current)
	for u in uc.units {
		if !c.allied_or_non_combat(c.allied_or_non_combat_ctx, u) {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateBasic$3
// Java: unit -> Matches.unitHasEnoughMovementForRoute(route).test(unit)
Move_Validator_Validate_Basic_3_Ctx :: struct {
	route: ^Route,
}

move_validator_lambda_validate_basic_3 :: proc(ctx: rawptr, unit: ^Unit) -> bool {
	c := cast(^Move_Validator_Validate_Basic_3_Ctx)ctx
	p, pc := matches_unit_has_enough_movement_for_route(c.route)
	return p(pc, unit)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateBasic$4
// Java: unit -> !Matches.unitHasEnoughMovementForRoute(route).test(unit)
Move_Validator_Validate_Basic_4_Ctx :: struct {
	route: ^Route,
}

move_validator_lambda_validate_basic_4 :: proc(ctx: rawptr, unit: ^Unit) -> bool {
	c := cast(^Move_Validator_Validate_Basic_4_Ctx)ctx
	p, pc := matches_unit_has_enough_movement_for_route(c.route)
	return !p(pc, unit)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateBasic$5
// Java: unit -> result.addDisallowedUnit("Not all units have enough movement", unit)
Move_Validator_Validate_Basic_5_Ctx :: struct {
	result: ^Move_Validation_Result,
}

move_validator_lambda_validate_basic_5 :: proc(ctx: rawptr, unit: ^Unit) {
	c := cast(^Move_Validator_Validate_Basic_5_Ctx)ctx
	move_validation_result_add_disallowed_unit(
		c.result,
		"Not all units have enough movement",
		unit,
	)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateCanal$1
// Java: unit -> !unitsThatFailCanal.contains(unit)
//          && Matches.unitHasEnoughMovementForRoute(route).test(unit)
Move_Validator_Validate_Canal_1_Ctx :: struct {
	units_that_fail_canal: map[^Unit]struct {},
	route:                 ^Route,
}

move_validator_lambda_validate_canal_1 :: proc(ctx: rawptr, unit: ^Unit) -> bool {
	c := cast(^Move_Validator_Validate_Canal_1_Ctx)ctx
	if _, ok := c.units_that_fail_canal[unit]; ok {
		return false
	}
	p, pc := matches_unit_has_enough_movement_for_route(c.route)
	return p(pc, unit)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateCanal$2
// Java: unit -> unitsThatFailCanal.contains(unit)
//          || !Matches.unitHasEnoughMovementForRoute(route).test(unit)
Move_Validator_Validate_Canal_2_Ctx :: struct {
	units_that_fail_canal: map[^Unit]struct {},
	route:                 ^Route,
}

move_validator_lambda_validate_canal_2 :: proc(ctx: rawptr, unit: ^Unit) -> bool {
	c := cast(^Move_Validator_Validate_Canal_2_Ctx)ctx
	if _, ok := c.units_that_fail_canal[unit]; ok {
		return true
	}
	p, pc := matches_unit_has_enough_movement_for_route(c.route)
	return !p(pc, unit)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateFirstUnits$0
// Java:
//   unit -> {
//     if (unit.getSubmerged()) {
//       result.addDisallowedUnit("Cannot move submerged units", unit);
//     } else if (Matches.unitIsDisabled().test(unit)) {
//       result.addDisallowedUnit("Cannot move disabled units", unit);
//     }
//   }
Move_Validator_Validate_First_Units_0_Ctx :: struct {
	result: ^Move_Validation_Result,
}

move_validator_lambda_validate_first_units_0 :: proc(ctx: rawptr, unit: ^Unit) {
	c := cast(^Move_Validator_Validate_First_Units_0_Ctx)ctx
	if unit_get_submerged(unit) {
		move_validation_result_add_disallowed_unit(c.result, "Cannot move submerged units", unit)
		return
	}
	p, pc := matches_unit_is_disabled()
	if p(pc, unit) {
		move_validation_result_add_disallowed_unit(c.result, "Cannot move disabled units", unit)
	}
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateFirstUnits
// Java (private static): emits an error or per-unit disallow flags for the
// first-pass unit checks. Mirrors the Java if/else-if/else chain exactly.
move_validator_validate_first_units :: proc(
	units: [dynamic]^Unit,
	route: ^Route,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if len(units) == 0 {
		move_validation_result_set_error(result, "No units")
	} else if !unit_collection_contains_all(
		territory_get_unit_collection(route_get_start(route)),
		units,
	) {
		move_validation_result_set_error(result, "Not enough units in starting territory")
	} else {
		// Java: new HashSet<>(units).size() != units.size()
		unique := make(map[^Unit]struct {}, len(units))
		defer delete(unique)
		for u in units {
			unique[u] = struct {}{}
		}
		if len(unique) != len(units) {
			move_validation_result_set_error(
				result,
				fmt.aprintf(
					"Not all units unique, units: %v unique: %v",
					units,
					unique,
				),
			)
		} else {
			ctx := Move_Validator_Validate_First_Units_0_Ctx{
				result = result,
			}
			for u in units {
				move_validator_lambda_validate_first_units_0(rawptr(&ctx), u)
			}
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#enemyDestroyerOnPath
// Java:
//   private boolean enemyDestroyerOnPath(final Route route, final GamePlayer player) {
//     final Predicate<Unit> enemyDestroyer =
//         Matches.unitIsDestroyer().and(Matches.enemyUnit(player));
//     return route.getMiddleSteps().stream()
//         .anyMatch(current -> current.anyUnitsMatch(enemyDestroyer));
//   }
Move_Validator_Enemy_Destroyer_Match_Ctx :: struct {
	player: ^Game_Player,
}

move_validator_enemy_destroyer_match :: proc(ctx: rawptr, u: ^Unit) -> bool {
	c := cast(^Move_Validator_Enemy_Destroyer_Match_Ctx)ctx
	d_p, d_c := matches_unit_is_destroyer()
	if !d_p(d_c, u) {
		return false
	}
	e_p, e_c := matches_enemy_unit(c.player)
	return e_p(e_c, u)
}

move_validator_enemy_destroyer_on_path :: proc(
	self: ^Move_Validator,
	route: ^Route,
	player: ^Game_Player,
) -> bool {
	_ = self
	match_ctx := new(Move_Validator_Enemy_Destroyer_Match_Ctx)
	match_ctx.player = player
	lambda_ctx := Move_Validator_Enemy_Destroyer_On_Path_9_Ctx{
		destroyer_match     = move_validator_enemy_destroyer_match,
		destroyer_match_ctx = rawptr(match_ctx),
	}
	for current in route_get_middle_steps(route) {
		if move_validator_lambda_enemy_destroyer_on_path_9(rawptr(&lambda_ctx), current) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getNonLand
// Java:
//   private static Collection<Unit> getNonLand(final Collection<Unit> units) {
//     return CollectionUtils.getMatches(units, Matches.unitIsAir().or(Matches.unitIsSea()));
//   }
move_validator_get_non_land :: proc(units: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	air_p, air_c := matches_unit_is_air()
	sea_p, sea_c := matches_unit_is_sea()
	for u in units {
		if air_p(air_c, u) || sea_p(sea_c, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#noEnemyUnitsOnPathMiddleSteps
// Java:
//   private boolean noEnemyUnitsOnPathMiddleSteps(final Route route, final GamePlayer player) {
//     final Predicate<Unit> alliedOrNonCombat =
//         Matches.unitIsInfrastructure()
//             .or(Matches.enemyUnit(player).negate())
//             .or(Matches.unitIsSubmerged());
//     return route.getMiddleSteps().stream()
//         .allMatch(current -> current.getUnitCollection().allMatch(alliedOrNonCombat));
//   }
Move_Validator_Allied_Or_Non_Combat_Ctx :: struct {
	player: ^Game_Player,
}

move_validator_allied_or_non_combat :: proc(ctx: rawptr, u: ^Unit) -> bool {
	c := cast(^Move_Validator_Allied_Or_Non_Combat_Ctx)ctx
	inf_p, inf_c := matches_unit_is_infrastructure()
	if inf_p(inf_c, u) {
		return true
	}
	e_p, e_c := matches_enemy_unit(c.player)
	if !e_p(e_c, u) {
		return true
	}
	sub_p, sub_c := matches_unit_is_submerged()
	return sub_p(sub_c, u)
}

move_validator_no_enemy_units_on_path_middle_steps :: proc(
	self: ^Move_Validator,
	route: ^Route,
	player: ^Game_Player,
) -> bool {
	_ = self
	pred_ctx := new(Move_Validator_Allied_Or_Non_Combat_Ctx)
	pred_ctx.player = player
	lambda_ctx := Move_Validator_No_Enemy_Units_On_Path_Middle_Steps_8_Ctx{
		allied_or_non_combat     = move_validator_allied_or_non_combat,
		allied_or_non_combat_ctx = rawptr(pred_ctx),
	}
	for current in route_get_middle_steps(route) {
		if !move_validator_lambda_no_enemy_units_on_path_middle_steps_8(
			rawptr(&lambda_ctx),
			current,
		) {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#findNonDependentUnits
// Java:
//   private static Collection<Unit> findNonDependentUnits(
//       final Collection<Unit> units,
//       final Route route,
//       final Map<Unit, Collection<Unit>> airTransportDependents) {
//     final Collection<Unit> unitsWithoutDependents = new ArrayList<>();
//     unitsWithoutDependents.addAll(route.getStart().isWater() ? getNonLand(units) : units);
//     unitsWithoutDependents.removeIf(u -> u.getTransportedBy() != null);
//     for (Collection<Unit> dependents : airTransportDependents.values()) {
//       unitsWithoutDependents.removeAll(dependents);
//     }
//     return unitsWithoutDependents;
//   }
move_validator_find_non_dependent_units :: proc(
	units: [dynamic]^Unit,
	route: ^Route,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	if territory_is_water(route_get_start(route)) {
		non_land := move_validator_get_non_land(units)
		defer delete(non_land)
		for u in non_land {
			append(&result, u)
		}
	} else {
		for u in units {
			append(&result, u)
		}
	}
	// removeIf u -> u.getTransportedBy() != nil
	{
		i := 0
		for i < len(result) {
			if move_validator_lambda_find_non_dependent_units_7(result[i]) {
				ordered_remove(&result, i)
			} else {
				i += 1
			}
		}
	}
	// removeAll dependents (across all map values)
	for _, dependents in air_transport_dependents {
		for d in dependents {
			i := 0
			for i < len(result) {
				if result[i] == d {
					ordered_remove(&result, i)
				} else {
					i += 1
				}
			}
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getCanCarry
// Java:
//   private static Collection<Unit> getCanCarry(
//       final Unit carrier,
//       final Collection<Unit> selectFrom,
//       final GamePlayer playerWhoIsDoingTheMovement) {
//     final UnitAttachment ua = carrier.getUnitAttachment();
//     final Collection<Unit> canCarry = new ArrayList<>();
//     int available = ua.getCarrierCapacity();
//     for (final Unit plane : selectFrom) {
//       final UnitAttachment planeAttachment = plane.getUnitAttachment();
//       final int cost = planeAttachment.getCarrierCost();
//       if (available >= cost
//           && ((carrier.getAlreadyMoved().compareTo(plane.getAlreadyMoved()) == 0)
//               || (Matches.unitHasNotMoved().test(plane) && Matches.unitHasNotMoved().test(carrier))
//               || (Matches.unitIsOwnedBy(playerWhoIsDoingTheMovement).negate().test(plane)
//                   && Matches.alliedUnit(playerWhoIsDoingTheMovement).test(plane)))) {
//         available -= cost;
//         canCarry.add(plane);
//       }
//       if (available == 0) {
//         break;
//       }
//     }
//     return canCarry;
//   }
move_validator_get_can_carry :: proc(
	carrier: ^Unit,
	select_from: [dynamic]^Unit,
	player_who_is_doing_the_movement: ^Game_Player,
) -> [dynamic]^Unit {
	ua := unit_get_unit_attachment(carrier)
	can_carry := make([dynamic]^Unit)
	available := unit_attachment_get_carrier_capacity(ua)
	for plane in select_from {
		plane_attachment := unit_get_unit_attachment(plane)
		cost := unit_attachment_get_carrier_cost(plane_attachment)
		if available >= cost {
			ok := false
			if unit_get_already_moved(carrier) == unit_get_already_moved(plane) {
				ok = true
			} else {
				hnm_p, hnm_c := matches_unit_has_not_moved()
				if hnm_p(hnm_c, plane) && hnm_p(hnm_c, carrier) {
					ok = true
				} else {
					owned_p, owned_c := matches_unit_is_owned_by(player_who_is_doing_the_movement)
					allied_p, allied_c := matches_allied_unit(player_who_is_doing_the_movement)
					if !owned_p(owned_c, plane) && allied_p(allied_c, plane) {
						ok = true
					}
				}
			}
			if ok {
				available -= cost
				append(&can_carry, plane)
			}
		}
		if available == 0 {
			break
		}
	}
	return can_carry
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getUnitsThatCantGoOnWater
// Java:
//   private static Collection<Unit> getUnitsThatCantGoOnWater(final Collection<Unit> units) {
//     final Collection<Unit> retUnits = new ArrayList<>();
//     for (final Unit unit : units) {
//       final UnitAttachment ua = unit.getUnitAttachment();
//       if (!ua.isSea() && !ua.isAir() && ua.getTransportCost() == -1) {
//         retUnits.add(unit);
//       }
//     }
//     return retUnits;
//   }
move_validator_get_units_that_cant_go_on_water :: proc(
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	ret_units := make([dynamic]^Unit)
	for unit in units {
		ua := unit_get_unit_attachment(unit)
		if !unit_attachment_is_sea(ua) && !unit_attachment_is_air(ua) &&
		   unit_attachment_get_transport_cost(ua) == -1 {
			append(&ret_units, unit)
		}
	}
	return ret_units
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$validateBasic$6
// Java (the `hasMovementOrAttackingLimit` predicate captured inside validateBasic):
//   unit -> {
//     final var ua = unit.getUnitAttachment();
//     if (ua.getMovementLimit().isPresent() || ua.getAttackingLimit().isPresent()) {
//       return true;
//     }
//     for (final var limit : playerMovementLimit) {
//       if (limit.getThird().contains(unit.getType())) { return true; }
//     }
//     for (final var limit : playerAttackingLimit) {
//       if (limit.getThird().contains(unit.getType())) { return true; }
//     }
//     return false;
//   }
// Captured Sets carried via the rawptr-ctx convention.
Move_Validator_Validate_Basic_6_Ctx :: struct {
	player_movement_limit:  map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {},
	player_attacking_limit: map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {},
}

move_validator_lambda_validate_basic_6 :: proc(ctx: rawptr, unit: ^Unit) -> bool {
	c := cast(^Move_Validator_Validate_Basic_6_Ctx)ctx
	ua := unit_get_unit_attachment(unit)
	if unit_attachment_get_movement_limit(ua) != nil ||
	   unit_attachment_get_attacking_limit(ua) != nil {
		return true
	}
	ut := unit_get_type(unit)
	for limit in c.player_movement_limit {
		third := triple_get_third(limit)
		if _, ok := third[ut]; ok {
			return true
		}
	}
	for limit in c.player_attacking_limit {
		third := triple_get_third(limit)
		if _, ok := third[ut]; ok {
			return true
		}
	}
	return false
}

