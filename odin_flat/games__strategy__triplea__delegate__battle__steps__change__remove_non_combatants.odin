package game

Remove_Non_Combatants :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

remove_non_combatants_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_Non_Combatants {
	self := new(Remove_Non_Combatants)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

remove_non_combatants_get_all_step_details :: proc(
	self: ^Remove_Non_Combatants,
) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_non_combatants_get_order :: proc(
	self: ^Remove_Non_Combatants,
) -> Battle_Step_Order {
	return .REMOVE_NON_COMBATANTS
}

