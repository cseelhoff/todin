package game

Transform_Damaged_Units_History_Change_Grouped_Units :: struct {
	old_units: [dynamic]^Unit,
	new_units: [dynamic]^Unit,
}

Transform_Damaged_Units_History_Change :: struct {
	change:                        ^Composite_Change,
	location:                      ^Territory,
	transforming_units:            map[^Unit]^Unit,
	attribute_changes:             ^Composite_Change,
	mark_no_movement_on_new_units: bool,
}

