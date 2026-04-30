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

