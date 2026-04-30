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

remove_units_history_change_get_new_units :: proc(self: ^Remove_Units_History_Change) -> [dynamic]^Unit {
	return self.new_units
}

remove_units_history_change_get_old_units :: proc(self: ^Remove_Units_History_Change) -> [dynamic]^Unit {
	return self.old_units
}

// Java: k -> new ArrayList<>() inside unloadedUnits.computeIfAbsent(...).
// Non-capturing; returns a fresh empty dynamic array of ^Unit.
remove_units_history_change_lambda_new_2 :: proc(k: ^Territory) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

