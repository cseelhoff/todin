package game

Initialize_Unit_Initialize_Unit_Placement :: struct {
	unit_type:   string,
	territory:   string,
	quantity:    i32,
	owner:       string,
	hits_taken:  ^i32,
	unit_damage: ^i32,
}

initialize_unit_initialize_unit_placement_get_unit_type :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> string {
	return self.unit_type
}

initialize_unit_initialize_unit_placement_get_territory :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> string {
	return self.territory
}

initialize_unit_initialize_unit_placement_get_quantity :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> i32 {
	return self.quantity
}

initialize_unit_initialize_unit_placement_get_owner :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> string {
	return self.owner
}

initialize_unit_initialize_unit_placement_get_hits_taken :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> ^i32 {
	return self.hits_taken
}

initialize_unit_initialize_unit_placement_get_unit_damage :: proc(self: ^Initialize_Unit_Initialize_Unit_Placement) -> ^i32 {
	return self.unit_damage
}
