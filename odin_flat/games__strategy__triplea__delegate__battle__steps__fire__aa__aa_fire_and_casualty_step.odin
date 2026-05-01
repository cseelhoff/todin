package game

Aa_Fire_And_Casualty_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

aa_fire_and_casualty_step_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Aa_Fire_And_Casualty_Step {
	self := new(Aa_Fire_And_Casualty_Step)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

aa_fire_and_casualty_step_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}
