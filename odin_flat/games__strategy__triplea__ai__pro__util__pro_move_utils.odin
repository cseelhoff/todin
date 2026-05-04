package game

Pro_Move_Utils :: struct {}

// Synthetic lambda `e -> Stream.concat(Stream.of(e.getKey()), e.getValue().stream())`
// from `ProMoveUtils.calculateMoveRoutes`, applied as the `flatMap` over
// `attackMap.values().map(ProTerritory::getAmphibAttackMap).map(Map::entrySet).flatMap(Collection::stream)`.
// The `Map.Entry<Unit, Collection<Unit>>` is unpacked into separate key/value
// parameters; the result is a flat list of the entry's key followed by every
// element of its value collection.
pro_move_utils_lambda_calculate_move_routes_0 :: proc(key: ^Unit, value: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	append(&result, key)
	for u in value {
		append(&result, u)
	}
	return result
}

// Synthetic lambda `move -> move.getUnitsToSeaTransports().isEmpty()`
// from `ProMoveUtils.doMove`, used as the `allMatch` predicate that
// determines whether none of the queued moves carry sea-transport loads.
pro_move_utils_lambda__do_move__3 :: proc(move: ^Move_Description) -> bool {
	return len(move_description_get_units_to_sea_transports(move)) == 0
}

// Synthetic lambda `route -> moves.add(new MoveDescription(unitList, route))`
// from `ProMoveUtils.calculateBombardMoveRoutes`, applied as the
// `Optional<Route>::ifPresent` consumer when the naval route to the
// bombard-from territory exists. Captures the enclosing `moves` and
// `unitList` ArrayLists; appends a freshly-constructed MoveDescription
// (via the 2-arg Collection<Unit>+Route constructor) to `moves`.
pro_move_utils_lambda__calculate_bombard_move_routes__1 :: proc(
	moves: ^[dynamic]^Move_Description,
	unit_list: [dynamic]^Unit,
	route: ^Route,
) {
	append(moves, move_description_new_units_route(unit_list[:], route))
}

// Synthetic lambda `route -> moves.add(new MoveDescription(unitList, route))`
// from `ProMoveUtils.calculateBombingRoutes`, applied as the
// `Optional<Route>::ifPresent` consumer when the air route to the
// strategic-bombing target territory exists. Captures the enclosing
// `moves` and `unitList` ArrayLists; appends a freshly-constructed
// MoveDescription (via the 2-arg Collection<Unit>+Route constructor)
// to `moves`.
pro_move_utils_lambda__calculate_bombing_routes__2 :: proc(
	moves: ^[dynamic]^Move_Description,
	unit_list: [dynamic]^Unit,
	route: ^Route,
) {
	append(moves, move_description_new_units_route(unit_list[:], route))
}

