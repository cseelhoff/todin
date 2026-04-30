package game

Check_Stalemate_Battle_End :: struct {
	using check_general_battle_end: Check_General_Battle_End,
}

check_stalemate_battle_end_get_all_step_details :: proc(self: ^Check_Stalemate_Battle_End) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

check_stalemate_battle_end_get_order :: proc(self: ^Check_Stalemate_Battle_End) -> Battle_Step_Order {
	return .STALEMATE_BATTLE_END_CHECK
}
