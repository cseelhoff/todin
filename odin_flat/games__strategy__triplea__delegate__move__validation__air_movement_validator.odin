package game

Air_Movement_Validator :: struct {}

// Java: private static Comparator<Territory> getLowestToHighestDistance(
//     final Territory territoryWeMeasureDistanceFrom,
//     final Predicate<Territory> condition) { ... }
//
// The returned comparator captures both `territoryWeMeasureDistanceFrom`
// and `condition`. Per the closure-capture convention
// (llm-instructions.md), we pair a non-capturing trampoline with a
// heap-allocated ctx. The returned shape is a less-than predicate
// `proc(rawptr, ^Territory, ^Territory) -> bool` (the form consumed by
// Odin sort routines), matching the pattern already established by
// other Comparator<T> ports in this package. The Java rules collapse
// to: territories that are unreachable (-1) sort AFTER reachable ones;
// otherwise smaller distance sorts first; ties report not-less.
Air_Movement_Validator_Get_Lowest_To_Highest_Distance_Ctx :: struct {
	territory_we_measure_distance_from: ^Territory,
	condition:                          proc(rawptr, ^Territory) -> bool,
	condition_ctx:                      rawptr,
}

air_movement_validator_get_lowest_to_highest_distance_less :: proc(
	ctx: rawptr,
	t1: ^Territory,
	t2: ^Territory,
) -> bool {
	c := cast(^Air_Movement_Validator_Get_Lowest_To_Highest_Distance_Ctx)ctx
	if t1 == t2 {
		return false
	}
	game_map := game_data_get_map(
		game_data_component_get_data(&t1.game_data_component),
	)
	distance1 := game_map_get_distance_predicate(
		game_map,
		c.territory_we_measure_distance_from,
		t1,
		c.condition,
		c.condition_ctx,
	)
	distance2 := game_map_get_distance_predicate(
		game_map,
		c.territory_we_measure_distance_from,
		t2,
		c.condition,
		c.condition_ctx,
	)
	if distance1 == distance2 {
		return false
	}
	if distance1 < 0 {
		// Java returns 1 → t1 sorts after t2 → t1 is NOT less.
		return false
	}
	if distance2 < 0 {
		// Java returns -1 → t1 sorts before t2 → t1 IS less.
		return true
	}
	return distance1 < distance2
}

air_movement_validator_get_lowest_to_highest_distance :: proc(
	territory_we_measure_distance_from: ^Territory,
	condition: proc(rawptr, ^Territory) -> bool,
	condition_ctx: rawptr,
) -> (
	proc(rawptr, ^Territory, ^Territory) -> bool,
	rawptr,
) {
	ctx := new(Air_Movement_Validator_Get_Lowest_To_Highest_Distance_Ctx)
	ctx.territory_we_measure_distance_from = territory_we_measure_distance_from
	ctx.condition = condition
	ctx.condition_ctx = condition_ctx
	return air_movement_validator_get_lowest_to_highest_distance_less, rawptr(ctx)
}

// Java: private static Comparator<Unit>
//     getLowestToHighestMovementComparatorIncludingUnitsNotYetMoved(final Route route) {
//   return Comparator.comparing(u -> getMovementLeftForAirUnitNotMovedYet(u, route));
// }
//
// The lambda captures `route`. We use the closure-capture convention:
// a heap-allocated ctx holding `^Route`, and the returned comparator is
// the less-than trampoline paired with that ctx. Comparator.comparing
// over a Comparable produces ascending natural order, so the trampoline
// returns `a < b` over the captured-key extraction.
Air_Movement_Validator_Get_Lowest_To_Highest_Movement_Comparator_Including_Units_Not_Yet_Moved_Ctx :: struct {
	route: ^Route,
}

air_movement_validator_get_lowest_to_highest_movement_comparator_including_units_not_yet_moved_less :: proc(
	ctx: rawptr,
	u1: ^Unit,
	u2: ^Unit,
) -> bool {
	c :=
		cast(^Air_Movement_Validator_Get_Lowest_To_Highest_Movement_Comparator_Including_Units_Not_Yet_Moved_Ctx)ctx
	a := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(u1, c.route)
	b := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(u2, c.route)
	return a < b
}

air_movement_validator_get_lowest_to_highest_movement_comparator_including_units_not_yet_moved :: proc(
	route: ^Route,
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx :=
		new(Air_Movement_Validator_Get_Lowest_To_Highest_Movement_Comparator_Including_Units_Not_Yet_Moved_Ctx)
	ctx.route = route
	return air_movement_validator_get_lowest_to_highest_movement_comparator_including_units_not_yet_moved_less,
		rawptr(ctx)
}

// Java: private static Predicate<Unit> unitCanFindLand(
//     final GameData data, final Territory current) {
//   return u -> canFindLand(data, u, current);
// }
//
// The lambda captures `data` and `current`. Per the closure-capture
// convention, we pair a non-capturing trampoline with a small ctx and
// return a `proc(rawptr, ^Unit) -> bool` predicate. The trampoline
// forwards to the 3-argument `canFindLand(GameData, Unit, Territory)`
// overload (arity-3-Territory variant) which is named in this package
// as `air_movement_validator_can_find_land_3`.
Air_Movement_Validator_Unit_Can_Find_Land_Ctx :: struct {
	data:    ^Game_Data,
	current: ^Territory,
}

air_movement_validator_unit_can_find_land_predicate :: proc(
	ctx: rawptr,
	u: ^Unit,
) -> bool {
	c := cast(^Air_Movement_Validator_Unit_Can_Find_Land_Ctx)ctx
	return air_movement_validator_can_find_land_3(c.data, u, c.current)
}

air_movement_validator_unit_can_find_land :: proc(
	data: ^Game_Data,
	current: ^Territory,
) -> (
	proc(rawptr, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Air_Movement_Validator_Unit_Can_Find_Land_Ctx)
	ctx.data = data
	ctx.current = current
	return air_movement_validator_unit_can_find_land_predicate, rawptr(ctx)
}

// Java: public static Collection<Unit> getFriendly(
//     final Territory territory, final GamePlayer player, final GameState data) {
//   return territory.getMatches(Matches.alliedUnit(player));
// }
//
// `data` is unused in Java; mirror the signature. Territory.getMatches
// is a UnitHolder default that delegates to UnitCollection.getMatches,
// which in turn filters territory.unit_collection.units by the predicate.
air_movement_validator_get_friendly :: proc(
	territory: ^Territory,
	player:    ^Game_Player,
	data:      ^Game_Data,
) -> [dynamic]^Unit {
	_ = data
	pred, pred_ctx := matches_allied_unit(player)
	result: [dynamic]^Unit
	for u in territory.unit_collection.units {
		if pred(pred_ctx, u) {
			append(&result, u)
		}
	}
	return result
}

// Java: public static int carrierCapacity(
//     final Unit unit, final Territory territoryUnitsAreCurrentlyIn) { ... }
//
// Mirrors the Java logic exactly: non-carriers report 0; carriers
// without the UNITS_MAY_NOT_LAND_ON_CARRIER combat-damaged effect
// report their attachment's full carrier capacity; carriers with
// that effect AND with UNITS_MAY_NOT_LEAVE_ALLIED_CARRIER report 0;
// otherwise report the carrier-cost sum of any allied air cargo
// already transported by this carrier in the territory.
air_movement_validator_carrier_capacity_unit :: proc(
	unit: ^Unit,
	territory_units_are_currently_in: ^Territory,
) -> i32 {
	carrier_pred, carrier_ctx := matches_unit_is_carrier()
	if !carrier_pred(carrier_ctx, unit) {
		return 0
	}
	if !air_movement_validator_unit_has_combat_damaged_effect(
		unit,
		"unitsMayNotLandOnCarrier",
	) {
		return unit_attachment_get_carrier_capacity(unit_get_unit_attachment(unit))
	}
	if !air_movement_validator_unit_has_combat_damaged_effect(
		unit,
		"unitsMayNotLeaveAlliedCarrier",
	) {
		return 0
	}
	cargo: i32 = 0
	air_pred, air_ctx := matches_unit_is_air()
	land_pred, land_ctx := matches_unit_can_land_on_carrier()
	for air_unit in territory_units_are_currently_in.unit_collection.units {
		if !air_pred(air_ctx, air_unit) {
			continue
		}
		if !land_pred(land_ctx, air_unit) {
			continue
		}
		transported_by := unit_get_transported_by(air_unit)
		if transported_by != nil && transported_by == unit {
			cargo += unit_attachment_get_carrier_cost(
				unit_get_unit_attachment(air_unit),
			)
		}
	}
	return cargo
}

// Helper for carrierCapacity above. Java calls
//   Matches.unitHasWhenCombatDamagedEffect(EFFECT).test(unit)
// which returns true iff any of the unit's WhenCombatDamaged entries
// has the given effect string. The package-level
// matches_unit_has_when_combat_damaged_effect predicate is the
// no-arg overload (any effect), so we open-code the per-effect
// filter here.
air_movement_validator_unit_has_combat_damaged_effect :: proc(
	unit: ^Unit,
	effect: string,
) -> bool {
	entries := unit_attachment_get_when_combat_damaged(unit_get_unit_attachment(unit))
	for w in entries {
		if w != nil && w.effect == effect {
			return true
		}
	}
	return false
}

// Java: public static int carrierCost(final Unit unit) {
//   if (Matches.unitCanLandOnCarrier().test(unit)) {
//     return unit.getUnitAttachment().getCarrierCost();
//   }
//   return 0;
// }
air_movement_validator_carrier_cost_unit :: proc(unit: ^Unit) -> i32 {
	pred, ctx := matches_unit_can_land_on_carrier()
	if pred(ctx, unit) {
		return unit_attachment_get_carrier_cost(unit_get_unit_attachment(unit))
	}
	return 0
}

// Java: private static boolean getEditMode(final GameState data) {
//   return EditDelegate.getEditMode(data.getProperties());
// }
air_movement_validator_get_edit_mode :: proc(data: ^Game_State) -> bool {
	return edit_delegate_get_edit_mode(game_state_get_properties(data))
}

// Java synthetic: lambda$populateStaticAlliedAndBuildingCarrierCapacity$0
//   from the .map(units -> units.getMatches(Matches.unitIsCarrier()))
// stage of the carriersInProductionQueue stream pipeline. Takes a
// UnitCollection and returns the matched carriers.
air_movement_validator_lambda_populate_static_allied_and_building_carrier_capacity_0 :: proc(
	units: ^Unit_Collection,
) -> [dynamic]^Unit {
	pred, ctx := matches_unit_is_carrier()
	result: [dynamic]^Unit
	if units == nil {
		return result
	}
	for u in units.units {
		if pred(ctx, u) {
			append(&result, u)
		}
	}
	return result
}

// Java: public static int carrierCapacity(
//     final Collection<Unit> units, final Territory territoryUnitsAreCurrentlyIn) {
//   int sum = 0;
//   for (final Unit unit : units) {
//     sum += carrierCapacity(unit, territoryUnitsAreCurrentlyIn);
//   }
//   return sum;
// }
air_movement_validator_carrier_capacity :: proc(
	units: []^Unit,
	territory_units_are_currently_in: ^Territory,
) -> i32 {
	sum: i32 = 0
	for unit in units {
		sum += air_movement_validator_carrier_capacity_unit(
			unit,
			territory_units_are_currently_in,
		)
	}
	return sum
}

// Java: public static int carrierCost(final Collection<Unit> units) {
//   int sum = 0;
//   for (final Unit unit : units) {
//     sum += carrierCost(unit);
//   }
//   return sum;
// }
air_movement_validator_carrier_cost :: proc(units: []^Unit) -> i32 {
	sum: i32 = 0
	for unit in units {
		sum += air_movement_validator_carrier_cost_unit(unit)
	}
	return sum
}

// Java: private static boolean areNeutralsPassableByAir(final GameState data) {
//   return Properties.getNeutralFlyoverAllowed(data.getProperties())
//       && !Properties.getNeutralsImpassable(data.getProperties());
// }
air_movement_validator_are_neutrals_passable_by_air :: proc(data: ^Game_State) -> bool {
	props := game_state_get_properties(data)
	return properties_get_neutral_flyover_allowed(props) &&
		!properties_get_neutrals_impassable(props)
}

// Java: private static int getNeutralCharge(final GameState data, final int numberOfTerritories) {
//   return numberOfTerritories * Properties.getNeutralCharge(data.getProperties());
// }
air_movement_validator_get_neutral_charge :: proc(
	data: ^Game_State,
	number_of_territories: i32,
) -> i32 {
	return number_of_territories *
		properties_get_neutral_charge(game_state_get_properties(data))
}

// Java: public static Collection<Unit> whatAirCanLandOnTheseCarriers(
//     final Collection<Unit> carriers,
//     final Collection<Unit> airUnits,
//     final Territory territoryUnitsAreIn) {
//   final Collection<Unit> airThatCanLandOnThem = new ArrayList<>();
//   for (final Unit carrier : carriers) {
//     int carrierCapacity = carrierCapacity(carrier, territoryUnitsAreIn);
//     for (final Unit air : airUnits) {
//       if (airThatCanLandOnThem.contains(air)) { continue; }
//       final int airCost = carrierCost(air);
//       if (carrierCapacity >= airCost) {
//         carrierCapacity -= airCost;
//         airThatCanLandOnThem.add(air);
//       }
//     }
//   }
//   return airThatCanLandOnThem;
// }
air_movement_validator_what_air_can_land_on_these_carriers :: proc(
	carriers: []^Unit,
	air_units: []^Unit,
	territory_units_are_in: ^Territory,
) -> [dynamic]^Unit {
	air_that_can_land_on_them: [dynamic]^Unit
	for carrier in carriers {
		carrier_capacity := air_movement_validator_carrier_capacity_unit(
			carrier,
			territory_units_are_in,
		)
		for air in air_units {
			already := false
			for existing in air_that_can_land_on_them {
				if existing == air {
					already = true
					break
				}
			}
			if already {
				continue
			}
			air_cost := air_movement_validator_carrier_cost_unit(air)
			if carrier_capacity >= air_cost {
				carrier_capacity -= air_cost
				append(&air_that_can_land_on_them, air)
			}
		}
	}
	return air_that_can_land_on_them
}

// Java: private static int getNeutralCharge(GameState data, Route route) {
//   return getNeutralCharge(data, MoveDelegate.getEmptyNeutral(route).size());
// }
air_movement_validator_get_neutral_charge_route :: proc(
	data:  ^Game_State,
	route: ^Route,
) -> i32 {
	empty := move_delegate_get_empty_neutral(route)
	defer delete(empty)
	return air_movement_validator_get_neutral_charge(data, i32(len(empty)))
}

// Java synthetic: lambda$getLowestToHighestDistance$1
//   (territoryWeMeasureDistanceFrom, condition, t1, t2) -> int
// This is the body of the comparator returned by getLowestToHighestDistance.
// It is also reachable through the closure-capture trampoline
// `air_movement_validator_get_lowest_to_highest_distance_less` defined
// near the top of this file; this proc preserves the bare lambda shape
// (returning Java's int comparator code: -1, 0, or 1) for any direct
// invocation that mirrors the Java bytecode.
air_movement_validator_lambda_get_lowest_to_highest_distance_1 :: proc(
	territory_we_measure_distance_from: ^Territory,
	condition:                          proc(rawptr, ^Territory) -> bool,
	condition_ctx:                      rawptr,
	t1:                                 ^Territory,
	t2:                                 ^Territory,
) -> i32 {
	if t1 == t2 {
		return 0
	}
	gd := game_data_component_get_data(&t1.game_data_component)
	gm := game_data_get_map(gd)
	d1 := game_map_get_distance_predicate(
		gm,
		territory_we_measure_distance_from,
		t1,
		condition,
		condition_ctx,
	)
	d2 := game_map_get_distance_predicate(
		gm,
		territory_we_measure_distance_from,
		t2,
		condition,
		condition_ctx,
	)
	if d1 == d2 {
		return 0
	}
	if d1 < 0 {
		return 1
	}
	if d2 < 0 {
		return -1
	}
	if d1 < d2 {
		return -1
	}
	return 1
}

// Java: private static BigDecimal maxMovementLeftForAllOwnedCarriers(
//     final GamePlayer player, final GameState data) {
//   BigDecimal max = BigDecimal.ZERO;
//   final Predicate<Unit> ownedCarrier =
//       Matches.unitIsCarrier().and(Matches.unitIsOwnedBy(player));
//   for (final Territory t : data.getMap().getTerritories()) {
//     for (final Unit carrier : t.getMatches(ownedCarrier)) {
//       max = max.max(carrier.getMovementLeft());
//     }
//   }
//   return max;
// }
air_movement_validator_max_movement_left_for_all_owned_carriers :: proc(
	player: ^Game_Player,
	data:   ^Game_State,
) -> f64 {
	max_val: f64 = 0.0
	carrier_pred, carrier_ctx := matches_unit_is_carrier()
	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	territories := game_map_get_territories(game_state_get_map(data))
	defer delete(territories)
	for t in territories {
		for unit in t.unit_collection.units {
			if !carrier_pred(carrier_ctx, unit) {
				continue
			}
			if !owned_pred(owned_ctx, unit) {
				continue
			}
			ml := unit_get_movement_left(unit)
			if ml > max_val {
				max_val = ml
			}
		}
	}
	return max_val
}

// Java: private static List<Unit> getAirUnitsToValidate(
//     Collection<Unit> units, Route route, GamePlayer player)
//
// Combines the player's owned non-kamikaze air units already at the
// route's end with the moving owned non-kamikaze air units. If we are
// in a combat move and there are enemy units at the destination,
// suicide-on-attack air units are dropped. The list is then sorted
// by ascending movement-left-when-not-yet-moved (lowest first).
air_movement_validator_get_air_units_to_validate :: proc(
	units:  []^Unit,
	route:  ^Route,
	player: ^Game_Player,
) -> [dynamic]^Unit {
	air_pred, air_ctx := matches_unit_is_air()
	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	kami_pred, kami_ctx := matches_unit_is_kamikaze()

	owned_air: [dynamic]^Unit
	// First: route.getEnd().getUnits() filtered by ownedAirMatch
	end_t := route_get_end(route)
	for u in end_t.unit_collection.units {
		if !air_pred(air_ctx, u) {
			continue
		}
		if !owned_pred(owned_ctx, u) {
			continue
		}
		if kami_pred(kami_ctx, u) {
			continue
		}
		append(&owned_air, u)
	}
	// Second: units (the moving units) filtered by the same predicate
	for u in units {
		if !air_pred(air_ctx, u) {
			continue
		}
		if !owned_pred(owned_ctx, u) {
			continue
		}
		if kami_pred(kami_ctx, u) {
			continue
		}
		append(&owned_air, u)
	}

	// If combat move and there are any enemy units at the destination,
	// remove suicide-on-attack air units.
	enemy_pred, enemy_ctx := matches_enemy_unit(player)
	any_enemy_at_end := false
	for u in end_t.unit_collection.units {
		if enemy_pred(enemy_ctx, u) {
			any_enemy_at_end = true
			break
		}
	}
	if any_enemy_at_end &&
	   game_step_properties_helper_is_combat_move(game_player_get_data(player)) {
		suicide_pred, suicide_ctx := matches_unit_is_suicide_on_attack()
		filtered: [dynamic]^Unit
		for u in owned_air {
			if !suicide_pred(suicide_ctx, u) {
				append(&filtered, u)
			}
		}
		delete(owned_air)
		owned_air = filtered
	}

	// Sort by getLowestToHighestMovementComparatorIncludingUnitsNotYetMoved(route).
	// The comparator captures `route`, so we drive an in-place insertion
	// sort directly with the captured key (no closures in Odin).
	n := len(owned_air)
	for i := 1; i < n; i += 1 {
		j := i
		for j > 0 {
			a := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
				owned_air[j],
				route,
			)
			b := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
				owned_air[j - 1],
				route,
			)
			if a < b {
				owned_air[j], owned_air[j - 1] = owned_air[j - 1], owned_air[j]
				j -= 1
			} else {
				break
			}
		}
	}
	return owned_air
}

// Java: public static boolean canLand(
//     Collection<Unit> airUnits, Territory territory,
//     GamePlayer player, GameData data)
//
// Returns true if all the air units can land in the given territory.
// Throws IllegalArgumentException if the input is empty or contains a
// non-air unit; mirrored as `panic` in the Odin port.
air_movement_validator_can_land :: proc(
	air_units: []^Unit,
	territory: ^Territory,
	player:    ^Game_Player,
	data:      ^Game_Data,
) -> bool {
	if len(air_units) == 0 {
		panic("can only test if air will land")
	}
	air_pred, air_ctx := matches_unit_is_air()
	for u in air_units {
		if !air_pred(air_ctx, u) {
			panic("can only test if air will land")
		}
	}
	if !territory_is_water(territory) &&
	   battle_tracker_was_conquered(
		   abstract_move_delegate_get_battle_tracker(data),
		   territory,
	   ) {
		return false
	}
	if territory_is_water(territory) {
		// All must be able to land on a carrier.
		carrier_pred, carrier_ctx := matches_unit_can_land_on_carrier()
		for u in air_units {
			if !carrier_pred(carrier_ctx, u) {
				return false
			}
		}
		// Build dedup set of friendly + airUnits to mirror Java HashSet.
		friendly_set: map[^Unit]struct{}
		defer delete(friendly_set)
		friendly_from_terr := air_movement_validator_get_friendly(territory, player, data)
		defer delete(friendly_from_terr)
		for u in friendly_from_terr {
			friendly_set[u] = {}
		}
		for u in air_units {
			friendly_set[u] = {}
		}
		friendly: [dynamic]^Unit
		defer delete(friendly)
		for u, _ in friendly_set {
			append(&friendly, u)
		}
		capacity := air_movement_validator_carrier_capacity(friendly[:], territory)
		cost := air_movement_validator_carrier_cost(friendly[:])
		return capacity >= cost
	}
	return relationship_tracker_can_land_air_units_on_owned_land(
		game_data_get_relationship_tracker(data),
		player,
		territory_get_owner(territory),
	)
}

// Java: private static IntegerMap<Territory> populateStaticAlliedAndBuildingCarrierCapacity(
//     List<Territory> landingSpots,
//     Map<Unit, Collection<Unit>> movedCarriersAndTheirFighters,
//     GamePlayer player, GameData data)
//
// For each landing spot, accumulate (a) the carrier capacity of any
// carriers we are about to build at an adjacent factory (when the
// relevant property is on and the landing spot is water), and (b) the
// carrier capacity of allied (not-owned) carriers already in that
// territory, excluding any carrier we have already moved.
air_movement_validator_populate_static_allied_and_building_carrier_capacity :: proc(
	landing_spots:                       []^Territory,
	moved_carriers_and_their_fighters:   map[^Unit][dynamic]^Unit,
	player:                              ^Game_Player,
	data:                                ^Game_Data,
) -> ^Integer_Map {
	starting_space := integer_map_new()

	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	allied_pred, allied_ctx := matches_is_unit_allied(player)
	carrier_pred, carrier_ctx := matches_unit_is_carrier()
	water_pred, water_ctx := matches_territory_is_water()
	factory_neighbor_pred, factory_neighbor_ctx :=
		matches_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor(player)

	props := game_state_get_properties(cast(^Game_State)data)
	land_air_on_new_carriers :=
		properties_get_lhtr_carrier_production_rules(props) ||
		properties_get_land_existing_fighters_on_new_carriers(props)

	// Build carriersInProductionQueue: flat-mapped list of carrier units
	// across the unit collections of every player whose turn is combined
	// with `player`.
	carriers_in_production_queue: [dynamic]^Unit
	defer delete(carriers_in_production_queue)
	combined := game_step_properties_helper_get_combined_turns(data, player)
	defer delete(combined)
	for gp, _ in combined {
		uc := game_player_get_unit_collection(gp)
		matched := air_movement_validator_lambda_populate_static_allied_and_building_carrier_capacity_0(
			uc,
		)
		for u in matched {
			append(&carriers_in_production_queue, u)
		}
		delete(matched)
	}

	for t in landing_spots {
		if land_air_on_new_carriers &&
		   len(carriers_in_production_queue) > 0 &&
		   water_pred(water_ctx, t) &&
		   factory_neighbor_pred(factory_neighbor_ctx, t) {
			produced_carrier_capacity := air_movement_validator_carrier_capacity(
				carriers_in_production_queue[:],
				t,
			)
			integer_map_add(starting_space, rawptr(t), produced_carrier_capacity)
			clear(&carriers_in_production_queue)
		}
		// allied carriers already in this territory, excluding those we've
		// already moved (= keys of movedCarriersAndTheirFighters).
		allied_carriers: [dynamic]^Unit
		defer delete(allied_carriers)
		for u in t.unit_collection.units {
			if owned_pred(owned_ctx, u) {
				continue
			}
			if !allied_pred(allied_ctx, u) {
				continue
			}
			if !carrier_pred(carrier_ctx, u) {
				continue
			}
			if _, already_moved := moved_carriers_and_their_fighters[u]; already_moved {
				continue
			}
			append(&allied_carriers, u)
		}
		allied_carrier_capacity := air_movement_validator_carrier_capacity(
			allied_carriers[:],
			t,
		)
		integer_map_add(starting_space, rawptr(t), allied_carrier_capacity)
	}
	return starting_space
}

// Java: private static BigDecimal getMovementLeftForAirUnitNotMovedYet(
//     final Unit airBeingValidated, final Route route) {
//   return route.getEnd().getUnits().contains(airBeingValidated)
//       // they are not being moved, they are already at the end
//       ? airBeingValidated.getMovementLeft()
//       // they are being moved (they are still at the start location)
//       : airBeingValidated.getMovementLeft()
//             .subtract(route.getMovementCost(airBeingValidated));
// }
// BigDecimal → f64 per llm-instructions.md.
air_movement_validator_get_movement_left_for_air_unit_not_moved_yet :: proc(
	air_being_validated: ^Unit,
	route:               ^Route,
) -> f64 {
	end := route_get_end(route)
	if unit_collection_contains(territory_get_unit_collection(end), air_being_validated) {
		return unit_get_movement_left(air_being_validated)
	}
	return unit_get_movement_left(air_being_validated) -
		route_get_movement_cost(route, air_being_validated)
}

// File-scope holder bridging the ctx-form Predicate<Territory> produced by
// `matches_air_can_fly_over` into the bare `proc(^Territory) -> bool`
// signature consumed by `game_map_get_route_for_unit`. Mirrors the holder
// pattern used by `pro_non_combat_move_ai.odin` and
// `pro_territory_manager.odin`. The holder is set immediately before each
// route lookup and the lookups are synchronous within
// `air_movement_validator_can_air_reach_this_spot`.
@(private = "file")
air_movement_validator_active_can_fly_over: proc(rawptr, ^Territory) -> bool

@(private = "file")
air_movement_validator_active_can_fly_over_ctx: rawptr

@(private = "file")
air_movement_validator_can_fly_over_trampoline :: proc(t: ^Territory) -> bool {
	return air_movement_validator_active_can_fly_over(
		air_movement_validator_active_can_fly_over_ctx,
		t,
	)
}

// Java: private static boolean canAirReachThisSpot(
//     final Unit unit, final GameState data, final GamePlayer player,
//     final Territory currentSpot, final BigDecimal movementLeft,
//     final Territory landingSpot, final boolean areNeutralsPassableByAir) {
//   final Optional<Route> optionalRoute = data.getMap().getRouteForUnit(
//       currentSpot, landingSpot,
//       Matches.airCanFlyOver(player, areNeutralsPassableByAir),
//       unit, player);
//   return optionalRoute.isPresent()
//       && optionalRoute.get().getMovementCost(unit).compareTo(movementLeft) <= 0
//       && (!areNeutralsPassableByAir
//           || getNeutralCharge(data, optionalRoute.get())
//               <= player.getResources().getQuantity(Constants.PUS));
// }
// BigDecimal → f64. Constants.PUS == "PUs".
air_movement_validator_can_air_reach_this_spot :: proc(
	unit:                          ^Unit,
	data:                          ^Game_State,
	player:                        ^Game_Player,
	current_spot:                  ^Territory,
	movement_left:                 f64,
	landing_spot:                  ^Territory,
	are_neutrals_passable_by_air:  bool,
) -> bool {
	fly_p, fly_c := matches_air_can_fly_over(player, are_neutrals_passable_by_air)
	air_movement_validator_active_can_fly_over = fly_p
	air_movement_validator_active_can_fly_over_ctx = fly_c
	optional_route := game_map_get_route_for_unit(
		game_state_get_map(data),
		current_spot,
		landing_spot,
		air_movement_validator_can_fly_over_trampoline,
		unit,
		player,
	)
	if optional_route == nil {
		return false
	}
	if route_get_movement_cost(optional_route, unit) > movement_left {
		return false
	}
	if !are_neutrals_passable_by_air {
		return true
	}
	pus := resource_list_get_resource_or_throw(
		game_state_get_resource_list(data),
		"PUs",
	)
	return air_movement_validator_get_neutral_charge_route(data, optional_route) <=
		resource_collection_get_quantity(game_player_get_resources(player), pus)
}

// Java: private static boolean canFindLand(
//     final GameData data, final Unit unit, final Territory current,
//     final BigDecimal movementLeft) { ... }
//
// 4-arg overload. Returns true if `unit` can reach any allied
// non-conquered land territory from `current` within `movementLeft`
// movement, considering neutral fly-over. BigDecimal → f64.
air_movement_validator_can_find_land_4 :: proc(
	data:          ^Game_Data,
	unit:          ^Unit,
	current:       ^Territory,
	movement_left: f64,
) -> bool {
	if movement_left < 0 {
		return false
	}
	gs := &data.game_state
	are_neutrals_passable := air_movement_validator_are_neutrals_passable_by_air(gs)
	player := unit_get_owner(unit)
	fly_p, fly_c := matches_air_can_fly_over(player, are_neutrals_passable)
	neighbors := game_map_get_neighbors_by_movement_cost(
		game_state_get_map(gs),
		current,
		movement_left,
		fly_p,
		fly_c,
	)
	defer delete(neighbors)
	land_p, land_c := matches_air_can_land_on_this_allied_non_conquered_land_territory(player)
	for landing_spot, _ in neighbors {
		if !land_p(land_c, landing_spot) {
			continue
		}
		if air_movement_validator_can_air_reach_this_spot(
			unit,
			gs,
			player,
			current,
			movement_left,
			landing_spot,
			are_neutrals_passable,
		) {
			return true
		}
	}
	return false
}

// Java: private static Map<Unit, BigDecimal> getMovementLeftForValidatingAir(
//     final Collection<Unit> airBeingValidated, final GamePlayer player,
//     final Route route) { ... }
//
// Returns a LinkedHashMap (insertion-ordered) mapping each input unit
// to its movement-left-for-validation value. Owned units use
// getMovementLeftForAirUnitNotMovedYet; everything else gets 0.
// Odin's builtin map preserves insertion order, matching LinkedHashMap.
// BigDecimal → f64.
air_movement_validator_get_movement_left_for_validating_air :: proc(
	air_being_validated: []^Unit,
	player:              ^Game_Player,
	route:               ^Route,
) -> map[^Unit]f64 {
	result := make(map[^Unit]f64)
	owned_p, owned_c := matches_unit_is_owned_by(player)
	for unit in air_being_validated {
		movement_left: f64 = 0.0
		if owned_p(owned_c, unit) {
			movement_left = air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
				unit,
				route,
			)
		}
		result[unit] = movement_left
	}
	return result
}

// Java synthetic: lambda$getLowestToHighestMovementComparatorIncludingUnitsNotYetMoved$2
//   u -> getMovementLeftForAirUnitNotMovedYet(u, route)
// The key-extractor passed to Comparator.comparing(...). The captured
// `route` is supplied as an explicit parameter here (as the bytecode
// would). BigDecimal → f64.
air_movement_validator_lambda_get_lowest_to_highest_movement_comparator_including_units_not_yet_moved_2 :: proc(
	route: ^Route,
	u:     ^Unit,
) -> f64 {
	return air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(u, route)
}

// Java: private static BigDecimal maxMovementLeftForTheseAirUnitsBeingValidated(
//     final Collection<Unit> airUnits, final Route route, final GamePlayer player) { ... }
//
// Among player-owned units in `air_units`, returns the maximum value
// of getMovementLeftForAirUnitNotMovedYet. Allied units contribute
// nothing (Java comment: "allied units can't move...."). Returns 0
// when no owned units are present. BigDecimal → f64.
air_movement_validator_max_movement_left_for_these_air_units_being_validated :: proc(
	air_units: []^Unit,
	route:     ^Route,
	player:    ^Game_Player,
) -> f64 {
	max_val: f64 = 0.0
	owned_p, owned_c := matches_unit_is_owned_by(player)
	for u in air_units {
		if !owned_p(owned_c, u) {
			continue
		}
		movement_left := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
			u,
			route,
		)
		if movement_left > max_val {
			max_val = movement_left
		}
	}
	return max_val
}

// Java: public static final String NOT_ALL_AIR_UNITS_CAN_LAND
//     = "Not all air units can land";
// Static field on AirMovementValidator. Used as the warning string
// passed to MoveValidationResult.addDisallowedUnit by both
// validateAirCaughtByMovingCarriersAndOwnedAndAlliedAir and
// getAirThatMustLandOnCarriers.
NOT_ALL_AIR_UNITS_CAN_LAND :: "Not all air units can land"

// Java: private static boolean canFindLand(
//     final GameData data, final Unit unit, final Route route) {
//   final Territory routeEnd = route.getEnd();
//   final BigDecimal movementLeft = getMovementLeftForAirUnitNotMovedYet(unit, route);
//   return canFindLand(data, unit, routeEnd, movementLeft);
// }
//
// Odin can't overload, so the 3-arg Route variant is renamed
// `..._can_find_land_3_route` (sibling of `..._can_find_land_3` for
// the Territory variant and `..._can_find_land_4` for the
// 4-arg BigDecimal overload). BigDecimal → f64.
air_movement_validator_can_find_land_3_route :: proc(
	data:  ^Game_Data,
	unit:  ^Unit,
	route: ^Route,
) -> bool {
	route_end := route_get_end(route)
	movement_left := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
		unit,
		route,
	)
	return air_movement_validator_can_find_land_4(data, unit, route_end, movement_left)
}

// Java: private static boolean canFindLand(
//     final GameData data, final Unit unit, final Territory current) {
//   final BigDecimal movementLeft = unit.getMovementLeft();
//   return canFindLand(data, unit, current, movementLeft);
// }
//
// 3-arg Territory overload. Forwarded to by the closure-capture
// predicate `air_movement_validator_unit_can_find_land_predicate`
// already defined above. BigDecimal → f64.
air_movement_validator_can_find_land_3 :: proc(
	data:    ^Game_Data,
	unit:    ^Unit,
	current: ^Territory,
) -> bool {
	movement_left := unit_get_movement_left(unit)
	return air_movement_validator_can_find_land_4(data, unit, current, movement_left)
}

// File-scope trampoline pair bridging the ctx-form
// Predicate<Territory> produced by `matches_sea_can_move_over` into
// the bare `proc(^Territory) -> bool` accepted by
// `game_map_get_route_for_units`. Mirrors the
// `air_movement_validator_active_can_fly_over` pattern above. Set
// immediately before each route lookup; lookups are synchronous
// within the validate proc below.
@(private = "file")
air_movement_validator_active_sea_can_move_over: proc(rawptr, ^Territory) -> bool

@(private = "file")
air_movement_validator_active_sea_can_move_over_ctx: rawptr

@(private = "file")
air_movement_validator_sea_can_move_over_trampoline :: proc(t: ^Territory) -> bool {
	return air_movement_validator_active_sea_can_move_over(
		air_movement_validator_active_sea_can_move_over_ctx,
		t,
	)
}

// Java: private static void validateAirCaughtByMovingCarriersAndOwnedAndAlliedAir(
//     final MoveValidationResult result,
//     final List<Territory> landingSpots,
//     final Collection<Territory> potentialCarrierOrigins,
//     final Map<Unit, Collection<Unit>> movedCarriersAndTheirFighters,
//     final Collection<Unit> airThatMustLandOnCarriers,
//     final Collection<Unit> airNotToConsider,
//     final GamePlayer player,
//     final Route route,
//     final GameData data) { ... }
//
// Java mutates the `Collection` parameters
// (`potentialCarrierOrigins`, `airThatMustLandOnCarriers`,
// `airNotToConsider`, and the `movedCarriersAndTheirFighters` map)
// and the caller observes those mutations. Odin's [dynamic]^T is a
// header-by-value type, so we accept those four as `^[dynamic]^T` /
// `^map[..]..` to preserve the "modifies caller's collection"
// semantics. `landingSpots` is read-only here; pass [dynamic]^T.
air_movement_validator_validate_air_caught_by_moving_carriers_and_owned_and_allied_air :: proc(
	result:                            ^Move_Validation_Result,
	landing_spots:                     [dynamic]^Territory,
	potential_carrier_origins:         ^[dynamic]^Territory,
	moved_carriers_and_their_fighters: ^map[^Unit][dynamic]^Unit,
	air_that_must_land_on_carriers:    ^[dynamic]^Unit,
	air_not_to_consider:               ^[dynamic]^Unit,
	player:                            ^Game_Player,
	route:                             ^Route,
	data:                              ^Game_Data,
) {
	owned_p, owned_c := matches_unit_is_owned_by(player)
	carrier_p, carrier_c := matches_unit_is_carrier()
	air_p, air_c := matches_unit_is_air()
	can_land_carrier_p, can_land_carrier_c := matches_unit_can_land_on_carrier()
	allied_p, allied_c := matches_is_unit_allied(player)

	// ownedCarrierMatch:           owned AND carrier
	// ownedAirMatch:               owned AND air AND canLandOnCarrier
	// alliedNotOwnedAirMatch:      !owned AND allied AND air AND canLandOnCarrier
	// alliedNotOwnedCarrierMatch:  !owned AND allied AND carrier
	// — open-coded inline since Odin lacks predicate composition.

	route_end := route_get_end(route)
	gs := &data.game_state
	are_neutrals_passable_by_air := air_movement_validator_are_neutrals_passable_by_air(gs)
	landing_spots_with_carrier_capacity :=
		air_movement_validator_populate_static_allied_and_building_carrier_capacity(
			landing_spots[:],
			moved_carriers_and_their_fighters^,
			player,
			data,
		)
	movement_left_for_air_to_validate :=
		air_movement_validator_get_movement_left_for_validating_air(
			air_that_must_land_on_carriers^[:],
			player,
			route,
		)
	defer delete(movement_left_for_air_to_validate)

	for landing_spot in landing_spots {
		// since we are here, no point looking at this place twice
		for j := 0; j < len(potential_carrier_origins^); j += 1 {
			if potential_carrier_origins^[j] == landing_spot {
				ordered_remove(potential_carrier_origins, j)
				break
			}
		}

		air_can_reach: [dynamic]^Unit
		for air in air_that_must_land_on_carriers^ {
			ml := movement_left_for_air_to_validate[air]
			if air_movement_validator_can_air_reach_this_spot(
				air,
				gs,
				player,
				route_end,
				ml,
				landing_spot,
				are_neutrals_passable_by_air,
			) {
				append(&air_can_reach, air)
			}
		}
		if len(air_can_reach) == 0 {
			delete(air_can_reach)
			continue
		}

		// units in landing spot, minus moved carriers, minus
		// airNotToConsider, minus fighters travelling with already-moved
		// carriers.
		units_in_landing_spot: [dynamic]^Unit
		for u in territory_get_unit_collection(landing_spot).units {
			if _, mv := moved_carriers_and_their_fighters^[u]; mv {
				continue
			}
			skip := false
			for ant in air_not_to_consider^ {
				if ant == u {
					skip = true
					break
				}
			}
			if skip {
				continue
			}
			for _, ftrs in moved_carriers_and_their_fighters^ {
				found := false
				for f in ftrs {
					if f == u {
						found = true
						break
					}
				}
				if found {
					skip = true
					break
				}
			}
			if skip {
				continue
			}
			append(&units_in_landing_spot, u)
		}

		// ownedCarrierMatch
		owned_carriers_in_landing_spot: [dynamic]^Unit
		for u in units_in_landing_spot {
			if owned_p(owned_c, u) && carrier_p(carrier_c, u) {
				append(&owned_carriers_in_landing_spot, u)
			}
		}

		// owned air here, but exclude any air that can fly to allied
		// land. unitCanFindLand(data, landingSpot).negate()
		ucfl_p, ucfl_ctx := air_movement_validator_unit_can_find_land(
			data,
			landing_spot,
		)
		air_in_landing_spot: [dynamic]^Unit
		for u in units_in_landing_spot {
			if owned_p(owned_c, u) &&
			   air_p(air_c, u) &&
			   can_land_carrier_p(can_land_carrier_c, u) {
				if !ucfl_p(ucfl_ctx, u) {
					append(&air_in_landing_spot, u)
				}
			}
		}
		// add allied air (it can't fly away)
		for u in units_in_landing_spot {
			if !owned_p(owned_c, u) &&
			   allied_p(allied_c, u) &&
			   air_p(air_c, u) &&
			   can_land_carrier_p(can_land_carrier_c, u) {
				append(&air_in_landing_spot, u)
			}
		}

		landing_spot_capacity := integer_map_get_int(
			landing_spots_with_carrier_capacity,
			rawptr(landing_spot),
		)
		landing_spot_capacity += air_movement_validator_carrier_capacity(
			owned_carriers_in_landing_spot[:],
			landing_spot,
		)
		landing_spot_capacity -= air_movement_validator_carrier_cost(
			air_in_landing_spot[:],
		)

		// airIter
		ai := 0
		for ai < len(air_can_reach) {
			air := air_can_reach[ai]
			cost := air_movement_validator_carrier_cost_unit(air)
			if landing_spot_capacity >= cost {
				landing_spot_capacity -= cost
				for k := 0; k < len(air_that_must_land_on_carriers^); k += 1 {
					if air_that_must_land_on_carriers^[k] == air {
						ordered_remove(air_that_must_land_on_carriers, k)
						break
					}
				}
				ordered_remove(&air_can_reach, ai)
			} else {
				ai += 1
			}
		}
		if len(air_that_must_land_on_carriers^) == 0 {
			return
		}

		// now bring carriers here
		ci := 0
		for ci < len(potential_carrier_origins^) {
			carrier_spot := potential_carrier_origins^[ci]
			units_in_carrier_spot: [dynamic]^Unit
			for u in territory_get_unit_collection(carrier_spot).units {
				if _, mv := moved_carriers_and_their_fighters^[u]; mv {
					continue
				}
				skip := false
				for ant in air_not_to_consider^ {
					if ant == u {
						skip = true
						break
					}
				}
				if skip {
					continue
				}
				for _, ftrs in moved_carriers_and_their_fighters^ {
					found := false
					for f in ftrs {
						if f == u {
							found = true
							break
						}
					}
					if found {
						skip = true
						break
					}
				}
				if skip {
					continue
				}
				append(&units_in_carrier_spot, u)
			}

			owned_carriers_in_carrier_spot: [dynamic]^Unit
			for u in units_in_carrier_spot {
				if owned_p(owned_c, u) && carrier_p(carrier_c, u) {
					append(&owned_carriers_in_carrier_spot, u)
				}
			}
			if len(owned_carriers_in_carrier_spot) == 0 {
				ordered_remove(potential_carrier_origins, ci)
				continue
			}

			ucfl2_p, ucfl2_ctx := air_movement_validator_unit_can_find_land(
				data,
				carrier_spot,
			)
			owned_air_in_carrier_spot: [dynamic]^Unit
			for u in units_in_carrier_spot {
				if owned_p(owned_c, u) &&
				   air_p(air_c, u) &&
				   can_land_carrier_p(can_land_carrier_c, u) {
					if !ucfl2_p(ucfl2_ctx, u) {
						append(&owned_air_in_carrier_spot, u)
					}
				}
			}
			allied_not_owned_air_in_carrier_spot: [dynamic]^Unit
			for u in units_in_carrier_spot {
				if !owned_p(owned_c, u) &&
				   allied_p(allied_c, u) &&
				   air_p(air_c, u) &&
				   can_land_carrier_p(can_land_carrier_c, u) {
					append(&allied_not_owned_air_in_carrier_spot, u)
				}
			}

			must_move_with_map := move_validator_carrier_must_move_with(
				owned_carriers_in_carrier_spot,
				territory_get_unit_collection(carrier_spot).units,
				player,
			)

			carrier_spot_capacity := integer_map_get_int(
				landing_spots_with_carrier_capacity,
				rawptr(carrier_spot),
			)
			if !integer_map_contains_key(
				landing_spots_with_carrier_capacity,
				rawptr(carrier_spot),
			) {
				// allied carrier capacity for territory:
				// alliedNotOwnedCarrierMatch
				allied_not_owned_carriers: [dynamic]^Unit
				for u in territory_get_unit_collection(carrier_spot).units {
					if !owned_p(owned_c, u) &&
					   allied_p(allied_c, u) &&
					   carrier_p(carrier_c, u) {
						append(&allied_not_owned_carriers, u)
					}
				}
				carrier_spot_capacity = air_movement_validator_carrier_capacity(
					allied_not_owned_carriers[:],
					carrier_spot,
				)
				delete(allied_not_owned_carriers)
				integer_map_put(
					landing_spots_with_carrier_capacity,
					rawptr(carrier_spot),
					carrier_spot_capacity,
				)
			}

			if len(allied_not_owned_air_in_carrier_spot) > 0 ||
			   len(must_move_with_map) > 0 {
				if len(must_move_with_map) == 0 {
					carrier_spot_capacity -= air_movement_validator_carrier_cost(
						allied_not_owned_air_in_carrier_spot[:],
					)
					for u in allied_not_owned_air_in_carrier_spot {
						append(air_not_to_consider, u)
					}
					if carrier_spot_capacity > 0 {
						oi := 0
						for oi < len(owned_air_in_carrier_spot) {
							air := owned_air_in_carrier_spot[oi]
							cost := air_movement_validator_carrier_cost_unit(
								air,
							)
							if carrier_spot_capacity >= cost {
								carrier_spot_capacity -= cost
								append(air_not_to_consider, air)
								ordered_remove(&owned_air_in_carrier_spot, oi)
							} else {
								oi += 1
							}
						}
					}
					integer_map_put(
						landing_spots_with_carrier_capacity,
						rawptr(carrier_spot),
						carrier_spot_capacity,
					)
				} else {
					// remove fighters that already moved out from
					// must_move_with_map values
					for k, _ in must_move_with_map {
						old_list := must_move_with_map[k]
						new_list: [dynamic]^Unit
						for u in old_list {
							already_moved := false
							for _, ftrs in moved_carriers_and_their_fighters^ {
								for f in ftrs {
									if f == u {
										already_moved = true
										break
									}
								}
								if already_moved {
									break
								}
							}
							if !already_moved {
								append(&new_list, u)
							}
						}
						delete(old_list)
						must_move_with_map[k] = new_list
					}
					// alliedNotOwnedAirInCarrierSpot.removeAll(airMovingWith)
					for _, air_moving_with in must_move_with_map {
						for u in air_moving_with {
							k := 0
							for k < len(allied_not_owned_air_in_carrier_spot) {
								if allied_not_owned_air_in_carrier_spot[k] == u {
									ordered_remove(
										&allied_not_owned_air_in_carrier_spot,
										k,
									)
								} else {
									k += 1
								}
							}
						}
					}
					carrier_spot_capacity -= air_movement_validator_carrier_cost(
						allied_not_owned_air_in_carrier_spot[:],
					)
					for u in allied_not_owned_air_in_carrier_spot {
						append(air_not_to_consider, u)
					}
					integer_map_put(
						landing_spots_with_carrier_capacity,
						rawptr(carrier_spot),
						carrier_spot_capacity,
					)
				}
			}

			air_movement_validator_active_sea_can_move_over,
			air_movement_validator_active_sea_can_move_over_ctx =
				matches_sea_can_move_over(player)
			optional_to_landing_spot := game_map_get_route_for_units(
				game_state_get_map(gs),
				carrier_spot,
				landing_spot,
				air_movement_validator_sea_can_move_over_trampoline,
				owned_carriers_in_carrier_spot,
				player,
			)
			if optional_to_landing_spot == nil {
				ci += 1
				continue
			}
			mv_route_p, mv_route_c := matches_unit_has_enough_movement_for_route(
				optional_to_landing_spot,
			)
			carriers_that_can_reach: [dynamic]^Unit
			for u in owned_carriers_in_carrier_spot {
				if mv_route_p(mv_route_c, u) {
					append(&carriers_that_can_reach, u)
				}
			}
			if len(carriers_that_can_reach) == 0 {
				ci += 1
				continue
			}
			carriers_that_cant_reach: [dynamic]^Unit
			for u in owned_carriers_in_carrier_spot {
				in_can_reach := false
				for c2 in carriers_that_can_reach {
					if c2 == u {
						in_can_reach = true
						break
					}
				}
				if !in_can_reach {
					append(&carriers_that_cant_reach, u)
				}
			}
			all_carriers: [dynamic]^Unit
			for u in carriers_that_cant_reach {
				append(&all_carriers, u)
			}
			for u in carriers_that_can_reach {
				append(&all_carriers, u)
			}

			carriers_to_move := make(map[^Unit][dynamic]^Unit)
			carrier_full: [dynamic]^Unit
			for carrier in all_carriers {
				air_moving_with: [dynamic]^Unit
				if allied_moving_with, ok := must_move_with_map[carrier]; ok {
					for u in allied_moving_with {
						append(&air_moving_with, u)
					}
				}
				cap := air_movement_validator_carrier_capacity_unit(
					carrier,
					carrier_spot,
				)
				cap -= air_movement_validator_carrier_cost(air_moving_with[:])
				oi := 0
				for oi < len(owned_air_in_carrier_spot) {
					air := owned_air_in_carrier_spot[oi]
					cost := air_movement_validator_carrier_cost_unit(air)
					if cap >= cost {
						cap -= cost
						append(&air_moving_with, air)
						ordered_remove(&owned_air_in_carrier_spot, oi)
					} else {
						oi += 1
					}
				}
				carriers_to_move[carrier] = air_moving_with
				if cap <= 0 {
					append(&carrier_full, carrier)
				}
			}

			// if carrier_full contains all of all_carriers
			all_full := true
			for c2 in all_carriers {
				in_full := false
				for cf in carrier_full {
					if cf == c2 {
						in_full = true
						break
					}
				}
				if !in_full {
					all_full = false
					break
				}
			}
			if all_full {
				ordered_remove(potential_carrier_origins, ci)
				continue
			}
			cant_full := true
			for c2 in carriers_that_cant_reach {
				in_full := false
				for cf in carrier_full {
					if cf == c2 {
						in_full = true
						break
					}
				}
				if !in_full {
					cant_full = false
					break
				}
			}
			if cant_full {
				ordered_remove(potential_carrier_origins, ci)
				// no `continue` — Java falls through to "ok now lets
				// move them" after iter.remove().
			}

			// move them
			for carrier in carriers_that_can_reach {
				moved_carriers_and_their_fighters^[carrier] =
					carriers_to_move[carrier]
				landing_spot_capacity +=
					air_movement_validator_carrier_capacity_unit(
						carrier,
						carrier_spot,
					)
				landing_spot_capacity -= air_movement_validator_carrier_cost(
					carriers_to_move[carrier][:],
				)
			}

			// reachIter
			ri := 0
			for ri < len(air_can_reach) {
				air := air_can_reach[ri]
				cost := air_movement_validator_carrier_cost_unit(air)
				if landing_spot_capacity >= cost {
					landing_spot_capacity -= cost
					for k := 0; k < len(air_that_must_land_on_carriers^); k += 1 {
						if air_that_must_land_on_carriers^[k] == air {
							ordered_remove(air_that_must_land_on_carriers, k)
							break
						}
					}
					ordered_remove(&air_can_reach, ri)
				} else {
					ri += 1
				}
			}
			if len(air_that_must_land_on_carriers^) == 0 {
				return
			}

			if !cant_full {
				ci += 1
			}
			// if cant_full: we already removed at ci above; do not advance.
		}
	}

	// anyone left over cannot land
	for air in air_that_must_land_on_carriers^ {
		move_validation_result_add_disallowed_unit(
			result,
			NOT_ALL_AIR_UNITS_CAN_LAND,
			air,
		)
	}
}

// Java: private static Collection<Unit> getAirThatMustLandOnCarriers(
//     final GameData data,
//     final Collection<Unit> ownedAir,
//     final Route route,
//     final MoveValidationResult result) { ... }
//
// Iterates the supplied owned air units, partitioning them into those
// that can find land along the supplied route and those that cannot.
// Units that cannot find land but can land on a carrier are returned;
// units that cannot find land and cannot land on a carrier are
// recorded as disallowed via the supplied MoveValidationResult.
air_movement_validator_get_air_that_must_land_on_carriers :: proc(
	data:      ^Game_Data,
	owned_air: []^Unit,
	route:     ^Route,
	result:    ^Move_Validation_Result,
) -> [dynamic]^Unit {
	air_that_must_land_on_carriers := make([dynamic]^Unit, 0)
	can_land_on_carriers, can_land_on_carriers_ctx := matches_unit_can_land_on_carrier()
	for unit in owned_air {
		if !air_movement_validator_can_find_land_3_route(data, unit, route) {
			if can_land_on_carriers(can_land_on_carriers_ctx, unit) {
				append(&air_that_must_land_on_carriers, unit)
			} else {
				// not everything can land on a carrier (i.e. bombers)
				move_validation_result_add_disallowed_unit(
					result,
					NOT_ALL_AIR_UNITS_CAN_LAND,
					unit,
				)
			}
		}
	}
	return air_that_must_land_on_carriers
}

// Java: synthetic lambda body for `unitCanFindLand`:
//   private static Predicate<Unit> unitCanFindLand(GameData data, Territory current) {
//     return u -> canFindLand(data, u, current);   // lambda$unitCanFindLand$3
//   }
//
// The captured-variable form has signature
// `(GameData, Territory, Unit) -> boolean`, where the first two
// arguments are the lambda's captured state and the last is the
// predicate input. The body forwards to the 3-arg Territory overload
// of canFindLand.
air_movement_validator_lambda_unit_can_find_land_3 :: proc(
	data:    ^Game_Data,
	current: ^Territory,
	u:       ^Unit,
) -> bool {
	return air_movement_validator_can_find_land_3(data, u, current)
}

// Java: static MoveValidationResult validateAirCanLand(
//     final Collection<Unit> units, final Route route,
//     final GamePlayer player, final MoveValidationResult result) { ... }
//
// Verifies every owned air unit ending the route has somewhere to
// land — friendly land at the destination, carriers already there or
// moving with us, or carriers reachable from nearby sea territories.
// Disallowed units are recorded on the supplied
// MoveValidationResult, which is mutated and returned (Java returns
// the same instance it was given).
air_movement_validator_validate_air_can_land :: proc(
	units:  []^Unit,
	route:  ^Route,
	player: ^Game_Player,
	result: ^Move_Validation_Result,
) -> ^Move_Validation_Result {
	data := game_player_get_data(player)
	gs := &data.game_state

	// First check if we even need to check (Java short-circuit cascade).
	if air_movement_validator_get_edit_mode(gs) {
		return result
	}
	any_air := false
	{
		air_p, air_c := matches_unit_is_air()
		for u in units {
			if air_p(air_c, u) {
				any_air = true
				break
			}
		}
	}
	if !any_air {
		return result
	}
	if route_has_no_steps(route) {
		return result
	}
	{
		can_land_land_p, can_land_land_c :=
			matches_air_can_land_on_this_allied_non_conquered_land_territory(player)
		if can_land_land_p(can_land_land_c, route_get_end(route)) {
			return result
		}
	}
	if properties_get_kamikaze_airplanes(game_data_get_properties(data)) {
		return result
	}

	// Find which aircraft cannot find friendly land to land on.
	air_to_validate := air_movement_validator_get_air_units_to_validate(
		units,
		route,
		player,
	)
	defer delete(air_to_validate)
	owned_air_that_must_land_on_carriers :=
		air_movement_validator_get_air_that_must_land_on_carriers(
			data,
			air_to_validate[:],
			route,
			result,
		)
	defer delete(owned_air_that_must_land_on_carriers)
	if len(owned_air_that_must_land_on_carriers) == 0 {
		return result
	}

	route_end := route_get_end(route)
	route_start := route_get_start(route)

	// airAlliedNotOwned = !owned AND allied AND air AND canLandOnCarrier.
	owned_p, owned_c := matches_unit_is_owned_by(player)
	allied_p, allied_c := matches_is_unit_allied(player)
	air_p, air_c := matches_unit_is_air()
	can_land_carrier_p, can_land_carrier_c := matches_unit_can_land_on_carrier()

	air_must_land_set: [dynamic]^Unit
	for u in route_end.unit_collection.units {
		if !owned_p(owned_c, u) &&
		   allied_p(allied_c, u) &&
		   air_p(air_c, u) &&
		   can_land_carrier_p(can_land_carrier_c, u) {
			already := false
			for x in air_must_land_set {
				if x == u {
					already = true
					break
				}
			}
			if !already {
				append(&air_must_land_set, u)
			}
		}
	}
	for u in units {
		if !owned_p(owned_c, u) &&
		   allied_p(allied_c, u) &&
		   air_p(air_c, u) &&
		   can_land_carrier_p(can_land_carrier_c, u) {
			already := false
			for x in air_must_land_set {
				if x == u {
					already = true
					break
				}
			}
			if !already {
				append(&air_must_land_set, u)
			}
		}
	}

	// movingCarriersAtStartLocationBeingMoved
	carrier_p, carrier_c := matches_unit_is_carrier()
	moving_carriers_at_start: [dynamic]^Unit
	for u in units {
		if carrier_p(carrier_c, u) {
			append(&moving_carriers_at_start, u)
		}
	}
	if len(moving_carriers_at_start) > 0 {
		// MoveValidator.carrierMustMoveWith(units, routeStart, player)
		units_dyn: [dynamic]^Unit
		for u in units {
			append(&units_dyn, u)
		}
		carrier_to_allied_cargo := move_validator_carrier_must_move_with_units_territory(
			units_dyn,
			route_start,
			player,
		)
		for _, allied_air_on_carrier in carrier_to_allied_cargo {
			for u in allied_air_on_carrier {
				already := false
				for x in air_must_land_set {
					if x == u {
						already = true
						break
					}
				}
				if !already {
					append(&air_must_land_set, u)
				}
			}
		}
		for k, v in carrier_to_allied_cargo {
			_ = k
			delete(v)
		}
		delete(carrier_to_allied_cargo)
		delete(units_dyn)
	}
	// add owned air last (lowest movement validated first)
	for u in owned_air_that_must_land_on_carriers {
		already := false
		for x in air_must_land_set {
			if x == u {
				already = true
				break
			}
		}
		if !already {
			append(&air_must_land_set, u)
		}
	}

	// sort by getLowestToHighestMovementComparatorIncludingUnitsNotYetMoved(route).
	{
		n := len(air_must_land_set)
		for i := 1; i < n; i += 1 {
			j := i
			for j > 0 {
				a := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
					air_must_land_set[j],
					route,
				)
				b := air_movement_validator_get_movement_left_for_air_unit_not_moved_yet(
					air_must_land_set[j - 1],
					route,
				)
				if a < b {
					air_must_land_set[j], air_must_land_set[j - 1] =
						air_must_land_set[j - 1], air_must_land_set[j]
					j -= 1
				} else {
					break
				}
			}
		}
	}

	// carriersAtEnd: friendly carriers at routeEnd + moving carriers we brought.
	carriers_at_end: [dynamic]^Unit
	{
		friendly_at_end := air_movement_validator_get_friendly(route_end, player, data)
		defer delete(friendly_at_end)
		for u in friendly_at_end {
			if carrier_p(carrier_c, u) {
				append(&carriers_at_end, u)
			}
		}
	}
	for u in moving_carriers_at_start {
		append(&carriers_at_end, u)
	}

	moved_carriers_and_their_fighters: map[^Unit][dynamic]^Unit
	for carrier in carriers_at_end {
		moved_carriers_and_their_fighters[carrier] = make([dynamic]^Unit)
	}

	air_not_to_consider: [dynamic]^Unit
	for u in air_must_land_set {
		append(&air_not_to_consider, u)
	}

	// removeAll(whatAirCanLandOnTheseCarriers(carriersAtEnd, ...))
	can_land_on_those := air_movement_validator_what_air_can_land_on_these_carriers(
		carriers_at_end[:],
		air_must_land_set[:],
		route_end,
	)
	{
		filtered: [dynamic]^Unit
		for u in air_must_land_set {
			drop := false
			for x in can_land_on_those {
				if x == u {
					drop = true
					break
				}
			}
			if !drop {
				append(&filtered, u)
			}
		}
		delete(air_must_land_set)
		air_must_land_set = filtered
	}
	delete(can_land_on_those)
	if len(air_must_land_set) == 0 {
		delete(air_not_to_consider)
		delete(moving_carriers_at_start)
		delete(carriers_at_end)
		for k, v in moved_carriers_and_their_fighters {
			_ = k
			delete(v)
		}
		delete(moved_carriers_and_their_fighters)
		delete(air_must_land_set)
		return result
	}

	// figure out the max remaining movement of our air and our carriers.
	max_movement_left_air := i32(
		air_movement_validator_max_movement_left_for_these_air_units_being_validated(
			air_must_land_set[:],
			route,
			player,
		),
	)
	max_movement_left_carriers := i32(
		air_movement_validator_max_movement_left_for_all_owned_carriers(player, gs),
	)

	// landingSpots = [routeEnd] ∪ neighbors(routeEnd, maxAirMv, airCanFlyOver),
	// then drop anything that isn't seaCanMoveOver, then sort by distance.
	landing_spots: [dynamic]^Territory
	append(&landing_spots, route_end)
	{
		fly_p, fly_c := matches_air_can_fly_over(
			player,
			air_movement_validator_are_neutrals_passable_by_air(gs),
		)
		neighbors := game_map_get_neighbors_distance_predicate(
			game_data_get_map(data),
			route_end,
			max_movement_left_air,
			fly_p,
			fly_c,
		)
		for t in neighbors {
			present := false
			for x in landing_spots {
				if x == t {
					present = true
					break
				}
			}
			if !present {
				append(&landing_spots, t)
			}
		}
		delete(neighbors)
	}
	sea_p, sea_c := matches_sea_can_move_over(player)
	{
		filtered: [dynamic]^Territory
		for t in landing_spots {
			if sea_p(sea_c, t) {
				append(&filtered, t)
			}
		}
		delete(landing_spots)
		landing_spots = filtered
	}
	{
		gm := game_data_get_map(data)
		n := len(landing_spots)
		for i := 1; i < n; i += 1 {
			j := i
			for j > 0 {
				t1 := landing_spots[j]
				t2 := landing_spots[j - 1]
				less := false
				if t1 != t2 {
					d1 := game_map_get_distance_predicate(
						gm,
						route_end,
						t1,
						sea_p,
						sea_c,
					)
					d2 := game_map_get_distance_predicate(
						gm,
						route_end,
						t2,
						sea_p,
						sea_c,
					)
					if d1 == d2 {
						less = false
					} else if d1 < 0 {
						less = false
					} else if d2 < 0 {
						less = true
					} else {
						less = d1 < d2
					}
				}
				if less {
					landing_spots[j], landing_spots[j - 1] =
						landing_spots[j - 1], landing_spots[j]
					j -= 1
				} else {
					break
				}
			}
		}
	}

	// potentialCarrierOrigins = LinkedHashSet(landingSpots) ∪
	//                            getNeighbors(landingSpots, maxOwnedCarrierMv, seaCanMoveOver)
	// minus routeEnd, minus territories that don't have an owned carrier.
	potential_carrier_origins: [dynamic]^Territory
	for t in landing_spots {
		present := false
		for x in potential_carrier_origins {
			if x == t {
				present = true
				break
			}
		}
		if !present {
			append(&potential_carrier_origins, t)
		}
	}
	{
		frontier: map[^Territory]struct{}
		for t in landing_spots {
			frontier[t] = {}
		}
		more := game_map_get_neighbors_set_distance_predicate(
			game_data_get_map(data),
			frontier,
			max_movement_left_carriers,
			sea_p,
			sea_c,
		)
		for t in more {
			present := false
			for x in potential_carrier_origins {
				if x == t {
					present = true
					break
				}
			}
			if !present {
				append(&potential_carrier_origins, t)
			}
		}
		delete(more)
		delete(frontier)
	}
	{
		filtered: [dynamic]^Territory
		for t in potential_carrier_origins {
			if t != route_end {
				append(&filtered, t)
			}
		}
		delete(potential_carrier_origins)
		potential_carrier_origins = filtered
	}
	{
		owned_carrier_p, owned_carrier_c := matches_territory_has_owned_carrier(player)
		filtered: [dynamic]^Territory
		for t in potential_carrier_origins {
			if owned_carrier_p(owned_carrier_c, t) {
				append(&filtered, t)
			}
		}
		delete(potential_carrier_origins)
		potential_carrier_origins = filtered
	}

	air_movement_validator_validate_air_caught_by_moving_carriers_and_owned_and_allied_air(
		result,
		landing_spots,
		&potential_carrier_origins,
		&moved_carriers_and_their_fighters,
		&air_must_land_set,
		&air_not_to_consider,
		player,
		route,
		data,
	)

	delete(landing_spots)
	delete(potential_carrier_origins)
	delete(moving_carriers_at_start)
	delete(carriers_at_end)
	delete(air_not_to_consider)
	delete(air_must_land_set)
	for k, v in moved_carriers_and_their_fighters {
		_ = k
		delete(v)
	}
	delete(moved_carriers_and_their_fighters)
	return result
}

