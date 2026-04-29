package game

Battle_Results :: struct {
	using game_data_component: Game_Data_Component,
	battle_rounds_fought:       i32,
	remaining_attacking_units:  [dynamic]^Unit,
	remaining_defending_units:  [dynamic]^Unit,
	who_won:                    I_Battle_Who_Won,
}

