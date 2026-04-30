package game

// games.strategy.engine.data.UnitsList
//
// Game-wide unit registry, keyed by UUID.

Units_List :: struct {
	units: map[Uuid]^Unit,
}

make_Units_List :: proc() -> ^Units_List {
	self := new(Units_List)
	self.units = make(map[Uuid]^Unit)
	return self
}

units_list_get_units :: proc(self: ^Units_List) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for _, u in self.units {
		append(&result, u)
	}
	return result
}

units_list_put :: proc(self: ^Units_List, unit: ^Unit) {
	self.units[unit.id] = unit
}

units_list_get :: proc(self: ^Units_List, id: Uuid) -> ^Unit {
	return self.units[id]
}

// iterator() -> Iterator<Unit>: returns getUnits().iterator(); the caller
// owns the returned dynamic array and must `delete` it.
units_list_iterator :: proc(self: ^Units_List) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for _, unit in self.units {
		append(&result, unit)
	}
	return result
}
