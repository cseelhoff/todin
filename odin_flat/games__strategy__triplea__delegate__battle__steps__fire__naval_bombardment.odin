package game

Naval_Bombardment :: struct {
	using battle_step: Battle_Step,
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
}

naval_bombardment_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Naval_Bombardment {
	self := new(Naval_Bombardment)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

naval_bombardment_get_order :: proc(self: ^Naval_Bombardment) -> Battle_Step_Order {
	return .NAVAL_BOMBARDMENT
}

naval_bombardment_lambda__get_all_step_details__0 :: proc(step: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return battle_step_get_all_step_details(step)
}

naval_bombardment_valid :: proc(self: ^Naval_Bombardment) -> bool {
	return battle_status_is_first_round(battle_state_get_status(self.battle_state)) &&
		len(battle_state_get_bombarding_units(self.battle_state)) > 0 &&
		!territory_is_water(battle_state_get_battle_site(self.battle_state))
}
