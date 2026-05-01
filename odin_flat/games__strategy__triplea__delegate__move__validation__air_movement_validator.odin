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
