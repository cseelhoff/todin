package game

Defensive_General :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

defensive_general_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Defensive_General {
	self := new(Defensive_General)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

defensive_general_get_order :: proc(self: ^Defensive_General) -> Battle_Step_Order {
	return .GENERAL_DEFENSIVE
}

defensive_general_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}
