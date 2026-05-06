package game

Remove_General_Suicide :: struct {
	using suicide_remove_units: Suicide_Remove_Units,
}

// Java: super(battleState, battleActions)
remove_general_suicide_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return remove_general_suicide_get_all_step_details(cast(^Remove_General_Suicide)self)
}

remove_general_suicide_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	remove_general_suicide_execute(cast(^Remove_General_Suicide)self, stack, bridge)
}

remove_general_suicide_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_General_Suicide {
	self := new(Remove_General_Suicide)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.battle_step.get_all_step_details = remove_general_suicide_v_get_all_step_details
	self.battle_step.i_executable.execute = remove_general_suicide_v_execute
	return self
}

remove_general_suicide_get_all_step_details :: proc(self: ^Remove_General_Suicide) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_general_suicide_get_order :: proc(self: ^Remove_General_Suicide) -> Battle_Step_Order {
	return .SUICIDE_REMOVE_CASUALTIES
}

// Java: Matches.unitIsFirstStrike().negate()
remove_general_suicide_pred_not_first_strike :: proc(_: rawptr, u: ^Unit) -> bool {
	pred, ctx := matches_unit_is_first_strike()
	return !pred(ctx, u)
}

// Java: removeUnits(bridge, Matches.unitIsFirstStrike().negate());
remove_general_suicide_execute :: proc(
	self: ^Remove_General_Suicide,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	suicide_remove_units_remove_units(
		&self.suicide_remove_units,
		bridge,
		remove_general_suicide_pred_not_first_strike,
		nil,
	)
}
