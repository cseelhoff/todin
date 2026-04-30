package game

Transform_Damaged_Units_History_Change_Grouped_Units :: struct {
	old_units: [dynamic]^Unit,
	new_units: [dynamic]^Unit,
}

transform_damaged_units_history_change_grouped_units_new :: proc() -> ^Transform_Damaged_Units_History_Change_Grouped_Units {
	self := new(Transform_Damaged_Units_History_Change_Grouped_Units)
	self.old_units = make([dynamic]^Unit)
	self.new_units = make([dynamic]^Unit)
	return self
}

transform_damaged_units_history_change_grouped_units_add_units :: proc(self: ^Transform_Damaged_Units_History_Change_Grouped_Units, old_unit: ^Unit, new_unit: ^Unit) {
	append(&self.old_units, old_unit)
	append(&self.new_units, new_unit)
}

transform_damaged_units_history_change_grouped_units_get_new_units :: proc(self: ^Transform_Damaged_Units_History_Change_Grouped_Units) -> [dynamic]^Unit {
	return self.new_units
}

transform_damaged_units_history_change_grouped_units_get_old_units :: proc(self: ^Transform_Damaged_Units_History_Change_Grouped_Units) -> [dynamic]^Unit {
	return self.old_units
}
