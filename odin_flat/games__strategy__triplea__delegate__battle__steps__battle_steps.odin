package game

Battle_Steps :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

battle_steps_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Battle_Steps {
	self := new(Battle_Steps)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}
