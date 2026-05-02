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

// Java: AddUnits#<init>(String, String, Collection<Unit>)
//   this(name, type, units, AddUnits.buildUnitOwnerMap(units));
add_units_new_3 :: proc(
	name: string,
	type: string,
	units: [dynamic]^Unit,
) -> ^Add_Units {
	return add_units_new(name, type, units, add_units_build_unit_owner_map(units))
}

// Java: AddUnits#lambda$buildUnitsWithOwner$2(GameState, Map<UUID,Unit>, Map.Entry<UUID,String>)
// The `entry -> { ... }` mapper inside `buildUnitsWithOwner`. Resolves the
// unit referenced by `entry.getKey()` against the live game state, falling
// back to the locally-attached units when the game state has no record of
// the UUID, then reapplies the original owner recorded in `entry.getValue()`.
// Java's Map.Entry is decomposed into (key, value) parameters in Odin.
add_units_lambda_build_units_with_owner_2 :: proc(
	data: ^Game_State,
	uuid_to_units: map[Uuid]^Unit,
	key: Uuid,
	value: string,
) -> ^Unit {
	gd := cast(^Game_Data)data
	unit := units_list_get(game_data_get_units(gd), key)
	if unit == nil {
		unit = uuid_to_units[key]
	}
	if value != "" {
		player := player_list_get_player_id(game_data_get_player_list(gd), value)
		unit.owner = player
	}
	return unit
}

// Java: AddUnits#<init>(String, String, Collection<Unit>, Map<UUID,String>)
//   this.name = name; this.type = type;
//   this.units = List.copyOf(units); this.unitOwnerMap = unitOwnerMap;
add_units_new :: proc(
	name: string,
	type: string,
	units: [dynamic]^Unit,
	unit_owner_map: map[Uuid]string,
) -> ^Add_Units {
	au := new(Add_Units)
	au.kind = .Add_Units
	au.name = name
	au.type = type
	copied: [dynamic]^Unit
	for u in units {
		append(&copied, u)
	}
	au.units = copied
	au.unit_owner_map = unit_owner_map
	return au
}

// Java: AddUnits#perform(GameState)
//   final UnitHolder holder = data.getUnitHolder(name, type);
//   final Collection<Unit> unitsWithCorrectOwner =
//       unitOwnerMap == null ? units : buildUnitsWithOwner(data);
//   holder.getUnitCollection().addAll(unitsWithCorrectOwner);
//
// In the Odin port, `unit_owner_map` is always populated by the
// constructors (we don't load legacy saves that omitted it), so
// emptiness stands in for Java's null check.
add_units_perform :: proc(self: ^Add_Units, data: ^Game_State) {
	holder := game_state_get_unit_holder(data, self.name, self.type)
	units_with_correct_owner: [dynamic]^Unit
	if len(self.unit_owner_map) == 0 {
		units_with_correct_owner = self.units
	} else {
		units_with_correct_owner = add_units_build_units_with_owner(self, data)
	}
	unit_collection_add_all(unit_holder_get_unit_collection(holder), units_with_correct_owner)
}
