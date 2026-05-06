package game

Clear_General_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

clear_general_casualties_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return clear_general_casualties_get_all_step_details(cast(^Clear_General_Casualties)self)
}

clear_general_casualties_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	clear_general_casualties_execute(cast(^Clear_General_Casualties)self, stack, bridge)
}

clear_general_casualties_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Clear_General_Casualties {
	self := new(Clear_General_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.get_all_step_details = clear_general_casualties_v_get_all_step_details
	self.execute = clear_general_casualties_v_execute
	return self
}

clear_general_casualties_get_order :: proc(self: ^Clear_General_Casualties) -> Battle_Step_Order {
	return .GENERAL_REMOVE_CASUALTIES
}

// Java: return List.of(new StepDetails(REMOVE_CASUALTIES, this));
clear_general_casualties_get_all_step_details :: proc(
	self: ^Clear_General_Casualties,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	append(&out, battle_step_step_details_new(BATTLE_STEP_REMOVE_CASUALTIES, &self.battle_step))
	return out
}

// Java: battleActions.clearWaitingToDieAndDamagedChangesInto(
//           bridge, BattleState.Side.OFFENSE, BattleState.Side.DEFENSE);
clear_general_casualties_execute :: proc(
	self: ^Clear_General_Casualties,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	battle_actions_clear_waiting_to_die_and_damaged_changes_into(
		self.battle_actions,
		bridge,
		.OFFENSE,
		.DEFENSE,
	)
}
