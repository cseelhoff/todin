package game

// Java owners covered by this file:
//   - games.strategy.triplea.UnitUtils

Unit_Utils :: struct {}

unit_utils_get_unit_types_from_unit_list :: proc(units: [dynamic]^Unit) -> map[^Unit_Type]struct{} {
	result: map[^Unit_Type]struct{}
	for unit in units {
		result[unit_get_type(unit)] = struct{}{}
	}
	return result
}

