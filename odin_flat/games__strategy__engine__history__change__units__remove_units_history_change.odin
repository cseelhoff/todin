package game

Remove_Units_History_Change :: struct {
	change:                                 ^Composite_Change,
	location:                               ^Territory,
	killed_units:                           [dynamic]^Unit,
	unloaded_units:                         map[^Territory][dynamic]^Unit,
	transform_damaged_units_history_change: ^Transform_Damaged_Units_History_Change,
	message_template:                       string,
	old_units:                              [dynamic]^Unit,
	new_units:                              [dynamic]^Unit,
}

Remove_Units_History_Change :: struct {
	change:                                 ^Composite_Change,
	location:                               ^Territory,
	killed_units:                           [dynamic]^Unit,
	unloaded_units:                         map[^Territory][dynamic]^Unit,
	transform_damaged_units_history_change: ^Transform_Damaged_Units_History_Change,
	message_template:                       string,
	old_units:                              [dynamic]^Unit,
	new_units:                              [dynamic]^Unit,
}
