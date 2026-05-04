package game

Remove_Units :: struct {
	using add_units: Add_Units,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.RemoveUnits

// Java: RemoveUnits#<init>(UnitCollection, Collection<Unit>)
//   this(collection.getHolder().getName(), collection.getHolder().getType(), units);
remove_units_new_2 :: proc(
	collection: ^Unit_Collection,
	units: [dynamic]^Unit,
) -> ^Remove_Units {
	holder := collection.holder
	return remove_units_new_3(holder.named.base.name, named_unit_holder_get_type(holder), units)
}

// Java: RemoveUnits#<init>(String, String, Collection<Unit>)
//   this(name, type, units, AddUnits.buildUnitOwnerMap(units));
remove_units_new_3 :: proc(
	name: string,
	type: string,
	units: [dynamic]^Unit,
) -> ^Remove_Units {
	return remove_units_new(name, type, units, add_units_build_unit_owner_map(units))
}

// Java: RemoveUnits#<init>(String, String, Collection<Unit>, Map<UUID,String>)
//   this.name = name; this.type = type;
//   this.units = List.copyOf(units); this.unitOwnerMap = unitOwnerMap;
remove_units_new :: proc(
	name: string,
	type: string,
	units: [dynamic]^Unit,
	unit_owner_map: map[Uuid]string,
) -> ^Remove_Units {
	ru := new(Remove_Units)
	ru.kind = .Remove_Units
	ru.name = name
	ru.type = type
	copied: [dynamic]^Unit
	for u in units {
		append(&copied, u)
	}
	ru.units = copied
	ru.unit_owner_map = unit_owner_map
	return ru
}

// Java: RemoveUnits#perform(GameState)
//   final UnitHolder holder = data.getUnitHolder(name, type);
//   holder.getUnitCollection().removeAll(units);
remove_units_perform :: proc(self: ^Remove_Units, state: ^Game_State) {
	holder := game_state_get_unit_holder(state, self.name, self.type)
	unit_collection_remove_all(unit_holder_get_unit_collection(holder), self.units)
}

