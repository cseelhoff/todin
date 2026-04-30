package game

Remove_General_Suicide :: struct {
	using suicide_remove_units: Suicide_Remove_Units,
}

remove_general_suicide_get_all_step_details :: proc(self: ^Remove_General_Suicide) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_general_suicide_get_order :: proc(self: ^Remove_General_Suicide) -> Battle_Step_Order {
	return .SUICIDE_REMOVE_CASUALTIES
}
