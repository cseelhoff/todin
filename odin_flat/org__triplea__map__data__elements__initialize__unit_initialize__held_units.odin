package game

Initialize_Unit_Initialize_Held_Units :: struct {
	unit_type: string,
	player:    string,
	quantity:  i32,
}
// Java owners covered by this file:
//   - org.triplea.map.data.elements.Initialize$UnitInitialize$HeldUnits

initialize_unit_initialize_held_units_get_player :: proc(self: ^Initialize_Unit_Initialize_Held_Units) -> string {
	return self.player
}

initialize_unit_initialize_held_units_get_quantity :: proc(self: ^Initialize_Unit_Initialize_Held_Units) -> i32 {
	return self.quantity
}

initialize_unit_initialize_held_units_get_unit_type :: proc(self: ^Initialize_Unit_Initialize_Held_Units) -> string {
	return self.unit_type
}

