package game

Add_Units :: struct {
	using change: Change,
	name:           string,
	units:          [dynamic]^Unit,
	type:           string,
	unit_owner_map: map[Uuid]string,
}

// Returns a map of unit UUIDs to player names.
add_units_build_unit_owner_map :: proc(units: [dynamic]^Unit) -> map[Uuid]string {
	result := make(map[Uuid]string)
	for u in units {
		result[u.id] = u.owner.named.base.name
	}
	return result
}

// Java: `u -> u.getOwner().getName()` — value mapper for the
// `Collectors.toMap(Unit::getId, ...)` call inside `buildUnitOwnerMap`.
add_units_lambda_build_unit_owner_map_0 :: proc(unit: ^Unit) -> string {
	return unit.owner.named.base.name
}

add_units_lambda_build_units_with_owner_1 :: proc(self: ^Add_Units, unit: ^Unit) -> ^Unit {
	return unit
}

// Java: AddUnits#buildUnitsWithOwner(GameState)
//
// Resolves each unit referenced by `unit_owner_map` against the live game
// state, falling back to the locally-attached units when the game state has
// no record of the UUID, and reapplies the original owner recorded at the
// time the change was created.
add_units_build_units_with_owner :: proc(self: ^Add_Units, state: ^Game_State) -> [dynamic]^Unit {
	data := cast(^Game_Data)state
	uuid_to_units := make(map[Uuid]^Unit)
	for unit in self.units {
		uuid_to_units[unit.id] = unit
	}
	result: [dynamic]^Unit
	for key, value in self.unit_owner_map {
		unit := units_list_get(game_data_get_units(data), key)
		if unit == nil {
			unit = uuid_to_units[key]
		}
		if value != "" {
			player := player_list_get_player_id(game_data_get_player_list(data), value)
			unit.owner = player
		}
		append(&result, unit)
	}
	return result
}
