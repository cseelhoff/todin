package game

Mark_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:      ^Battle_State,
	battle_actions:    ^Battle_Actions,
	side:              Battle_State_Side,
	firing_group:      ^Firing_Group,
	fire_round_state:  ^Fire_Round_State,
	return_fire:       Must_Fight_Battle_Return_Fire,
}

