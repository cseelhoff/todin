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

// public static @Nullable GamePlayer findPlayerWithMostUnits(final Iterable<Unit> units)
unit_utils_find_player_with_most_units :: proc(units: [dynamic]^Unit) -> ^Game_Player {
	player_unit_count := integer_map_new()
	for unit in units {
		integer_map_add(player_unit_count, rawptr(unit_get_owner(unit)), 1)
	}
	max: i32 = -1
	player: ^Game_Player = nil
	for current in integer_map_key_set(player_unit_count) {
		count := integer_map_get_int(player_unit_count, current)
		if count > max {
			max = count
			player = (^Game_Player)(current)
		}
	}
	return player
}

