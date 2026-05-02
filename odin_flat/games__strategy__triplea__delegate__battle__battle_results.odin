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

// Java: BattleResults(IBattle battle, GameData data)
battle_results_new :: proc(battle: ^I_Battle, data: ^Game_Data) -> ^Battle_Results {
	self := new(Battle_Results)
	self.game_data_component = make_Game_Data_Component(data)
	self.battle_rounds_fought = i_battle_get_battle_round(battle)
	self.remaining_attacking_units = i_battle_get_remaining_attacking_units(battle)
	self.remaining_defending_units = i_battle_get_remaining_defending_units(battle)
	self.who_won = i_battle_get_who_won(battle)
	if self.who_won == .NOT_FINISHED {
		panic("Battle not finished yet")
	}
	return self
}

// Java: BattleResults(IBattle battle, WhoWon scriptedWhoWon, GameData data)
battle_results_new_with_who_won :: proc(battle: ^I_Battle, scripted_who_won: I_Battle_Who_Won, data: ^Game_Data) -> ^Battle_Results {
	self := new(Battle_Results)
	self.game_data_component = make_Game_Data_Component(data)
	self.battle_rounds_fought = i_battle_get_battle_round(battle)
	self.remaining_attacking_units = i_battle_get_remaining_attacking_units(battle)
	self.remaining_defending_units = i_battle_get_remaining_defending_units(battle)
	self.who_won = scripted_who_won
	return self
}

// Java: boolean draw()
battle_results_draw :: proc(self: ^Battle_Results) -> bool {
	return (self.who_won != .ATTACKER && self.who_won != .DEFENDER) ||
		(len(battle_results_get_remaining_attacking_units(self)) == 0 &&
			len(battle_results_get_remaining_defending_units(self)) == 0)
}

// Java: boolean attackerWon()
battle_results_attacker_won :: proc(self: ^Battle_Results) -> bool {
	return !battle_results_draw(self) && self.who_won == .ATTACKER
}

// Java: boolean defenderWon()
battle_results_defender_won :: proc(self: ^Battle_Results) -> bool {
	return !battle_results_draw(self) && self.who_won == .DEFENDER
}

