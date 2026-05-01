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

battle_steps_builder :: proc() -> ^Battle_Steps_Battle_Steps_Builder {
	return battle_steps_battle_steps_builder_new()
}

battle_steps_lambda_get_0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}
