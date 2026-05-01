package game

Offensive_General :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_general_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_General {
	self := new(Offensive_General)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

offensive_general_get_order :: proc(self: ^Offensive_General) -> Battle_Step_Order {
	return .GENERAL_OFFENSIVE
}

offensive_general_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}
