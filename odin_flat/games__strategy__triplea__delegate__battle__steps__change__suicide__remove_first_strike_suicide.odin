package game

Remove_First_Strike_Suicide :: struct {
	using suicide_remove_units: Suicide_Remove_Units,
}

remove_first_strike_suicide_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return remove_first_strike_suicide_get_all_step_details(cast(^Remove_First_Strike_Suicide)self)
}

remove_first_strike_suicide_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	remove_first_strike_suicide_execute(cast(^Remove_First_Strike_Suicide)self, stack, bridge)
}

remove_first_strike_suicide_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Remove_First_Strike_Suicide {
	self := new(Remove_First_Strike_Suicide)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.battle_step.get_all_step_details = remove_first_strike_suicide_v_get_all_step_details
	self.battle_step.get_order = remove_first_strike_suicide_v_get_order
	self.battle_step.i_executable.execute = remove_first_strike_suicide_v_execute
	return self
}

remove_first_strike_suicide_v_get_order :: proc(self: ^Battle_Step) -> Battle_Step_Order {
	return remove_first_strike_suicide_get_order(cast(^Remove_First_Strike_Suicide)self)
}

remove_first_strike_suicide_get_all_step_details :: proc(self: ^Remove_First_Strike_Suicide) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_first_strike_suicide_get_order :: proc(self: ^Remove_First_Strike_Suicide) -> Battle_Step_Order {
	return .FIRST_STRIKE_SUICIDE_REMOVE_CASUALTIES
}

// Java: removeUnits(bridge, Matches.unitIsFirstStrike());
remove_first_strike_suicide_execute :: proc(
	self: ^Remove_First_Strike_Suicide,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	pred, ctx := matches_unit_is_first_strike()
	suicide_remove_units_remove_units(
		&self.suicide_remove_units,
		bridge,
		pred,
		ctx,
	)
}
