package game

Offensive_Aa_Fire :: struct {
	using aa_fire_and_casualty_step: Aa_Fire_And_Casualty_Step,
}

offensive_aa_fire_get_order :: proc(self: ^Offensive_Aa_Fire) -> Battle_Step_Order {
	return .AA_OFFENSIVE
}

offensive_aa_fire_get_side :: proc(self: ^Offensive_Aa_Fire) -> Battle_State_Side {
	return .OFFENSE
}
