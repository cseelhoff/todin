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

