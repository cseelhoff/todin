package game

Battle_Results :: struct {
	using game_data_component: Game_Data_Component,
	battle_rounds_fought:       i32,
	remaining_attacking_units:  [dynamic]^Unit,
	remaining_defending_units:  [dynamic]^Unit,
	who_won:                    I_Battle_Who_Won,
}

battle_results_get_remaining_attacking_units :: proc(self: ^Battle_Results) -> [dynamic]^Unit {
	return self.remaining_attacking_units
}

battle_results_get_remaining_defending_units :: proc(self: ^Battle_Results) -> [dynamic]^Unit {
	return self.remaining_defending_units
}

