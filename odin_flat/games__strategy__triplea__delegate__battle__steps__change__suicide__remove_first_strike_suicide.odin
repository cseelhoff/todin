package game

Remove_First_Strike_Suicide :: struct {
	using suicide_remove_units: Suicide_Remove_Units,
}

remove_first_strike_suicide_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Remove_First_Strike_Suicide {
	self := new(Remove_First_Strike_Suicide)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

remove_first_strike_suicide_get_all_step_details :: proc(self: ^Remove_First_Strike_Suicide) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_first_strike_suicide_get_order :: proc(self: ^Remove_First_Strike_Suicide) -> Battle_Step_Order {
	return .FIRST_STRIKE_SUICIDE_REMOVE_CASUALTIES
}
