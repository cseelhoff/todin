package game

import "core:fmt"
import "core:strings"

// games.strategy.triplea.delegate.move.validation.MoveValidator#TOO_POOR_TO_VIOLATE_NEUTRALITY
MOVE_VALIDATOR_TOO_POOR_TO_VIOLATE_NEUTRALITY :: "Not enough money to pay for violating neutrality"

// games.strategy.triplea.delegate.move.validation.MoveValidator#CANT_MOVE_THROUGH_IMPASSABLE
MOVE_VALIDATOR_CANT_MOVE_THROUGH_IMPASSABLE :: "Can't move through impassable territories"

// games.strategy.triplea.delegate.move.validation.MoveValidator#CANNOT_VIOLATE_NEUTRALITY
MOVE_VALIDATOR_CANNOT_VIOLATE_NEUTRALITY :: "Cannot violate neutrality"

// String constants from MoveValidator.java referenced inside the
// validate{Combat,Transport,...} chains.
MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_IN_A_PREVIOUS_PHASE ::
	"Transport has already unloaded units in a previous phase"
MOVE_VALIDATOR_TRANSPORT_MAY_NOT_UNLOAD_TO_FRIENDLY_TERRITORIES_UNTIL_AFTER_COMBAT_IS_RESOLVED ::
	"Transport may not unload to friendly territories until after combat is resolved"
MOVE_VALIDATOR_ENEMY_SUBMARINE_PREVENTING_UNESCORTED_AMPHIBIOUS_ASSAULT_LANDING ::
	"Enemy Submarine Preventing Unescorted Amphibious Assault Landing"
MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_TO :: "Transport has already unloaded units to "
MOVE_VALIDATOR_CANNOT_LOAD_AND_UNLOAD_AN_ALLIED_TRANSPORT_IN_THE_SAME_ROUND ::
	"Cannot load and unload an allied transport in the same round"
MOVE_VALIDATOR_CANT_MOVE_THROUGH_RESTRICTED :: "Can't move through restricted territories"
MOVE_VALIDATOR_TRANSPORT_CANNOT_LOAD_AND_UNLOAD_AFTER_COMBAT ::
	"Transport cannot both load AND unload after being in combat"
MOVE_VALIDATOR_TRANSPORT_CANNOT_LOAD_AFTER_COMBAT :: "Transport cannot load after being in combat"
MOVE_VALIDATOR_NOT_ALL_UNITS_CAN_BLITZ :: "Not all units can blitz"
MOVE_VALIDATOR_CANNOT_BLITZ_OUT_OF_BATTLE_INTO_ENEMY_TERRITORY ::
	"Cannot blitz out of a battle into enemy territory"
MOVE_VALIDATOR_NOT_ALL_UNITS_CAN_BLITZ_OUT_OF_EMPTY_ENEMY_TERRITORY ::
	"Not all units can blitz out of empty enemy territory"
MOVE_VALIDATOR_CANNOT_BLITZ_OUT_OF_BATTLE_FURTHER_INTO_ENEMY_TERRITORY ::
	"Cannot blitz out of a battle further into enemy territory"

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

// games.strategy.triplea.delegate.move.validation.MoveValidator#isNotNeutralsBlitzable
// Java:
//   private static boolean isNotNeutralsBlitzable(final GameProperties properties) {
//     return !Properties.getNeutralsBlitzable(properties)
//         && !Properties.getNeutralsImpassable(properties);
//   }
move_validator_is_not_neutrals_blitzable :: proc(properties: ^Game_Properties) -> bool {
	return !properties_get_neutrals_blitzable(properties) &&
	       !properties_get_neutrals_impassable(properties)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getNeutralCharge
// Java:
//   private static int getNeutralCharge(
//       final GameProperties properties, final int numberOfTerritories) {
//     return numberOfTerritories * Properties.getNeutralCharge(properties);
//   }
move_validator_get_neutral_charge :: proc(
	properties: ^Game_Properties,
	number_of_territories: i32,
) -> i32 {
	return number_of_territories * properties_get_neutral_charge(properties)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#hasConqueredNonBlitzedNonWaterOnRoute
// Java:
//   private static boolean hasConqueredNonBlitzedNonWaterOnRoute(
//       final Route route, final GameData data) {
//     for (final Territory current : route.getMiddleSteps()) {
//       if (!Matches.territoryIsWater().test(current)
//           && AbstractMoveDelegate.getBattleTracker(data).wasConquered(current)
//           && !AbstractMoveDelegate.getBattleTracker(data).wasBlitzed(current)) {
//         return true;
//       }
//     }
//     return false;
//   }
move_validator_has_conquered_non_blitzed_non_water_on_route :: proc(
	route: ^Route,
	data: ^Game_Data,
) -> bool {
	bt := abstract_move_delegate_get_battle_tracker(data)
	middle := route_get_middle_steps(route)
	defer delete(middle)
	for current in middle {
		if !territory_is_water(current) &&
		   battle_tracker_was_conquered(bt, current) &&
		   !battle_tracker_was_blitzed(bt, current) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#onlyIgnoredUnitsOnPath
// Java:
//   public boolean onlyIgnoredUnitsOnPath(
//       final Route route, final GamePlayer player, final boolean ignoreRouteEnd) {
//     final Predicate<Unit> transportOnly =
//         Matches.unitIsInfrastructure()
//             .or(Matches.unitIsSeaTransportButNotCombatSeaTransport())
//             .or(Matches.unitIsLand())
//             .or(Matches.enemyUnit(player).negate());
//     final Predicate<Unit> subOnly =
//         Matches.unitIsInfrastructure()
//             .or(Matches.unitCanBeMovedThroughByEnemies())
//             .or(Matches.enemyUnit(player).negate());
//     final Predicate<Unit> transportOrSubOnly = transportOnly.or(subOnly);
//     final boolean getIgnoreTransportInMovement =
//         Properties.getIgnoreTransportInMovement(data.getProperties());
//     List<Territory> steps;
//     if (ignoreRouteEnd) { steps = route.getMiddleSteps(); }
//     else {
//       steps = route.getSteps();
//       if (steps.isEmpty()) { steps = List.of(route.getStart()); }
//     }
//     boolean validMove = false;
//     for (final Territory current : steps) {
//       if (current.isWater()) {
//         if ((getIgnoreTransportInMovement
//                 && current.getUnitCollection().allMatch(transportOrSubOnly))
//             || current.getUnitCollection().allMatch(subOnly)) {
//           validMove = true;
//           continue;
//         }
//         return false;
//       }
//     }
//     return validMove;
//   }
move_validator_only_ignored_units_on_path :: proc(
	self: ^Move_Validator,
	route: ^Route,
	player: ^Game_Player,
	ignore_route_end: bool,
) -> bool {
	infra_p, infra_c := matches_unit_is_infrastructure()
	stxc_p, stxc_c := matches_unit_is_sea_transport_but_not_combat_sea_transport()
	land_p, land_c := matches_unit_is_land()
	enemy_p, enemy_c := matches_enemy_unit(player)
	can_through_p, can_through_c := matches_unit_can_be_moved_through_by_enemies()

	transport_only :: proc(
		u: ^Unit,
		infra_p: proc(rawptr, ^Unit) -> bool, infra_c: rawptr,
		stxc_p: proc(rawptr, ^Unit) -> bool, stxc_c: rawptr,
		land_p: proc(rawptr, ^Unit) -> bool, land_c: rawptr,
		enemy_p: proc(rawptr, ^Unit) -> bool, enemy_c: rawptr,
	) -> bool {
		return infra_p(infra_c, u) ||
			stxc_p(stxc_c, u) ||
			land_p(land_c, u) ||
			!enemy_p(enemy_c, u)
	}
	sub_only :: proc(
		u: ^Unit,
		infra_p: proc(rawptr, ^Unit) -> bool, infra_c: rawptr,
		can_through_p: proc(rawptr, ^Unit) -> bool, can_through_c: rawptr,
		enemy_p: proc(rawptr, ^Unit) -> bool, enemy_c: rawptr,
	) -> bool {
		return infra_p(infra_c, u) ||
			can_through_p(can_through_c, u) ||
			!enemy_p(enemy_c, u)
	}

	get_ignore_transport_in_movement := properties_get_ignore_transport_in_movement(
		game_data_get_properties(self.data),
	)
	steps: [dynamic]^Territory
	if ignore_route_end {
		steps = route_get_middle_steps(route)
	} else {
		steps = route_get_steps(route)
		if len(steps) == 0 {
			append(&steps, route_get_start(route))
		}
	}
	defer delete(steps)

	valid_move := false
	for current in steps {
		if territory_is_water(current) {
			uc := territory_get_unit_collection(current)
			all_transport_or_sub := true
			for u in uc.units {
				if !(transport_only(
						u,
						infra_p, infra_c,
						stxc_p, stxc_c,
						land_p, land_c,
						enemy_p, enemy_c,
					) ||
					sub_only(
						u,
						infra_p, infra_c,
						can_through_p, can_through_c,
						enemy_p, enemy_c,
					)) {
					all_transport_or_sub = false
					break
				}
			}
			all_sub := true
			for u in uc.units {
				if !sub_only(
					u,
					infra_p, infra_c,
					can_through_p, can_through_c,
					enemy_p, enemy_c,
				) {
					all_sub = false
					break
				}
			}
			if (get_ignore_transport_in_movement && all_transport_or_sub) || all_sub {
				valid_move = true
				continue
			}
			return false
		}
	}
	return valid_move
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateMovementRestrictedByTerritory
// Java:
//   private MoveValidationResult validateMovementRestrictedByTerritory(
//       final Route route, final GamePlayer player, final MoveValidationResult result) {
//     if (getEditMode(data.getProperties())) { return result; }
//     if (!Properties.getMovementByTerritoryRestricted(data.getProperties())) { return result; }
//     final RulesAttachment ra = player.getRulesAttachment();
//     if (ra == null || ra.getMovementRestrictionTerritories() == null) { return result; }
//     final Collection<Territory> listedTerritories =
//         ra.getListedTerritories(ra.getMovementRestrictionTerritories(), true, true);
//     if (ra.isMovementRestrictionTypeAllowed()) {
//       for (final Territory current : route.getAllTerritories()) {
//         if (!listedTerritories.contains(current)) {
//           return result.setErrorReturnResult("Cannot move outside restricted territories");
//         }
//       }
//     } else if (ra.isMovementRestrictionTypeDisallowed()) {
//       for (final Territory current : route.getAllTerritories()) {
//         if (listedTerritories.contains(current)) {
//           return result.setErrorReturnResult("Cannot move to restricted territories");
//         }
//       }
//     }
//     return result;
//   }
move_validator_validate_movement_restricted_by_territory :: proc(
	self: ^Move_Validator,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	props := game_data_get_properties(self.data)
	if edit_delegate_get_edit_mode(props) {
		return result
	}
	if !properties_get_movement_by_territory_restricted(props) {
		return result
	}
	ra := game_player_get_rules_attachment(player)
	if ra == nil {
		return result
	}
	mrt := rules_attachment_get_movement_restriction_territories(ra)
	if mrt == nil {
		return result
	}
	listed := rules_attachment_get_listed_territories(ra, mrt, true, true)
	defer delete(listed)
	all_terrs := route_get_all_territories(route)
	defer delete(all_terrs)
	contains :: proc(list: [dynamic]^Territory, t: ^Territory) -> bool {
		for x in list {
			if x == t {
				return true
			}
		}
		return false
	}
	if rules_attachment_is_movement_restriction_type_allowed(ra) {
		for current in all_terrs {
			if !contains(listed, current) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot move outside restricted territories",
				)
			}
		}
	} else if rules_attachment_is_movement_restriction_type_disallowed(ra) {
		for current in all_terrs {
			if contains(listed, current) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot move to restricted territories",
				)
			}
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#checkCanalStepAndOwnership
// Java:
//   private Optional<String> checkCanalStepAndOwnership(
//       final CanalAttachment canalAttachment, final GamePlayer player) {
//     if (canalAttachment.getCanNotMoveThroughDuringCombatMove()
//         && GameStepPropertiesHelper.isCombatMove(data, true)) {
//       return Optional.of("Can only move through " + canalAttachment.getCanalName()
//           + " during non-combat move");
//     }
//     for (final Territory borderTerritory : canalAttachment.getLandTerritories()) {
//       if (!data.getRelationshipTracker().canMoveThroughCanals(player, borderTerritory.getOwner())) {
//         return Optional.of("Must control " + canalAttachment.getCanalName()
//             + " to move through");
//       }
//       if (AbstractMoveDelegate.getBattleTracker(data).wasConquered(borderTerritory)) {
//         return Optional.of("Must control " + canalAttachment.getCanalName()
//             + " for an entire turn to move through");
//       }
//     }
//     return Optional.empty();
//   }
// Optional<String> → (string, bool) per the convention used elsewhere in
// the port (e.g. Client_Setting.get_encoded_current_value).
move_validator_check_canal_step_and_ownership :: proc(
	self: ^Move_Validator,
	canal_attachment: ^Canal_Attachment,
	player: ^Game_Player,
) -> (string, bool) {
	if canal_attachment_get_can_not_move_through_during_combat_move(canal_attachment) &&
	   game_step_properties_helper_is_combat_move(self.data, true) {
		return fmt.aprintf(
			"Can only move through %v during non-combat move",
			canal_attachment_get_canal_name(canal_attachment),
		), true
	}
	rt := game_data_get_relationship_tracker(self.data)
	bt := abstract_move_delegate_get_battle_tracker(self.data)
	for border_territory in canal_attachment_get_land_territories(canal_attachment) {
		if !relationship_tracker_can_move_through_canals(
			rt,
			player,
			territory_get_owner(border_territory),
		) {
			return fmt.aprintf(
				"Must control %v to move through",
				canal_attachment_get_canal_name(canal_attachment),
			), true
		}
		if battle_tracker_was_conquered(bt, border_territory) {
			return fmt.aprintf(
				"Must control %v for an entire turn to move through",
				canal_attachment_get_canal_name(canal_attachment),
			), true
		}
	}
	return "", false
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#carrierMustMoveWith
// Java (3-arg public static):
//   public static Map<Unit, Collection<Unit>> carrierMustMoveWith(
//       final Collection<Unit> units, final Collection<Unit> startUnits,
//       final GamePlayer player) {
//     final Predicate<Unit> friendlyNotOwnedAir =
//         Matches.alliedUnit(player)
//             .and(Matches.unitIsOwnedBy(player).negate())
//             .and(Matches.unitCanLandOnCarrier());
//     final Collection<Unit> alliedAir = CollectionUtils.getMatches(startUnits, friendlyNotOwnedAir);
//     if (alliedAir.isEmpty()) { return Map.of(); }
//     final Predicate<Unit> friendlyNotOwnedCarrier =
//         Matches.unitIsCarrier()
//             .and(Matches.alliedUnit(player))
//             .and(Matches.unitIsOwnedBy(player).negate());
//     final Collection<Unit> alliedCarrier =
//         CollectionUtils.getMatches(startUnits, friendlyNotOwnedCarrier);
//     for (final Unit carrier : alliedCarrier) {
//       final Collection<Unit> carrying = getCanCarry(carrier, alliedAir, player);
//       alliedAir.removeAll(carrying);
//     }
//     if (alliedAir.isEmpty()) { return Map.of(); }
//     final Map<Unit, Collection<Unit>> mapping = new HashMap<>();
//     final Collection<Unit> ownedCarrier =
//         CollectionUtils.getMatches(units, Matches.unitIsCarrier().and(Matches.unitIsOwnedBy(player)));
//     for (final Unit carrier : ownedCarrier) {
//       final Collection<Unit> carrying = getCanCarry(carrier, alliedAir, player);
//       alliedAir.removeAll(carrying);
//       mapping.put(carrier, carrying);
//     }
//     return ImmutableMap.copyOf(mapping);
//   }
move_validator_carrier_must_move_with :: proc(
	units: [dynamic]^Unit,
	start_units: [dynamic]^Unit,
	player: ^Game_Player,
) -> map[^Unit][dynamic]^Unit {
	allied_p, allied_c := matches_allied_unit(player)
	owned_p, owned_c := matches_unit_is_owned_by(player)
	can_land_p, can_land_c := matches_unit_can_land_on_carrier()
	carrier_p, carrier_c := matches_unit_is_carrier()

	allied_air := make([dynamic]^Unit)
	for u in start_units {
		if allied_p(allied_c, u) && !owned_p(owned_c, u) && can_land_p(can_land_c, u) {
			append(&allied_air, u)
		}
	}
	if len(allied_air) == 0 {
		delete(allied_air)
		return map[^Unit][dynamic]^Unit{}
	}

	allied_carrier := make([dynamic]^Unit)
	defer delete(allied_carrier)
	for u in start_units {
		if carrier_p(carrier_c, u) && allied_p(allied_c, u) && !owned_p(owned_c, u) {
			append(&allied_carrier, u)
		}
	}
	remove_all :: proc(target: ^[dynamic]^Unit, removed: [dynamic]^Unit) {
		for r in removed {
			i := 0
			for i < len(target) {
				if target[i] == r {
					ordered_remove(target, i)
				} else {
					i += 1
				}
			}
		}
	}
	for carrier in allied_carrier {
		carrying := move_validator_get_can_carry(carrier, allied_air, player)
		defer delete(carrying)
		remove_all(&allied_air, carrying)
	}
	if len(allied_air) == 0 {
		delete(allied_air)
		return map[^Unit][dynamic]^Unit{}
	}

	mapping: map[^Unit][dynamic]^Unit
	owned_carrier := make([dynamic]^Unit)
	defer delete(owned_carrier)
	for u in units {
		if carrier_p(carrier_c, u) && owned_p(owned_c, u) {
			append(&owned_carrier, u)
		}
	}
	for carrier in owned_carrier {
		carrying := move_validator_get_can_carry(carrier, allied_air, player)
		remove_all(&allied_air, carrying)
		mapping[carrier] = carrying
	}
	delete(allied_air)
	return mapping
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#carrierMustMoveWith(Territory, GamePlayer)
// Java: public static Map<Unit, Collection<Unit>> carrierMustMoveWith(
//           final Territory start, final GamePlayer player) {
//         return carrierMustMoveWith(start.getUnits(), start.getUnits(), player);
//       }
move_validator_carrier_must_move_with_territory :: proc(
	start: ^Territory,
	player: ^Game_Player,
) -> map[^Unit][dynamic]^Unit {
	su := territory_get_unit_collection(start).units
	return move_validator_carrier_must_move_with(su, su, player)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#carrierMustMoveWith(Collection<Unit>, Territory, GamePlayer)
// Java: public static Map<Unit, Collection<Unit>> carrierMustMoveWith(
//           final Collection<Unit> units, final Territory start, final GamePlayer player) {
//         return carrierMustMoveWith(units, start.getUnits(), player);
//       }
move_validator_carrier_must_move_with_units_territory :: proc(
	units: [dynamic]^Unit,
	start: ^Territory,
	player: ^Game_Player,
) -> map[^Unit][dynamic]^Unit {
	return move_validator_carrier_must_move_with(
		units,
		territory_get_unit_collection(start).units,
		player,
	)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#nonAirPassingThroughNeutralTerritory
// Java:
//   private static boolean nonAirPassingThroughNeutralTerritory(
//       final Route route, final Collection<Unit> units, final GameProperties properties) {
//     return route.hasNeutralBeforeEnd()
//         && !units.stream().allMatch(Matches.unitIsAir())
//         && isNotNeutralsBlitzable(properties);
//   }
move_validator_non_air_passing_through_neutral_territory :: proc(
	route: ^Route,
	units: [dynamic]^Unit,
	properties: ^Game_Properties,
) -> bool {
	if !route_has_neutral_before_end(route) {
		return false
	}
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	if all_air {
		return false
	}
	return move_validator_is_not_neutrals_blitzable(properties)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getNumLandTransportsWithoutCapacity
// Java:
//   private static int getNumLandTransportsWithoutCapacity(
//       final Collection<Unit> units, final GamePlayer player) {
//     if (player.getTechAttachment().getMechanizedInfantry()) {
//       final Predicate<Unit> transportLand =
//           Matches.unitIsLandTransportWithoutCapacity().and(Matches.unitIsOwnedBy(player));
//       return CollectionUtils.countMatches(units, transportLand);
//     }
//     return 0;
//   }
move_validator_get_num_land_transports_without_capacity :: proc(
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> i32 {
	if !tech_attachment_get_mechanized_infantry(game_player_get_tech_attachment(player)) {
		return 0
	}
	tl_p, tl_c := matches_unit_is_land_transport_without_capacity()
	owned_p, owned_c := matches_unit_is_owned_by(player)
	count: i32 = 0
	for u in units {
		if tl_p(tl_c, u) && owned_p(owned_c, u) {
			count += 1
		}
	}
	return count
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#getLandTransportsWithCapacity
// Java:
//   private static IntegerMap<Unit> getLandTransportsWithCapacity(
//       final Collection<Unit> units, final GamePlayer player) {
//     final IntegerMap<Unit> map = new IntegerMap<>();
//     if (player.getTechAttachment().getMechanizedInfantry()) {
//       final Predicate<Unit> transportLand =
//           Matches.unitIsLandTransportWithCapacity().and(Matches.unitIsOwnedBy(player));
//       for (final Unit unit : CollectionUtils.getMatches(units, transportLand)) {
//         map.put(unit, unit.getUnitAttachment().getTransportCapacity());
//       }
//     }
//     return map;
//   }
move_validator_get_land_transports_with_capacity :: proc(
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> ^Integer_Map_Unit {
	m := new(Integer_Map_Unit)
	m.entries = make(map[^Unit]i32)
	if !tech_attachment_get_mechanized_infantry(game_player_get_tech_attachment(player)) {
		return m
	}
	tl_p, tl_c := matches_unit_is_land_transport_with_capacity()
	owned_p, owned_c := matches_unit_is_owned_by(player)
	for u in units {
		if tl_p(tl_c, u) && owned_p(owned_c, u) {
			m.entries[u] = unit_attachment_get_transport_capacity(unit_get_unit_attachment(u))
		}
	}
	return m
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#canPayToCrossNeutralTerritory
// Java:
//   private MoveValidationResult canPayToCrossNeutralTerritory(
//       final Route route, final GamePlayer player, final MoveValidationResult result) {
//     final Collection<Territory> neutrals = MoveDelegate.getEmptyNeutral(route);
//     final int pus = player.isNull() ? 0 : player.getResources().getQuantity(Constants.PUS);
//     if (pus < getNeutralCharge(data.getProperties(), neutrals.size())) {
//       return result.setErrorReturnResult(TOO_POOR_TO_VIOLATE_NEUTRALITY);
//     }
//     return result;
//   }
move_validator_can_pay_to_cross_neutral_territory :: proc(
	self: ^Move_Validator,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	neutrals := move_delegate_get_empty_neutral(route)
	defer delete(neutrals)
	pus: i32 = 0
	if !game_player_is_null(player) {
		pus_resource := resource_list_get_resource_or_throw(
			game_data_get_resource_list(self.data),
			"PUs",
		)
		pus = resource_collection_get_quantity(game_player_get_resources(player), pus_resource)
	}
	if pus < move_validator_get_neutral_charge(
		game_data_get_properties(self.data),
		i32(len(neutrals)),
	) {
		return move_validation_result_set_error_return_result(
			result,
			MOVE_VALIDATOR_TOO_POOR_TO_VIOLATE_NEUTRALITY,
		)
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#canPassThroughCanal
// Java:
//   private Optional<String> canPassThroughCanal(
//       final CanalAttachment canalAttachment, final Unit unit, final GamePlayer player) {
//     if (unit != null && Matches.unitIsOfTypes(canalAttachment.getExcludedUnits()).test(unit)) {
//       return Optional.empty();
//     }
//     return checkCanalStepAndOwnership(canalAttachment, player);
//   }
// Optional<String> -> (string, bool) per the convention used by
// move_validator_check_canal_step_and_ownership.
move_validator_can_pass_through_canal :: proc(
	self: ^Move_Validator,
	canal_attachment: ^Canal_Attachment,
	unit: ^Unit,
	player: ^Game_Player,
) -> (string, bool) {
	if unit != nil {
		excluded_p, excluded_c := matches_unit_is_of_types(
			canal_attachment_get_excluded_units(canal_attachment),
		)
		if excluded_p(excluded_c, unit) {
			return "", false
		}
	}
	return move_validator_check_canal_step_and_ownership(self, canal_attachment, player)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#canAnyPassThroughCanal
// Java:
//   private Optional<String> canAnyPassThroughCanal(
//       final CanalAttachment canalAttachment,
//       final Collection<Unit> units,
//       final GamePlayer player) {
//     if (units.stream().anyMatch(Matches.unitIsOfTypes(canalAttachment.getExcludedUnits()))) {
//       return Optional.empty();
//     }
//     return checkCanalStepAndOwnership(canalAttachment, player);
//   }
move_validator_can_any_pass_through_canal :: proc(
	self: ^Move_Validator,
	canal_attachment: ^Canal_Attachment,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> (string, bool) {
	excluded_p, excluded_c := matches_unit_is_of_types(
		canal_attachment_get_excluded_units(canal_attachment),
	)
	for u in units {
		if excluded_p(excluded_c, u) {
			return "", false
		}
	}
	return move_validator_check_canal_step_and_ownership(self, canal_attachment, player)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateFirstRoute
// Java:
//   private MoveValidationResult validateFirstRoute(
//       Route route, Collection<Unit> units, GamePlayer player, MoveValidationResult result) {
//     if (!data.getMap().isValidRoute(route)) {
//       return result.setErrorReturnResult("Invalid route: " + route);
//     } else if (validateMovementRestrictedByTerritory(route, player, result).hasError()) {
//       return result;
//     }
//     final Collection<Territory> landOnRoute = route.getMatches(Matches.territoryIsLand());
//     for (final Territory t : landOnRoute) {
//       if (units.stream().anyMatch(Matches.unitIsLand())
//           && !data.getRelationshipTracker().canMoveLandUnitsOverOwnedLand(player, t.getOwner())) {
//         return result.setErrorReturnResult(
//             player.getName() + " may not move land units over land owned by " + t.getOwner().getName());
//       }
//       if (units.stream().anyMatch(Matches.unitIsAir())
//           && !data.getRelationshipTracker().canMoveAirUnitsOverOwnedLand(player, t.getOwner())) {
//         return result.setErrorReturnResult(
//             player.getName() + " may not move air units over land owned by " + t.getOwner().getName());
//       }
//     }
//     return result;
//   }
move_validator_validate_first_route :: proc(
	self: ^Move_Validator,
	route: ^Route,
	units: [dynamic]^Unit,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if !game_map_is_valid_route(game_data_get_map(self.data), route) {
		// Java: "Invalid route: " + route, where Route.toString builds
		//   "Route:" + start.getName() + (" -> " + step.getName())*
		sb := strings.builder_make()
		strings.write_string(&sb, "Invalid route: Route:")
		start := route_get_start(route)
		if start != nil {
			strings.write_string(&sb, start.named.base.name)
		}
		for t in route.steps {
			strings.write_string(&sb, " -> ")
			strings.write_string(&sb, t.named.base.name)
		}
		return move_validation_result_set_error_return_result(result, strings.to_string(sb))
	} else if move_validation_result_has_error(
		move_validator_validate_movement_restricted_by_territory(self, route, player, result),
	) {
		return result
	}
	land_on_route := route_get_matches(route, move_validator_lambda_validate_first_route_is_land)
	defer delete(land_on_route)
	land_p, land_c := matches_unit_is_land()
	air_p, air_c := matches_unit_is_air()
	rt := game_data_get_relationship_tracker(self.data)
	for t in land_on_route {
		any_land := false
		for u in units {
			if land_p(land_c, u) { any_land = true; break }
		}
		if any_land &&
		   !relationship_tracker_can_move_land_units_over_owned_land(
			   rt, player, territory_get_owner(t),
		   ) {
			return move_validation_result_set_error_return_result(
				result,
				fmt.aprintf(
					"%s may not move land units over land owned by %s",
					player.named.base.name,
					territory_get_owner(t).named.base.name,
				),
			)
		}
		any_air := false
		for u in units {
			if air_p(air_c, u) { any_air = true; break }
		}
		if any_air &&
		   !relationship_tracker_can_move_air_units_over_owned_land(
			   rt, player, territory_get_owner(t),
		   ) {
			return move_validation_result_set_error_return_result(
				result,
				fmt.aprintf(
					"%s may not move air units over land owned by %s",
					player.named.base.name,
					territory_get_owner(t).named.base.name,
				),
			)
		}
	}
	return result
}

// Adapter: route_get_matches takes a non-ctx predicate, and
// matches_pred_territory_is_land takes (rawptr, ^Territory). Wrap it.
move_validator_lambda_validate_first_route_is_land :: proc(t: ^Territory) -> bool {
	return matches_pred_territory_is_land(nil, t)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#canAnyUnitsPassCanal
// Java:
//   public boolean canAnyUnitsPassCanal(
//       final Territory start, final Territory end,
//       final Collection<Unit> units, final GamePlayer player) {
//     boolean canPass = true;
//     final Route route = new Route(start, end);
//     for (final CanalAttachment canalAttachment : CanalAttachment.get(start, route)) {
//       final Collection<Unit> unitsWithoutDependents = findNonDependentUnits(units, route, Map.of());
//       canPass = canAnyPassThroughCanal(canalAttachment, unitsWithoutDependents, player).isEmpty();
//       final boolean mustControlAllCanals =
//           Properties.getControlAllCanalsBetweenTerritoriesToPass(data.getProperties());
//       if (mustControlAllCanals != canPass) { break; }
//     }
//     return canPass;
//   }
// canAnyPassThroughCanal in Odin returns (string, bool); bool=true means
// Optional.present, so isEmpty() <=> !ok.
move_validator_can_any_units_pass_canal :: proc(
	self: ^Move_Validator,
	start: ^Territory,
	end: ^Territory,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> bool {
	can_pass := true
	route := route_new_from_start_and_steps(start, end)
	canals := canal_attachment_get(start, route)
	defer delete(canals)
	empty_deps: map[^Unit][dynamic]^Unit
	defer delete(empty_deps)
	for canal_attachment in canals {
		units_without_dependents := move_validator_find_non_dependent_units(
			units,
			route,
			empty_deps,
		)
		_, ok := move_validator_can_any_pass_through_canal(
			self,
			canal_attachment,
			units_without_dependents,
			player,
		)
		delete(units_without_dependents)
		can_pass = !ok
		must_control_all_canals := properties_get_control_all_canals_between_territories_to_pass(
			game_data_get_properties(self.data),
		)
		if must_control_all_canals != can_pass {
			break
		}
	}
	return can_pass
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#checkLandTransports
// Java:
//   private Set<Unit> checkLandTransports(
//       final GamePlayer player,
//       final Collection<Unit> possibleLandTransports,
//       final Collection<Unit> unitsToLandTransport) {
//     final Set<Unit> disallowedUnits = new HashSet<>();
//     try (GameData.Unlocker ignored = data.acquireReadLock()) {
//       int numLandTransportsWithoutCapacity =
//           getNumLandTransportsWithoutCapacity(possibleLandTransports, player);
//       final IntegerMap<Unit> landTransportsWithCapacity =
//           getLandTransportsWithCapacity(possibleLandTransports, player);
//       for (final Unit unit : TransportUtils.sortByTransportCostDescending(unitsToLandTransport)) {
//         boolean unitOk = false;
//         if (Matches.unitHasNotMoved().test(unit) && Matches.unitIsLandTransportable().test(unit)) {
//           if (numLandTransportsWithoutCapacity > 0) {
//             numLandTransportsWithoutCapacity--;
//             unitOk = true;
//           } else {
//             for (final Unit transport : landTransportsWithCapacity.keySet()) {
//               final int cost = unit.getUnitAttachment().getTransportCost();
//               if (cost <= landTransportsWithCapacity.getInt(transport)) {
//                 landTransportsWithCapacity.add(transport, -cost);
//                 unitOk = true;
//                 break;
//               }
//             }
//           }
//         }
//         if (!unitOk) { disallowedUnits.add(unit); }
//       }
//     }
//     return disallowedUnits;
//   }
// Set<Unit> -> map[^Unit]struct{}. acquireReadLock is a no-op in the
// single-threaded port.
move_validator_check_land_transports :: proc(
	self: ^Move_Validator,
	player: ^Game_Player,
	possible_land_transports: [dynamic]^Unit,
	units_to_land_transport: [dynamic]^Unit,
) -> map[^Unit]struct {} {
	disallowed_units: map[^Unit]struct {}
	game_data_acquire_read_lock(self.data)
	num_land_transports_without_capacity := move_validator_get_num_land_transports_without_capacity(
		possible_land_transports,
		player,
	)
	land_transports_with_capacity := move_validator_get_land_transports_with_capacity(
		possible_land_transports,
		player,
	)
	sorted := transport_utils_sort_by_transport_cost_descending(units_to_land_transport)
	defer delete(sorted)
	for unit in sorted {
		unit_ok := false
		hnm_p, hnm_c := matches_unit_has_not_moved()
		lt_p, lt_c := matches_unit_is_land_transportable()
		if hnm_p(hnm_c, unit) && lt_p(lt_c, unit) {
			if num_land_transports_without_capacity > 0 {
				num_land_transports_without_capacity -= 1
				unit_ok = true
			} else {
				for transport, capacity in land_transports_with_capacity.entries {
					cost := unit_attachment_get_transport_cost(unit_get_unit_attachment(unit))
					if cost <= capacity {
						land_transports_with_capacity.entries[transport] = capacity - cost
						unit_ok = true
						break
					}
				}
			}
		}
		if !unit_ok {
			disallowed_units[unit] = struct {}{}
		}
	}
	return disallowed_units
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#convertTransportKeyedMapToLoadedUnitKeyedMap
// Java:
//   private Map<Unit, Unit> convertTransportKeyedMapToLoadedUnitKeyedMap(
//       final Map<Unit, Collection<Unit>> airTransportDependents,
//       final MoveValidationResult result) {
//     Map<Unit, Unit> unitsToTransport = new HashMap<>();
//     for (Unit transport : airTransportDependents.keySet()) {
//       int capacity = TransportTracker.getAvailableCapacity(transport);
//       for (Unit beingTransported : airTransportDependents.get(transport)) {
//         int cost = beingTransported.getUnitAttachment().getTransportCost();
//         if (capacity < cost) {
//           result.setError("Not all units could be air transported");
//           return Map.of();
//         }
//         unitsToTransport.put(beingTransported, transport);
//         capacity -= cost;
//       }
//     }
//     return unitsToTransport;
//   }
move_validator_convert_transport_keyed_map_to_loaded_unit_keyed_map :: proc(
	self: ^Move_Validator,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	result: ^Move_Validation_Result,
) -> map[^Unit]^Unit {
	_ = self
	units_to_transport: map[^Unit]^Unit
	for transport, dependents in air_transport_dependents {
		capacity := transport_tracker_get_available_capacity(transport)
		for being_transported in dependents {
			cost := unit_attachment_get_transport_cost(
				unit_get_unit_attachment(being_transported),
			)
			if capacity < cost {
				move_validation_result_set_error(
					result,
					"Not all units could be air transported",
				)
				clear(&units_to_transport)
				return units_to_transport
			}
			units_to_transport[being_transported] = transport
			capacity -= cost
		}
	}
	return units_to_transport
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateCanal(Route, Collection<Unit>, Map<Unit, Collection<Unit>>, GamePlayer)
// Java (package-private):
//   @Nullable String validateCanal(
//       final Route route,
//       @Nullable final Collection<Unit> units,
//       final Map<Unit, Collection<Unit>> airTransportDependents,
//       final GamePlayer player) { ... }
//
// The Java parameter `units` is nullable. Odin's [dynamic]^Unit cannot
// directly express "null Collection vs empty Collection", so we add an
// explicit `units_is_null` discriminator. When true, Java's
// `setWithNull` (a singleton set holding `null`) is mirrored by an
// `units_without_dependents` containing one `nil` ^Unit, which is
// fine because `move_validator_can_pass_through_canal` already
// short-circuits the `unit != null` branch.
//
// Optional<String> result -> nullable ^string. We allocate the result
// string with `new(string)` once we know the final answer; callers
// that compare the return to `nil` use the standard Odin pointer
// idiom.
move_validator_validate_canal_with_dependents :: proc(
	self: ^Move_Validator,
	route: ^Route,
	units: [dynamic]^Unit,
	units_is_null: bool,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	player: ^Game_Player,
) -> ^string {
	territories := route_get_all_territories(route)
	defer delete(territories)

	territory_canals: map[^Territory][dynamic]^Canal_Attachment
	defer {
		for _, list in territory_canals {
			delete(list)
		}
		delete(territory_canals)
	}

	num_canals := 0
	for t in territories {
		canals := canal_attachment_get(t, route)
		territory_canals[t] = canals
		num_canals += len(canals)
	}
	if num_canals == 0 {
		return nil
	}
	must_control_all_canals := properties_get_control_all_canals_between_territories_to_pass(
		game_data_get_properties(self.data),
	)

	last_failure: string
	has_failure := false
	units_that_fail_canal: map[^Unit]struct {}
	defer delete(units_that_fail_canal)

	units_without_dependents: [dynamic]^Unit
	defer delete(units_without_dependents)
	if units_is_null {
		append(&units_without_dependents, (^Unit)(nil))
	} else {
		deps_units := move_validator_find_non_dependent_units(
			units,
			route,
			air_transport_dependents,
		)
		defer delete(deps_units)
		for u in deps_units {
			append(&units_without_dependents, u)
		}
	}

	for unit in units_without_dependents {
		for t in territories {
			failure_message: string
			failure_present := false
			canals_for_t := territory_canals[t]
			for canal_attachment in canals_for_t {
				msg, present := move_validator_can_pass_through_canal(
					self,
					canal_attachment,
					unit,
					player,
				)
				failure_message = msg
				failure_present = present
				can_pass := !failure_present
				if must_control_all_canals != can_pass {
					// need to control any canal and can pass OR
					// need to control all and can't pass.
					break
				}
			}
			if failure_present {
				last_failure = failure_message
				has_failure = true
				units_that_fail_canal[unit] = struct {}{}
			}
		}
	}
	if !has_failure {
		return nil
	}
	if units_is_null {
		rs := new(string)
		rs^ = last_failure
		return rs
	}

	// If any units failed canal check then try to land transport them.
	potential_land_transports: [dynamic]^Unit
	defer delete(potential_land_transports)
	units_to_land_transport: [dynamic]^Unit
	defer delete(units_to_land_transport)

	ctx1 := Move_Validator_Validate_Canal_1_Ctx {
		units_that_fail_canal = units_that_fail_canal,
		route                 = route,
	}
	ctx2 := Move_Validator_Validate_Canal_2_Ctx {
		units_that_fail_canal = units_that_fail_canal,
		route                 = route,
	}
	for u in units_without_dependents {
		if move_validator_lambda_validate_canal_1(rawptr(&ctx1), u) {
			append(&potential_land_transports, u)
		}
		if move_validator_lambda_validate_canal_2(rawptr(&ctx2), u) {
			append(&units_to_land_transport, u)
		}
	}

	disallowed := move_validator_check_land_transports(
		self,
		player,
		potential_land_transports,
		units_to_land_transport,
	)
	defer delete(disallowed)
	if len(disallowed) == 0 {
		return nil
	}
	rs := new(string)
	rs^ = last_failure
	return rs
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateParatroops
// Java (private):
//   private MoveValidationResult validateParatroops(
//       final Collection<Unit> units,
//       final Map<Unit, Collection<Unit>> airTransportDependents,
//       final Route route,
//       final GamePlayer player,
//       final MoveValidationResult result) { ... }
move_validator_validate_paratroops :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if !tech_attachment_get_paratroopers(game_player_get_tech_attachment(player)) {
		return result
	}

	transportable_p, transportable_c := matches_unit_is_air_transportable()
	transport_p, transport_c := matches_unit_is_air_transport()
	has_transportable := false
	has_transport := false
	for u in units {
		if !has_transportable && transportable_p(transportable_c, u) {
			has_transportable = true
		}
		if !has_transport && transport_p(transport_c, u) {
			has_transport = true
		}
		if has_transportable && has_transport {
			break
		}
	}
	if !has_transportable || !has_transport {
		return result
	}

	properties := game_data_get_properties(self.data)
	if self.is_non_combat &&
	   !properties_get_paratroopers_can_move_during_non_combat(properties) {
		return move_validation_result_set_error_return_result(
			result,
			"Paratroops may not move during NonCombat",
		)
	}
	if !edit_delegate_get_edit_mode(properties) {
		// if we can move without using paratroop tech, do so this allows
		// moving a bomber/infantry from one friendly territory to another
		paratroopers_to_air_transports :=
			move_validator_convert_transport_keyed_map_to_loaded_unit_keyed_map(
				self,
				air_transport_dependents,
				result,
			)
		defer delete(paratroopers_to_air_transports)
		if move_validation_result_has_error(result) {
			return result
		}
		for air_transport, _ in air_transport_dependents {
			if unit_has_moved(air_transport) {
				move_validation_result_add_disallowed_unit(
					result,
					"Cannot move then transport paratroops",
					air_transport,
				)
			}
		}
		friendly_p, friendly_c := matches_is_territory_friendly(player)
		friendly_end := friendly_p(friendly_c, route_get_end(route))
		can_move_non_combat := properties_get_paratroopers_can_move_during_non_combat(
			properties,
		)
		is_wrong_phase := !self.is_non_combat && friendly_end && can_move_non_combat
		must_advance_to_battle := friendly_end && !can_move_non_combat
		for paratroop, _ in paratroopers_to_air_transports {
			if unit_has_moved(paratroop) {
				move_validation_result_add_disallowed_unit(
					result,
					"Cannot paratroop units that have already moved",
					paratroop,
				)
			}
			if must_advance_to_battle {
				move_validation_result_add_disallowed_unit(
					result,
					"Paratroops must advance to battle",
					paratroop,
				)
			}
			if is_wrong_phase {
				move_validation_result_add_disallowed_unit(
					result,
					"Paratroops may only airlift during Non-Combat Movement Phase",
					paratroop,
				)
			}
		}
		if !properties_get_paratroopers_can_attack_deep_into_enemy_territory(properties) {
			land_p, land_c := matches_territory_is_land()
			enemy_p, enemy_c := matches_is_territory_enemy(player)
			middle := route_get_middle_steps(route)
			defer delete(middle)
			for t in middle {
				if land_p(land_c, t) && enemy_p(enemy_c, t) {
					return move_validation_result_set_error_return_result(
						result,
						"Must stop paratroops in first enemy territory",
					)
				}
			}
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#allLandUnitsHaveAirTransport
// Java (public static):
//   public static boolean allLandUnitsHaveAirTransport(final Collection<Unit> units) {
//     if (units.isEmpty()
//         || !units.stream().allMatch(
//             Matches.unitIsAirTransportable()
//                 .or(Matches.unitIsAirTransport())
//                 .or(Matches.unitIsAir()))) {
//       return false;
//     }
//     final List<Unit> paratroopsRequiringTransport =
//         CollectionUtils.getMatches(units, Matches.unitIsAirTransportable());
//     if (paratroopsRequiringTransport.isEmpty()) { return false; }
//     final List<Unit> airTransports =
//         CollectionUtils.getMatches(units, Matches.unitIsAirTransport());
//     final List<Unit> allParatroops =
//         TransportUtils.findUnitsToLoadOnAirTransports(paratroopsRequiringTransport, airTransports);
//     if (allParatroops.size() != paratroopsRequiringTransport.size()) { return false; }
//     final Map<Unit, Unit> transportLoadMap =
//         TransportUtils.mapTransportsToLoad(units, airTransports);
//     return transportLoadMap.keySet().containsAll(paratroopsRequiringTransport);
//   }
move_validator_all_land_units_have_air_transport :: proc(units: [dynamic]^Unit) -> bool {
	if len(units) == 0 {
		return false
	}
	transportable_p, transportable_c := matches_unit_is_air_transportable()
	air_transport_p, air_transport_c := matches_unit_is_air_transport()
	air_p, air_c := matches_unit_is_air()
	for u in units {
		if !(transportable_p(transportable_c, u) ||
			   air_transport_p(air_transport_c, u) ||
			   air_p(air_c, u)) {
			return false
		}
	}
	paratroops_requiring_transport := make([dynamic]^Unit)
	defer delete(paratroops_requiring_transport)
	for u in units {
		if transportable_p(transportable_c, u) {
			append(&paratroops_requiring_transport, u)
		}
	}
	if len(paratroops_requiring_transport) == 0 {
		return false
	}
	air_transports := make([dynamic]^Unit)
	defer delete(air_transports)
	for u in units {
		if air_transport_p(air_transport_c, u) {
			append(&air_transports, u)
		}
	}
	all_paratroops := transport_utils_find_units_to_load_on_air_transports(
		paratroops_requiring_transport,
		air_transports,
	)
	defer delete(all_paratroops)
	if len(all_paratroops) != len(paratroops_requiring_transport) {
		return false
	}
	transport_load_map := transport_utils_map_transports_to_load(units, air_transports)
	defer delete(transport_load_map)
	for p in paratroops_requiring_transport {
		if _, ok := transport_load_map[p]; !ok {
			return false
		}
	}
	return true
}

// Adapter so route_get_matches / route_any_match (which expect a
// non-context predicate) can call non-capturing matches predicates.
move_validator_lambda_validate_basic_pred_impassable :: proc(t: ^Territory) -> bool {
	return matches_pred_territory_is_impassable(nil, t)
}

move_validator_lambda_validate_basic_pred_neutral_but_not_water :: proc(t: ^Territory) -> bool {
	return matches_pred_territory_is_neutral_but_not_water(nil, t)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateBasic
// Java (private):
//   private MoveValidationResult validateBasic(
//       final Collection<Unit> units,
//       final Route route,
//       final GamePlayer player,
//       final Map<Unit, Unit> unitsToSeaTransports,
//       final Map<Unit, Collection<Unit>> airTransportDependents,
//       final MoveValidationResult result) { ... }
move_validator_validate_basic :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	units_to_sea_transports: map[^Unit]^Unit,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	is_edit_mode := edit_delegate_get_edit_mode(game_data_get_properties(self.data))

	contains_all :: proc(haystack: [dynamic]^Unit, needles: [dynamic]^Unit) -> bool {
		for n in needles {
			found := false
			for h in haystack {
				if h == n {
					found = true
					break
				}
			}
			if !found {
				return false
			}
		}
		return true
	}

	transport_values := make([dynamic]^Unit)
	defer delete(transport_values)
	for _, t in units_to_sea_transports {
		append(&transport_values, t)
	}
	end_uc := territory_get_unit_collection(route_get_end(route))
	if !unit_collection_contains_all(end_uc, transport_values) &&
	   !contains_all(units, transport_values) {
		return move_validation_result_set_error_return_result(
			result,
			"Transports not found in route end",
		)
	}

	air_keys := make([dynamic]^Unit)
	defer delete(air_keys)
	for k in air_transport_dependents {
		append(&air_keys, k)
	}
	if !contains_all(units, air_keys) {
		return move_validation_result_set_error_return_result(
			result,
			"Air transports map contains units not being moved",
		)
	}
	for _, deps in air_transport_dependents {
		if !contains_all(units, deps) {
			return move_validation_result_set_error_return_result(
				result,
				"Air transports map contains units not being moved",
			)
		}
	}

	if !is_edit_mode {
		// Make sure all units are at least friendly
		enemy_p, enemy_c := matches_enemy_unit(player)
		for u in units {
			if enemy_p(enemy_c, u) {
				move_validation_result_add_disallowed_unit(
					result,
					"Can only move friendly units",
					u,
				)
			}
		}

		// Ensure all air transports are included
		for air_transport, dep_units in air_transport_dependents {
			in_units := false
			for u in units {
				if u == air_transport {
					in_units = true
					break
				}
			}
			if !in_units {
				for unit in dep_units {
					found := false
					for u in units {
						if u == unit {
							found = true
							break
						}
					}
					if found {
						move_validation_result_add_disallowed_unit(
							result,
							"Not all units have enough movement",
							unit,
						)
					}
				}
			}
		}

		// Check that units have enough movement considering land transports
		units_without_dependents := move_validator_find_non_dependent_units(
			units,
			route,
			air_transport_dependents,
		)
		defer delete(units_without_dependents)
		units_with_enough_movement := make([dynamic]^Unit)
		defer delete(units_with_enough_movement)
		units_without_enough_movement := make([dynamic]^Unit)
		defer delete(units_without_enough_movement)
		ctx3 := Move_Validator_Validate_Basic_3_Ctx {
			route = route,
		}
		ctx4 := Move_Validator_Validate_Basic_4_Ctx {
			route = route,
		}
		for u in units_without_dependents {
			if move_validator_lambda_validate_basic_3(rawptr(&ctx3), u) {
				append(&units_with_enough_movement, u)
			}
			if move_validator_lambda_validate_basic_4(rawptr(&ctx4), u) {
				append(&units_without_enough_movement, u)
			}
		}
		disallowed := move_validator_check_land_transports(
			self,
			player,
			units_with_enough_movement,
			units_without_enough_movement,
		)
		defer delete(disallowed)
		ctx5 := Move_Validator_Validate_Basic_5_Ctx {
			result = result,
		}
		for u in disallowed {
			move_validator_lambda_validate_basic_5(rawptr(&ctx5), u)
		}

		// Can only move owned units except transported units or allied air on carriers
		owned_p, owned_c := matches_unit_is_owned_by(player)
		for u in units_without_dependents {
			if !owned_p(owned_c, u) {
				ua := unit_get_unit_attachment(u)
				if !(unit_attachment_get_carrier_cost(ua) > 0 &&
					   game_player_is_allied(player, unit_get_owner(u))) {
					move_validation_result_add_disallowed_unit(
						result,
						"Can only move own troops",
						u,
					)
				}
			}
		}

		// neutral-territory passage
		if move_validator_non_air_passing_through_neutral_territory(
			route,
			units,
			game_data_get_properties(self.data),
		) {
			return move_validation_result_set_error_return_result(
				result,
				"Must stop land units when passing through neutral territories",
			)
		}

		// territory effects disallow check
		steps := route_get_steps(route)
		defer delete(steps)
		forbidden_types := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory_1(
			steps,
		)
		defer delete(forbidden_types)
		forbid_p, forbid_c := matches_unit_is_of_types(forbidden_types)
		any_forbidden := false
		for u in units {
			if forbid_p(forbid_c, u) {
				any_forbidden = true
				break
			}
		}
		if any_forbidden {
			msg: string
			if route_number_of_steps(route) > 1 {
				msg = "Territory Effects disallow some units into these territories"
			} else {
				msg = "Territory Effects disallow some units into this territory"
			}
			return move_validation_result_set_error_return_result(result, msg)
		}

		// requiresUnitsToMove
		requires_units_to_move_list := units_without_dependents
		if route_is_unload(route) {
			requires_units_to_move_list = units
		}
		all_terrs := route_get_all_territories(route)
		defer delete(all_terrs)
		for t in all_terrs {
			req_p, req_c := matches_unit_has_required_units_to_move(t)
			all_match := true
			for u in requires_units_to_move_list {
				if !req_p(req_c, u) {
					all_match = false
					break
				}
			}
			if !all_match {
				return move_validation_result_set_error_return_result(
					result,
					fmt.aprintf(
						"%s doesn't have the required units to allow moving the selected units into it",
						t.named.base.name,
					),
				)
			}
		}
	}

	// make sure that no non-sea non-transportable no carriable units end at sea
	if territory_is_water(route_get_end(route)) {
		cant_go := move_validator_get_units_that_cant_go_on_water(units)
		defer delete(cant_go)
		for u in cant_go {
			move_validation_result_add_disallowed_unit(
				result,
				"Not all units can end at water",
				u,
			)
		}
	}

	// if we are water make sure no land
	sea_p, sea_c := matches_unit_is_sea()
	any_sea := false
	for u in units {
		if sea_p(sea_c, u) {
			any_sea = true
			break
		}
	}
	if any_sea && route_has_land(route) {
		for u in units {
			if sea_p(sea_c, u) {
				move_validation_result_add_disallowed_unit(
					result,
					"Sea units cannot go on land",
					u,
				)
			}
		}
	}

	// stack limits per unit
	pa := player_attachment_get(player)
	player_movement_limit: map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {}
	player_attacking_limit: map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {}
	if pa != nil {
		player_movement_limit = player_attachment_get_movement_limit(pa)
		player_attacking_limit = player_attachment_get_attacking_limit(pa)
	}
	ctx6 := Move_Validator_Validate_Basic_6_Ctx {
		player_movement_limit  = player_movement_limit,
		player_attacking_limit = player_attacking_limit,
	}
	units_with_stacking_limits := make([dynamic]^Unit)
	defer delete(units_with_stacking_limits)
	for u in units {
		if move_validator_lambda_validate_basic_6(rawptr(&ctx6), u) {
			append(&units_with_stacking_limits, u)
		}
	}
	steps2 := route_get_steps(route)
	defer delete(steps2)
	for t in steps2 {
		limit_type: string
		enemy_t_p, enemy_t_c := matches_is_territory_enemy_and_not_unowned_water(player)
		is_enemy_terr := enemy_t_p(enemy_t_c, t)
		enemy_u_p, enemy_u_c := matches_unit_is_enemy_of(player)
		any_enemy_unit := territory_any_units_match(t, enemy_u_p, enemy_u_c)
		if is_enemy_terr || any_enemy_unit {
			limit_type = UNIT_STACKING_LIMIT_FILTER_ATTACKING_LIMIT
		} else {
			limit_type = UNIT_STACKING_LIMIT_FILTER_MOVEMENT_LIMIT
		}
		empty_existing: [dynamic]^Unit
		defer delete(empty_existing)
		allowed := unit_stacking_limit_filter_filter_units(
			units_with_stacking_limits,
			limit_type,
			player,
			t,
			empty_existing,
		)
		defer delete(allowed)
		for u in units_with_stacking_limits {
			in_allowed := false
			for a in allowed {
				if a == u {
					in_allowed = true
					break
				}
			}
			if !in_allowed {
				move_validation_result_add_disallowed_unit(
					result,
					fmt.aprintf(
						"Unit type %s has reached stacking limit",
						unit_get_type(u).named.base.name,
					),
					u,
				)
			}
		}
	}

	// Don't allow move through impassable territories
	if !is_edit_mode &&
	   route_any_match(route, move_validator_lambda_validate_basic_pred_impassable) {
		return move_validation_result_set_error_return_result(
			result,
			MOVE_VALIDATOR_CANT_MOVE_THROUGH_IMPASSABLE,
		)
	}
	if move_validation_result_has_error(
		move_validator_can_pay_to_cross_neutral_territory(self, route, player, result),
	) {
		return result
	}
	props := game_data_get_properties(self.data)
	if properties_get_neutrals_impassable(props) &&
	   move_validator_is_not_neutrals_blitzable(props) {
		neutrals := route_get_matches(
			route,
			move_validator_lambda_validate_basic_pred_neutral_but_not_water,
		)
		defer delete(neutrals)
		if len(neutrals) != 0 {
			return move_validation_result_set_error_return_result(
				result,
				MOVE_VALIDATOR_CANNOT_VIOLATE_NEUTRALITY,
			)
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateCanal(Route, Collection<Unit>, GamePlayer)
// Java (public):
//   public @Nullable String validateCanal(
//       final Route route, @Nullable final Collection<Unit> units, final GamePlayer player) {
//     return validateCanal(route, units, Map.of(), player);
//   }
// `units_is_null` mirrors Java's nullable Collection (matches the
// `with_dependents` overload's discriminator).
move_validator_validate_canal :: proc(
	self: ^Move_Validator,
	route: ^Route,
	units: [dynamic]^Unit,
	units_is_null: bool,
	player: ^Game_Player,
) -> ^string {
	empty_deps: map[^Unit][dynamic]^Unit
	defer delete(empty_deps)
	return move_validator_validate_canal_with_dependents(
		self,
		route,
		units,
		units_is_null,
		empty_deps,
		player,
	)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateCanal(Collection<Unit>, Route, GamePlayer, Map, MoveValidationResult)
// Java (private):
//   private MoveValidationResult validateCanal(
//       final Collection<Unit> units,
//       final Route route,
//       final GamePlayer player,
//       final Map<Unit, Collection<Unit>> airTransportDependents,
//       final MoveValidationResult result) {
//     if (getEditMode(data.getProperties())) { return result; }
//     // TODO: merge validateCanal here and provide granular unit warnings
//     return result.setErrorReturnResult(validateCanal(route, units, airTransportDependents, player));
//   }
// Suffix `_to_result` distinguishes this overload from the public 3-arg
// `move_validator_validate_canal` and the package-private 4-arg
// `move_validator_validate_canal_with_dependents`.
move_validator_validate_canal_to_result :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if edit_delegate_get_edit_mode(game_data_get_properties(self.data)) {
		return result
	}
	rs := move_validator_validate_canal_with_dependents(
		self,
		route,
		units,
		false,
		air_transport_dependents,
		player,
	)
	// Java: result.setErrorReturnResult(@Nullable String). When the inner
	// returns null, MoveValidationResult.setErrorReturnResult(null) is a
	// no-op that returns the same result. Mirror that here.
	if rs == nil {
		return result
	}
	return move_validation_result_set_error_return_result(result, rs^)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#nonParatroopersPresent
// Java (private static):
//   private static boolean nonParatroopersPresent(
//       final GamePlayer player, final Collection<Unit> units) {
//     if (!player.getTechAttachment().getParatroopers()) return true;
//     if (!units.stream().allMatch(Matches.unitIsAir().or(Matches.unitIsLand()))) return true;
//     if (units.stream().anyMatch(not(Matches.unitIsAirTransportable()).and(Matches.unitIsLand()))) return true;
//     return !allLandUnitsHaveAirTransport(units);
//   }
move_validator_non_paratroopers_present :: proc(
	player: ^Game_Player,
	units: [dynamic]^Unit,
) -> bool {
	if !tech_attachment_get_paratroopers(game_player_get_tech_attachment(player)) {
		return true
	}
	air_p, air_c := matches_unit_is_air()
	land_p, land_c := matches_unit_is_land()
	for u in units {
		if !(air_p(air_c, u) || land_p(land_c, u)) {
			return true
		}
	}
	transportable_p, transportable_c := matches_unit_is_air_transportable()
	for u in units {
		if !transportable_p(transportable_c, u) && land_p(land_c, u) {
			return true
		}
	}
	return !move_validator_all_land_units_have_air_transport(units)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateFirst
// Java (private):
//   private MoveValidationResult validateFirst(
//       final Collection<Unit> units, final Route route,
//       final GamePlayer player, final MoveValidationResult result) { ... }
move_validator_validate_first :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if move_validation_result_has_error(
		move_validator_validate_first_units(units, route, result),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_first_route(self, route, units, player, result),
	) {
		return result
	}
	if !edit_delegate_get_edit_mode(game_data_get_properties(self.data)) {
		// matches = units filtered by NOT(unitIsBeingTransportedByOrIsDependentOfSomeUnitInThisList)
		bt_p, bt_c := matches_unit_is_being_transported_by_or_is_dependent_of_some_unit_in_this_list(
			units,
			player,
			true,
		)
		matches: [dynamic]^Unit
		defer delete(matches)
		for u in units {
			if !bt_p(bt_c, u) {
				append(&matches, u)
			}
		}
		owned_p, owned_c := matches_unit_is_owned_by(player)
		all_owned := true
		for u in matches {
			if !owned_p(owned_c, u) {
				all_owned = false
				break
			}
		}
		if len(matches) == 0 || !all_owned {
			move_validation_result_set_error(
				result,
				fmt.aprintf(
					"Player, %s, is not owner of all the units: %s",
					player.named.base.name,
					my_formatter_units_to_text_no_owner_simple(units),
				),
			)
			return result
		}
	}
	return result
}

// Adapter for route.allMatchMiddleSteps(Matches.isTerritoryEnemy(player).negate()).
// route_all_match_middle_steps takes a non-context predicate, but
// matches_is_territory_enemy is player-bound — so we materialize the
// middle steps and check inline (used inside validateCombat).
move_validator_route_all_middle_not_enemy :: proc(
	route: ^Route,
	player: ^Game_Player,
) -> bool {
	middle := route_get_middle_steps(route)
	defer delete(middle)
	if len(middle) == 0 {
		return false
	}
	enemy_p, enemy_c := matches_is_territory_enemy(player)
	for t in middle {
		if enemy_p(enemy_c, t) {
			return false
		}
	}
	return true
}

move_validator_route_any_step_is_enemy :: proc(route: ^Route, player: ^Game_Player) -> bool {
	enemy_p, enemy_c := matches_is_territory_enemy(player)
	for t in route.steps {
		if enemy_p(enemy_c, t) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateCombat
// Java (private): mirrors the long combat-move sanity chain on lines
// 398..573 of MoveValidator.java.
move_validator_validate_combat :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	props := game_data_get_properties(self.data)
	if edit_delegate_get_edit_mode(props) {
		return result
	}
	// route.getSteps()
	steps := route_get_steps(route)
	defer delete(steps)
	move_into_p, move_into_c := matches_territory_owner_relationship_type_can_move_into_during_combat_move(
		player,
	)
	for t in steps {
		if !move_into_p(move_into_c, t) {
			return move_validation_result_set_error_return_result(
				result,
				fmt.aprintf(
					"Cannot move into territories owned by %s during Combat Movement Phase",
					territory_get_owner(t).named.base.name,
				),
			)
		}
	}

	// Contested-enemy block 1.
	all_units_can_attack_from_contested := properties_get_all_units_can_attack_from_contested_territories(
		props,
	)
	start := route_get_start(route)
	at_war_p, at_war_c := matches_is_at_war(player)
	any_route_enemy := move_validator_route_any_step_is_enemy(route, player)
	all_middle_not_enemy := move_validator_route_all_middle_not_enemy(route, player)
	air_p, air_c := matches_unit_is_air()
	if !all_units_can_attack_from_contested &&
	   !territory_is_water(start) &&
	   at_war_p(at_war_c, territory_get_owner(start)) &&
	   any_route_enemy && !all_middle_not_enemy {
		blitz_p, blitz_c := matches_territory_is_blitzable(player)
		all_air := true
		for u in units {
			if !air_p(air_c, u) {
				all_air = false
				break
			}
		}
		if !blitz_p(blitz_c, start) && !all_air {
			return move_validation_result_set_error_return_result(
				result,
				MOVE_VALIDATOR_CANNOT_BLITZ_OUT_OF_BATTLE_FURTHER_INTO_ENEMY_TERRITORY,
			)
		}
		// disallowed = unitCanBlitz().negate().and(unitIsNotAir())
		can_blitz_p, can_blitz_c := matches_unit_can_blitz()
		not_air_p, not_air_c := matches_unit_is_not_air()
		for u in units {
			if !can_blitz_p(can_blitz_c, u) && not_air_p(not_air_c, u) {
				move_validation_result_add_disallowed_unit(
					result,
					MOVE_VALIDATOR_NOT_ALL_UNITS_CAN_BLITZ_OUT_OF_EMPTY_ENEMY_TERRITORY,
					u,
				)
			}
		}
	}

	// Contested-enemy block 2 (start owned by us, moving into enemy).
	if !all_units_can_attack_from_contested &&
	   !territory_is_water(start) &&
	   !at_war_p(at_war_c, territory_get_owner(start)) &&
	   any_route_enemy && !all_middle_not_enemy {
		blitz_p, blitz_c := matches_territory_is_blitzable(player)
		all_air := true
		for u in units {
			if !air_p(air_c, u) {
				all_air = false
				break
			}
		}
		if !blitz_p(blitz_c, start) && !all_air {
			return move_validation_result_set_error_return_result(
				result,
				MOVE_VALIDATOR_CANNOT_BLITZ_OUT_OF_BATTLE_INTO_ENEMY_TERRITORY,
			)
		}
	}

	// AA / units that can't move during combat unless transported.
	cnm_p, cnm_c := matches_unit_can_not_move_during_combat_move()
	any_cnm := false
	for u in units {
		if cnm_p(cnm_c, u) {
			any_cnm = true
			break
		}
	}
	end := route_get_end(route)
	if any_cnm && (!territory_is_water(start) || !territory_is_water(end)) {
		for u in units {
			if cnm_p(cnm_c, u) {
				move_validation_result_add_disallowed_unit(
					result,
					"Cannot move AA guns in combat movement phase",
					u,
				)
			}
		}
	}

	// Neutral in middle stops land units.
	if move_validator_non_air_passing_through_neutral_territory(route, units, props) {
		return move_validation_result_set_error_return_result(
			result,
			"Must stop land units when passing through neutral territories",
		)
	}

	// Land-unit blitz checks over enemy steps.
	land_p, land_c := matches_unit_is_land()
	any_land := false
	for u in units {
		if land_p(land_c, u) {
			any_land = true
			break
		}
	}
	if any_land && route_has_steps(route) {
		bt := abstract_move_delegate_get_battle_tracker(self.data)
		enemy_count: i32 = 0
		all_enemy_blitzable := true
		blitz_p, blitz_c := matches_territory_is_blitzable(player)
		middle := route_get_middle_steps(route)
		defer delete(middle)
		for current in middle {
			if territory_is_water(current) {
				continue
			}
			if game_player_is_at_war(territory_get_owner(current), player) ||
			   battle_tracker_was_conquered(bt, current) {
				enemy_count += 1
				all_enemy_blitzable = all_enemy_blitzable && blitz_p(blitz_c, current)
			}
		}
		if enemy_count > 0 && !all_enemy_blitzable {
			if move_validator_non_paratroopers_present(player, units) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot blitz on that route",
				)
			}
		} else if all_enemy_blitzable && !(territory_is_water(start) || territory_is_water(end)) {
			can_blitz_p, can_blitz_c := matches_unit_can_blitz()
			units_without_dependents := move_validator_find_non_dependent_units(
				units,
				route,
				air_transport_dependents,
			)
			defer delete(units_without_dependents)
			non_blitzing_units: [dynamic]^Unit
			defer delete(non_blitzing_units)
			for u in units_without_dependents {
				if !(can_blitz_p(can_blitz_c, u) || air_p(air_c, u)) {
					append(&non_blitzing_units, u)
				}
			}
			// Remove units that gain blitz via abilities.
			gained := unit_attachment_get_units_which_receives_ability_when_with(
				units,
				ABILITY_CAN_BLITZ,
				game_data_get_unit_type_list(self.data),
			)
			defer delete(gained)
			{
				i := 0
				for i < len(non_blitzing_units) {
					removed := false
					for g in gained {
						if non_blitzing_units[i] == g {
							ordered_remove(&non_blitzing_units, i)
							removed = true
							break
						}
					}
					if !removed {
						i += 1
					}
				}
			}
			// Compute lostBlitz unit-types over either allTerritories or steps.
			was_start_fought_over := battle_tracker_was_conquered(bt, start) ||
				battle_tracker_was_blitzed(bt, start)
			territories_for_lost_blitz: [dynamic]^Territory
			if was_start_fought_over {
				territories_for_lost_blitz = route_get_all_territories(route)
			} else {
				territories_for_lost_blitz = route_get_steps(route)
			}
			defer delete(territories_for_lost_blitz)
			lost_blitz_types := territory_effect_helper_get_unit_types_that_lost_blitz(
				territories_for_lost_blitz,
			)
			defer delete(lost_blitz_types)
			for u in units {
				if _, ok := lost_blitz_types[unit_get_type(u)]; ok {
					already := false
					for n in non_blitzing_units {
						if n == u {
							already = true
							break
						}
					}
					if !already {
						append(&non_blitzing_units, u)
					}
				}
			}
			// Java's "no enemy/non-friendly territory and not fought over" cleanup:
			// nonBlitzingUnits.removeIf(not(Unit::getWasInCombat))
			//   IFF !wasStartFoughtOver && !route.anyMatch(notEndOrFriendlyTerrs)
			//                          && !route.anyMatch(notEndWasFought)
			any_not_end_or_friendly := false
			any_not_end_was_fought := false
			friendly_p, friendly_c := matches_is_territory_friendly(player)
			fought_p, fought_c := matches_territory_was_fought_over(bt)
			for t in route.steps {
				is_not_end := t != end
				if is_not_end && !friendly_p(friendly_c, t) {
					any_not_end_or_friendly = true
				}
				if is_not_end && fought_p(fought_c, t) {
					any_not_end_was_fought = true
				}
			}
			if !was_start_fought_over && !any_not_end_or_friendly && !any_not_end_was_fought {
				i := 0
				for i < len(non_blitzing_units) {
					if !unit_get_was_in_combat(non_blitzing_units[i]) {
						ordered_remove(&non_blitzing_units, i)
					} else {
						i += 1
					}
				}
			}
			if len(non_blitzing_units) > 0 {
				// potentialLandTransports = units \ nonBlitzingUnits
				potential_land_transports: [dynamic]^Unit
				defer delete(potential_land_transports)
				for u in units {
					in_nb := false
					for n in non_blitzing_units {
						if n == u {
							in_nb = true
							break
						}
					}
					if !in_nb {
						append(&potential_land_transports, u)
					}
				}
				disallowed := move_validator_check_land_transports(
					self,
					player,
					potential_land_transports,
					non_blitzing_units,
				)
				defer delete(disallowed)
				for u in disallowed {
					move_validation_result_add_disallowed_unit(
						result,
						MOVE_VALIDATOR_NOT_ALL_UNITS_CAN_BLITZ,
						u,
					)
				}
			}
		}
	}

	// Aircraft / neutral fly-over.
	any_air_unit := false
	for u in units {
		if air_p(air_c, u) {
			any_air_unit = true
			break
		}
	}
	if route_has_steps(route) &&
	   any_air_unit &&
	   (!properties_get_neutral_flyover_allowed(props) ||
		   properties_get_neutrals_impassable(props)) {
		nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
		any_neutral_middle := false
		middle := route_get_middle_steps(route)
		defer delete(middle)
		for t in middle {
			if nbnw_p(nbnw_c, t) {
				any_neutral_middle = true
				break
			}
		}
		moved_p, moved_c := matches_unit_has_moved()
		any_air_moved := false
		for u in units {
			if air_p(air_c, u) && moved_p(moved_c, u) {
				any_air_moved = true
				break
			}
		}
		if any_neutral_middle ||
		   (nbnw_p(nbnw_c, start) && any_air_moved) {
			return move_validation_result_set_error_return_result(
				result,
				"Air units cannot fly over neutral territories",
			)
		}
	}

	// No conquered, non-blitzed, non-water on route.
	all_air2 := true
	for u in units {
		if !air_p(air_c, u) {
			all_air2 = false
			break
		}
	}
	if move_validator_has_conquered_non_blitzed_non_water_on_route(route, self.data) &&
	   !all_air2 {
		return move_validation_result_set_error_return_result(
			result,
			"Cannot move through newly captured territories",
		)
	}

	// "Units cannot participate in multiple battles" combat-state check.
	wic_p, wic_c := matches_unit_was_in_combat()
	wut_p, wut_c := matches_unit_was_unloaded_this_turn()
	any_wic := false
	any_wut := false
	for u in units {
		if !any_wic && wic_p(wic_c, u) {
			any_wic = true
		}
		if !any_wut && wut_p(wut_c, u) {
			any_wut = true
		}
		if any_wic && any_wut {
			break
		}
	}
	enemy_passable_p, enemy_passable_c :=
		matches_is_territory_enemy_and_not_unowned_water_or_impassable_or_restricted(player)
	end_uc := territory_get_unit_collection(end)
	if any_wic && any_wut && enemy_passable_p(enemy_passable_c, end) && len(end_uc.units) != 0 {
		return move_validation_result_set_error_return_result(
			result,
			"Units cannot participate in multiple battles",
		)
	}

	// Invasion in combat phase.
	enemy_terr_p, enemy_terr_c := matches_is_territory_enemy(player)
	if route_is_unload(route) && enemy_terr_p(enemy_terr_c, end) {
		can_invade_p, can_invade_c := matches_unit_can_invade()
		for u in units {
			if !can_invade_p(can_invade_c, u) {
				transport := unit_get_transported_by(u)
				move_validation_result_add_disallowed_unit(
					result,
					fmt.aprintf(
						"%s can't invade from %s",
						unit_get_type(u).named.base.name,
						unit_get_type(transport).named.base.name,
					),
					u,
				)
			}
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateNonCombat
// Java (private): non-combat move validation chain on lines 574..651.
move_validator_validate_non_combat :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	props := game_data_get_properties(self.data)
	if edit_delegate_get_edit_mode(props) {
		return result
	}
	if route_any_match(route, move_validator_lambda_validate_basic_pred_impassable) {
		return move_validation_result_set_error_return_result(
			result,
			MOVE_VALIDATOR_CANT_MOVE_THROUGH_IMPASSABLE,
		)
	}
	// route.anyMatch(territoryIsPassableAndNotRestricted(player))
	any_passable := false
	pass_p, pass_c := matches_territory_is_passable_and_not_restricted(player)
	for t in route.steps {
		if pass_p(pass_c, t) {
			any_passable = true
			break
		}
	}
	if !any_passable {
		return move_validation_result_set_error_return_result(
			result,
			MOVE_VALIDATOR_CANT_MOVE_THROUGH_RESTRICTED,
		)
	}
	// neutralOrEnemy = territoryIsNeutralButNotWater() OR isTerritoryEnemyAndNotUnownedWaterOrImpassableOrRestricted(player)
	nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
	enemy_passable_p, enemy_passable_c :=
		matches_is_territory_enemy_and_not_unowned_water_or_impassable_or_restricted(player)
	is_neutral_or_enemy :: proc(
		t: ^Territory,
		nbnw_p: proc(rawptr, ^Territory) -> bool, nbnw_c: rawptr,
		enemy_passable_p: proc(rawptr, ^Territory) -> bool, enemy_passable_c: rawptr,
	) -> bool {
		return nbnw_p(nbnw_c, t) || enemy_passable_p(enemy_passable_c, t)
	}
	naval_may_not_non_com_into_controlled :=
		properties_get_ww2_v2(props) ||
		properties_get_naval_units_may_not_non_combat_move_into_controlled_sea_zones(props)
	end := route_get_end(route)
	if is_neutral_or_enemy(end, nbnw_p, nbnw_c, enemy_passable_p, enemy_passable_c) {
		if !territory_is_water(end) || naval_may_not_non_com_into_controlled {
			return move_validation_result_set_error_return_result(
				result,
				"Cannot advance units to battle in non combat",
			)
		}
	}
	// Subs can't move under destroyers.
	can_through_p, can_through_c := matches_unit_can_move_through_enemies()
	all_can_through := true
	for u in units {
		if !can_through_p(can_through_c, u) {
			all_can_through = false
			break
		}
	}
	if all_can_through && move_validator_enemy_destroyer_on_path(self, route, player) {
		return move_validation_result_set_error_return_result(
			result,
			"Cannot move submarines under destroyers",
		)
	}
	// Can't advance to battle unless: only ignored units on route, only air to sea,
	// or only units that can enter territories with enemy units during NCM.
	enemy_unit_p, enemy_unit_c := matches_enemy_unit(player)
	sub_p, sub_c := matches_unit_is_submerged()
	enemy_unit_not_sub :: proc(
		u: ^Unit,
		enemy_unit_p: proc(rawptr, ^Unit) -> bool, enemy_unit_c: rawptr,
		sub_p: proc(rawptr, ^Unit) -> bool, sub_c: rawptr,
	) -> bool {
		return enemy_unit_p(enemy_unit_c, u) && !sub_p(sub_c, u)
	}
	any_enemy_not_sub := false
	for u in territory_get_unit_collection(end).units {
		if enemy_unit_not_sub(u, enemy_unit_p, enemy_unit_c, sub_p, sub_c) {
			any_enemy_not_sub = true
			break
		}
	}
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	subs_can_end_ncm := properties_get_subs_can_end_non_combat_move_with_enemies(props)
	all_can_through2 := true
	for u in units {
		if !can_through_p(can_through_c, u) {
			all_can_through2 = false
			break
		}
	}
	if any_enemy_not_sub &&
	   !move_validator_only_ignored_units_on_path(self, route, player, false) &&
	   !(territory_is_water(end) && all_air) &&
	   !(subs_can_end_ncm && all_can_through2) {
		return move_validation_result_set_error_return_result(
			result,
			"Cannot advance to battle in non combat",
		)
	}
	// Now check movement over neutral/enemy territories during noncombat.
	sea_p, sea_c := matches_unit_is_sea()
	any_sea := false
	for u in units {
		if sea_p(sea_c, u) {
			any_sea = true
			break
		}
	}
	water_p, water_c := matches_territory_is_water()
	any_water_in_route := false
	for t in route.steps {
		if water_p(water_c, t) {
			any_water_in_route = true
			break
		}
	}
	any_neutral_or_enemy_in_route := false
	for t in route.steps {
		if is_neutral_or_enemy(t, nbnw_p, nbnw_c, enemy_passable_p, enemy_passable_c) {
			any_neutral_or_enemy_in_route = true
			break
		}
	}
	non_paratroopers := move_validator_non_paratroopers_present(player, units)
	if all_air || (!any_sea && !non_paratroopers) {
		// Air-only flow check for neutral non-water along route.
		any_neutral_non_water := false
		for t in route.steps {
			if nbnw_p(nbnw_c, t) && !water_p(water_c, t) {
				any_neutral_non_water = true
				break
			}
		}
		if any_neutral_non_water &&
		   (!properties_get_neutral_flyover_allowed(props) ||
			   properties_get_neutrals_impassable(props)) {
			return move_validation_result_set_error_return_result(
				result,
				"Air units cannot fly over neutral territories in non combat",
			)
		}
	} else if any_sea || any_water_in_route {
		if naval_may_not_non_com_into_controlled && any_neutral_or_enemy_in_route {
			return move_validation_result_set_error_return_result(
				result,
				"Cannot move units through neutral or enemy territories in non combat",
			)
		}
	} else {
		if any_neutral_or_enemy_in_route {
			return move_validation_result_set_error_return_result(
				result,
				"Cannot move units through neutral or enemy territories in non combat",
			)
		}
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateNonEnemyUnitsOnPath
// Java (private): lines 684..717 of MoveValidator.java.
move_validator_validate_non_enemy_units_on_path :: proc(
	self: ^Move_Validator,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	if edit_delegate_get_edit_mode(game_data_get_properties(self.data)) {
		return result
	}
	if move_validator_no_enemy_units_on_path_middle_steps(self, route, player) {
		return result
	}
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	if all_air {
		return result
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	matches_units: [dynamic]^Unit
	defer delete(matches_units)
	for u in units {
		if !bt_p(bt_c, u) {
			append(&matches_units, u)
		}
	}
	if len(matches_units) > 0 {
		can_through_p, can_through_c := matches_unit_can_move_through_enemies()
		all_can_through := true
		for u in matches_units {
			if !can_through_p(can_through_c, u) {
				all_can_through = false
				break
			}
		}
		if all_can_through {
			if move_validator_enemy_destroyer_on_path(self, route, player) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot move submarines under destroyers",
				)
			}
			return result
		}
	}
	if move_validator_only_ignored_units_on_path(self, route, player, true) {
		return result
	}
	if move_validator_non_paratroopers_present(player, units) {
		return move_validation_result_set_error_return_result(result, "Enemy units on path")
	}
	return result
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateTransport
// Java (private): lines 1146..1378 of MoveValidator.java.
move_validator_validate_transport :: proc(
	self: ^Move_Validator,
	undoable_moves: [dynamic]^Undoable_Move,
	units: [dynamic]^Unit,
	route: ^Route,
	player: ^Game_Player,
	units_to_sea_transports: map[^Unit]^Unit,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	if !route_has_water(route) || all_air {
		return result
	}
	// loadingNonSeaTransportsOnly:
	//   !unitsToSeaTransports.isEmpty()
	//     && unitsToSeaTransports.values().noneMatch(unitIsSea().and(unitCanTransport()))
	sea_p, sea_c := matches_unit_is_sea()
	can_transport_p, can_transport_c := matches_unit_can_transport()
	loading_non_sea_only := false
	if len(units_to_sea_transports) > 0 {
		any_sea_transport := false
		for _, t in units_to_sea_transports {
			if sea_p(sea_c, t) && can_transport_p(can_transport_c, t) {
				any_sea_transport = true
				break
			}
		}
		loading_non_sea_only = !any_sea_transport
	}
	if loading_non_sea_only {
		return result
	}
	props := game_data_get_properties(self.data)
	is_edit_mode := edit_delegate_get_edit_mode(props)
	route_end := route_get_end(route)
	route_start := route_get_start(route)
	if !is_edit_mode && route_is_unload(route) {
		if route_has_more_than_one_step(route) {
			return move_validation_result_set_error_return_result(
				result,
				"Unloading units must stop where they are unloaded",
			)
		}
		loaded_allied := transport_tracker_get_units_loaded_on_allied_transports_this_turn(units)
		defer delete(loaded_allied)
		for u in loaded_allied {
			move_validation_result_add_disallowed_unit(
				result,
				MOVE_VALIDATOR_CANNOT_LOAD_AND_UNLOAD_AN_ALLIED_TRANSPORT_IN_THE_SAME_ROUND,
				u,
			)
		}
		empty_to_load: [dynamic]^Unit
		defer delete(empty_to_load)
		transports_map := transport_utils_map_transports(route, units, empty_to_load)
		defer delete(transports_map)
		transports: [dynamic]^Unit
		defer delete(transports)
		for _, t in transports_map {
			append(&transports, t)
		}
		is_scrambling_or_kamikaze :=
			properties_get_scramble_rules_in_effect(props) ||
			properties_get_use_kamikaze_suicide_attacks(props)
		subs_prevent_unescorted := properties_get_submarines_prevent_unescorted_amphibious_assaults(
			props,
		)
		enemy_of_p, enemy_of_c := matches_unit_is_enemy_of(player)
		can_through_p, can_through_c := matches_unit_can_be_moved_through_by_enemies()
		owned_p, owned_c := matches_unit_is_owned_by(player)
		non_xport_combat_p, non_xport_combat_c := matches_unit_is_not_sea_transport_but_could_be_combat_sea_transport()
		// enemySubMatch = unitIsEnemyOf(player) AND unitCanBeMovedThroughByEnemies()
		// ownedSeaNonTransportMatch = ownedBy(player) AND unitIsSea() AND unitIsNotSeaTransportButCouldBeCombatSeaTransport()
		territory_has_enemy_sub :: proc(
			t: ^Territory,
			enemy_of_p: proc(rawptr, ^Unit) -> bool, enemy_of_c: rawptr,
			can_through_p: proc(rawptr, ^Unit) -> bool, can_through_c: rawptr,
		) -> bool {
			for u in territory_get_unit_collection(t).units {
				if enemy_of_p(enemy_of_c, u) && can_through_p(can_through_c, u) {
					return true
				}
			}
			return false
		}
		territory_has_owned_sea_non_xport :: proc(
			t: ^Territory,
			owned_p: proc(rawptr, ^Unit) -> bool, owned_c: rawptr,
			sea_p: proc(rawptr, ^Unit) -> bool, sea_c: rawptr,
			nxc_p: proc(rawptr, ^Unit) -> bool, nxc_c: rawptr,
		) -> bool {
			for u in territory_get_unit_collection(t).units {
				if owned_p(owned_c, u) &&
				   sea_p(sea_c, u) &&
				   nxc_p(nxc_c, u) {
					return true
				}
			}
			return false
		}
		t_has_enemy_units_p, t_has_enemy_units_c := matches_territory_has_enemy_units(player)
		t_is_enemy_p, t_is_enemy_c := matches_is_territory_enemy_and_not_unowned_water(player)
		t_empty_combat_p, t_empty_combat_c := matches_territory_is_empty_of_combat_units(player)
		bt := abstract_move_delegate_get_battle_tracker(self.data)
		for transport in transports {
			if !self.is_non_combat {
				if t_has_enemy_units_p(t_has_enemy_units_c, route_end) ||
				   t_is_enemy_p(t_is_enemy_c, route_end) {
					// amphibious assault
					if subs_prevent_unescorted &&
					   !territory_has_owned_sea_non_xport(
						   route_start,
						   owned_p, owned_c,
						   sea_p, sea_c,
						   non_xport_combat_p, non_xport_combat_c,
					   ) &&
					   territory_has_enemy_sub(
						   route_start,
						   enemy_of_p, enemy_of_c,
						   can_through_p, can_through_c,
					   ) {
						transporting := unit_get_transporting(transport)
						defer delete(transporting)
						for u in transporting {
							move_validation_result_add_disallowed_unit(
								result,
								MOVE_VALIDATOR_ENEMY_SUBMARINE_PREVENTING_UNESCORTED_AMPHIBIOUS_ASSAULT_LANDING,
								u,
							)
						}
					}
				} else if !battle_tracker_was_conquered(bt, route_end) &&
				   (is_scrambling_or_kamikaze ||
					   !t_empty_combat_p(t_empty_combat_c, route_start)) {
					transporting := unit_get_transporting(transport)
					defer delete(transporting)
					for u in transporting {
						move_validation_result_add_disallowed_unit(
							result,
							MOVE_VALIDATOR_TRANSPORT_MAY_NOT_UNLOAD_TO_FRIENDLY_TERRITORIES_UNTIL_AFTER_COMBAT_IS_RESOLVED,
							u,
						)
					}
				}
			}
			if transport_tracker_has_transport_unloaded_in_previous_phase(transport) {
				transporting := unit_get_transporting(transport)
				defer delete(transporting)
				for u in transporting {
					move_validation_result_add_disallowed_unit(
						result,
						MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_IN_A_PREVIOUS_PHASE,
						u,
					)
				}
			} else if transport_tracker_is_transport_unload_restricted_to_another_territory(
				transport,
				route_end,
			) {
				already_unloaded_to := move_validator_get_territory_transport_has_unloaded_to(
					undoable_moves,
					transport,
				)
				if already_unloaded_to != nil {
					transporting := unit_get_transporting(transport)
					defer delete(transporting)
					for u in transporting {
						move_validation_result_add_disallowed_unit(
							result,
							fmt.aprintf(
								"%s%s",
								MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_TO,
								already_unloaded_to.named.base.name,
							),
							u,
						)
					}
				}
			} else if transport_tracker_is_transport_unload_restricted_in_non_combat(transport) {
				transporting := unit_get_transporting(transport)
				defer delete(transporting)
				for u in transporting {
					move_validation_result_add_disallowed_unit(
						result,
						MOVE_VALIDATOR_TRANSPORT_CANNOT_LOAD_AND_UNLOAD_AFTER_COMBAT,
						u,
					)
				}
			}
		}
	}
	// land/landAndAir collections.
	land_p, land_c := matches_unit_is_land()
	land: [dynamic]^Unit
	defer delete(land)
	land_and_air: [dynamic]^Unit
	defer delete(land_and_air)
	for u in units {
		if land_p(land_c, u) {
			append(&land, u)
		}
		if land_p(land_c, u) || air_p(air_c, u) {
			append(&land_and_air, u)
		}
	}
	can_be_xport_p, can_be_xport_c := matches_unit_can_be_transported()
	for u in land {
		if !can_be_xport_p(can_be_xport_c, u) {
			move_validation_result_add_disallowed_unit(
				result,
				"Not all units can be transported",
				u,
			)
		}
	}
	// "go sea land sea" guard.
	if !is_edit_mode &&
	   route_has_land(route) &&
	   !(territory_is_water(route_start) || territory_is_water(route_end)) &&
	   move_validator_non_paratroopers_present(player, land_and_air) {
		return move_validation_result_set_error_return_result(
			result,
			"Invalid move, only start or end can be land when route has water.",
		)
	}
	if !is_edit_mode &&
	   !territory_is_water(route_end) &&
	   !territory_is_water(route_start) &&
	   move_validator_non_paratroopers_present(player, land_and_air) {
		return move_validation_result_set_error_return_result(
			result,
			"Must stop units at a transport on route",
		)
	}
	if territory_is_water(route_end) && territory_is_water(route_start) {
		for unit in units {
			ua := unit_get_unit_attachment(unit)
			if unit_attachment_get_transport_capacity(ua) != -1 {
				holding := unit_get_transporting(unit)
				defer delete(holding)
				for h in holding {
					found := false
					for u in units {
						if u == h {
							found = true
							break
						}
					}
					if !found {
						move_validation_result_add_disallowed_unit(
							result,
							"Transports cannot leave their units",
							unit,
						)
						break
					}
				}
			}
			if unit_attachment_get_transport_cost(ua) != -1 {
				transport := unit_get_transported_by(unit)
				if transport != nil {
					found := false
					for u in units {
						if u == transport {
							found = true
							break
						}
					}
					if !found {
						move_validation_result_add_disallowed_unit(
							result,
							"Unit must stay with its transport while moving",
							unit,
						)
					}
				}
			}
		}
	}
	if route_is_load(route) {
		if !is_edit_mode &&
		   !route_has_exactly_one_step(route) &&
		   move_validator_non_paratroopers_present(player, land_and_air) {
			return move_validation_result_set_error_return_result(
				result,
				"Units cannot move before loading onto transports",
			)
		}
		// enemyNonSubmerged check at route end.
		enemy_unit_p, enemy_unit_c := matches_enemy_unit(player)
		sub_p, sub_c := matches_unit_is_submerged()
		any_enemy_non_sub_at_end := false
		for u in territory_get_unit_collection(route_end).units {
			if enemy_unit_p(enemy_unit_c, u) && !sub_p(sub_c, u) {
				any_enemy_non_sub_at_end = true
				break
			}
		}
		if !properties_get_units_can_load_in_hostile_sea_zones(props) &&
		   any_enemy_non_sub_at_end &&
		   move_validator_non_paratroopers_present(player, land_and_air) &&
		   !move_validator_only_ignored_units_on_path(self, route, player, false) {
			bt := abstract_move_delegate_get_battle_tracker(self.data)
			end_units := territory_get_unit_collection(route_end).units
			if !battle_tracker_did_all_these_players_just_go_to_war_this_turn(
				bt,
				player,
				end_units,
			) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot load when enemy sea units are present",
				)
			}
		}
		if !is_edit_mode {
			for base_unit in land {
				if unit_has_moved(base_unit) {
					move_validation_result_add_disallowed_unit(
						result,
						"Units cannot move before loading onto transports",
						base_unit,
					)
				}
				transport, ok := units_to_sea_transports[base_unit]
				if !ok {
					continue
				}
				if transport_tracker_has_transport_unloaded_in_previous_phase(transport) {
					move_validation_result_add_disallowed_unit(
						result,
						MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_IN_A_PREVIOUS_PHASE,
						base_unit,
					)
				} else if transport_tracker_is_transport_load_restricted_after_combat(transport) {
					move_validation_result_add_disallowed_unit(
						result,
						MOVE_VALIDATOR_TRANSPORT_CANNOT_LOAD_AFTER_COMBAT,
						base_unit,
					)
				} else if transport_tracker_is_transport_unload_restricted_to_another_territory(
					transport,
					route_end,
				) {
					already_unloaded_to: ^Territory =
						move_validator_get_territory_transport_has_unloaded_to(
							undoable_moves,
							transport,
						)
					for _, transport_to_load in units_to_sea_transports {
						if !transport_tracker_is_transport_unload_restricted_to_another_territory(
							transport_to_load,
							route_end,
						) {
							ua := unit_get_unit_attachment(base_unit)
							if transport_tracker_get_available_capacity(transport_to_load) >=
							   unit_attachment_get_transport_cost(ua) {
								already_unloaded_to = nil
								break
							}
						}
					}
					if already_unloaded_to != nil {
						move_validation_result_add_disallowed_unit(
							result,
							fmt.aprintf(
								"%s%s",
								MOVE_VALIDATOR_TRANSPORT_HAS_ALREADY_UNLOADED_UNITS_TO,
								already_unloaded_to.named.base.name,
							),
							base_unit,
						)
					}
				}
			}
		}
		// not all land mapped → "Not enough transports" / unresolved.
		all_mapped := true
		for u in land {
			if _, ok := units_to_sea_transports[u]; !ok {
				all_mapped = false
				break
			}
		}
		if !all_mapped {
			units_to_load_categories := unit_separator_categorize_default(land)
			defer delete(units_to_load_categories)
			if len(units_to_sea_transports) == 0 || len(units_to_load_categories) == 1 {
				for unit in land {
					if _, ok := units_to_sea_transports[unit]; ok {
						continue
					}
					ua := unit_get_unit_attachment(unit)
					if unit_attachment_get_transport_cost(ua) != -1 {
						move_validation_result_add_disallowed_unit(
							result,
							"Not enough transports",
							unit,
						)
					}
				}
			} else {
				for unit in land {
					ua := unit_get_unit_attachment(unit)
					if unit_attachment_get_transport_cost(ua) != -1 {
						move_validation_result_add_unresolved_unit(
							result,
							"Not enough transports",
							unit,
						)
					}
				}
			}
		}
	}
	return result
}


// games.strategy.triplea.delegate.move.validation.MoveValidator#validateFuel
// Java: private MoveValidationResult validateFuel(Collection<Unit>, Route,
//       GamePlayer, MoveValidationResult)
move_validator_validate_fuel :: proc(
	self: ^Move_Validator,
	units: []^Unit,
	route: ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	props := game_data_get_properties(self.data)
	if edit_delegate_get_edit_mode(props) {
		return result
	}
	if !properties_get_use_fuel_cost(props) {
		return result
	}
	fuel_cost := route_get_movement_fuel_cost_charge(units, route, player, self.data)
	resources_copy := resource_collection_get_resources_copy(fuel_cost)
	if resource_collection_has(game_player_get_resources(player), &resources_copy) {
		return result
	}
	return move_validation_result_set_error_return_result(
		result,
		fmt.aprintf(
			"Not enough resources to perform this move, you need: %v for this move",
			fuel_cost,
		),
	)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateMove(
//   games.strategy.engine.data.MoveDescription,
//   games.strategy.engine.data.GamePlayer)
// Java: public MoveValidationResult validateMove(MoveDescription move,
//       GamePlayer player) { return validateMove(move, player, List.of()); }
move_validator_validate_move_simple :: proc(
	self: ^Move_Validator,
	move: ^Move_Description,
	player: ^Game_Player,
) -> ^Move_Validation_Result {
	empty: [dynamic]^Undoable_Move
	defer delete(empty)
	return move_validator_validate_move(self, move, player, empty)
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#validateMove(
//   games.strategy.engine.data.MoveDescription,
//   games.strategy.engine.data.GamePlayer,
//   java.util.List)
// Java: public MoveValidationResult validateMove(MoveDescription move,
//       GamePlayer player, List<UndoableMove> undoableMoves)
move_validator_validate_move :: proc(
	self: ^Move_Validator,
	move: ^Move_Description,
	player: ^Game_Player,
	undoable_moves: [dynamic]^Undoable_Move,
) -> ^Move_Validation_Result {
	units := move.abstract_move_description.units
	route := move_description_get_route(move)
	units_to_sea_transports := move_description_get_units_to_sea_transports(move)
	air_transports_set := move_description_get_air_transports_dependents(move)

	// Move_Description stores airTransportsDependents as Set<Unit> per key
	// (`map[^Unit]map[^Unit]struct{}`), but the validate_* procs accept the
	// `Map<Unit, Collection<Unit>>` form (`map[^Unit][dynamic]^Unit`). Build
	// a transient view in the dynamic-array shape.
	air_transport_dependents := make(map[^Unit][dynamic]^Unit)
	defer {
		for _, v in air_transport_dependents {
			delete(v)
		}
		delete(air_transport_dependents)
	}
	for k, v in air_transports_set {
		arr: [dynamic]^Unit
		for u, _ in v {
			append(&arr, u)
		}
		air_transport_dependents[k] = arr
	}

	result := move_validation_result_new()
	if route_has_no_steps(route) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_first(self, units, route, player, result),
	) {
		return result
	}
	if self.is_non_combat {
		if move_validation_result_has_error(
			move_validator_validate_non_combat(self, units, route, player, result),
		) {
			return result
		}
	} else {
		if move_validation_result_has_error(
			move_validator_validate_combat(
				self,
				units,
				air_transport_dependents,
				route,
				player,
				result,
			),
		) {
			return result
		}
	}
	if move_validation_result_has_error(
		move_validator_validate_non_enemy_units_on_path(self, units, route, player, result),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_basic(
			self,
			units,
			route,
			player,
			units_to_sea_transports,
			air_transport_dependents,
			result,
		),
	) {
		return result
	}
	if move_validation_result_has_error(
		air_movement_validator_validate_air_can_land(units[:], route, player, result),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_transport(
			self,
			undoable_moves,
			units,
			route,
			player,
			units_to_sea_transports,
			result,
		),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_paratroops(
			self,
			units,
			air_transport_dependents,
			route,
			player,
			result,
		),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_canal_to_result(
			self,
			units,
			route,
			player,
			air_transport_dependents,
			result,
		),
	) {
		return result
	}
	if move_validation_result_has_error(
		move_validator_validate_fuel(self, units[:], route, player, result),
	) {
		return result
	}

	// Don't let the user move out of a battle zone, the exception is air
	// units and unloading units into a battle zone.
	bt := abstract_move_delegate_get_battle_tracker(self.data)
	not_air_pred, not_air_ctx := matches_unit_is_not_air()
	any_not_air := false
	for u in units {
		if not_air_pred(not_air_ctx, u) {
			any_not_air = true
			break
		}
	}
	if battle_tracker_has_pending_non_bombing_battle(bt, route_get_start(route)) &&
	   any_not_air {
		units_started_in_territory := true
		for unit in units {
			if abstract_move_delegate_get_route_used_to_move_into(
				   undoable_moves,
				   unit,
				   route_get_end(route),
			   ) != nil {
				units_started_in_territory = false
				break
			}
		}
		if !units_started_in_territory {
			unload := route_is_unload(route)
			end_owner := territory_get_owner(route_get_end(route))
			attack :=
				!game_player_is_allied(end_owner, player) ||
				battle_tracker_was_conquered(bt, route_get_end(route))
			if !(unload && attack) {
				return move_validation_result_set_error_return_result(
					result,
					"Cannot move units out of battle zone",
				)
			}
		}
	}
	return result
}
