package game

Initialize_Unit_Initialize :: struct {
	unit_placements: [dynamic]^Initialize_Unit_Initialize_Unit_Placement,
	held_units:      [dynamic]^Initialize_Unit_Initialize_Held_Units,
}

initialize_unit_initialize_get_held_units :: proc(self: ^Initialize_Unit_Initialize) -> [dynamic]^Initialize_Unit_Initialize_Held_Units {
	return self.held_units
}

initialize_unit_initialize_get_unit_placements :: proc(self: ^Initialize_Unit_Initialize) -> [dynamic]^Initialize_Unit_Initialize_Unit_Placement {
	return self.unit_placements
}

