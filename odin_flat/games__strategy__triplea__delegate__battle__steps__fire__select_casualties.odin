package game

Select_Casualties :: struct {
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	select_casualties: proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}

