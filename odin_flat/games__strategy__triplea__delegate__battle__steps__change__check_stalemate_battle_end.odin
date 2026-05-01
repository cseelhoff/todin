package game

Check_Stalemate_Battle_End :: struct {
	using check_general_battle_end: Check_General_Battle_End,
}

check_stalemate_battle_end_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Check_Stalemate_Battle_End {
	self := new(Check_Stalemate_Battle_End)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

check_stalemate_battle_end_get_all_step_details :: proc(self: ^Check_Stalemate_Battle_End) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

check_stalemate_battle_end_get_order :: proc(self: ^Check_Stalemate_Battle_End) -> Battle_Step_Order {
	return .STALEMATE_BATTLE_END_CHECK
}

// Java: if (!getBattleState().getStatus().isOver() && isStalemate())
//         getBattleActions().endBattle(IBattle.WhoWon.DRAW, bridge);
check_stalemate_battle_end_execute :: proc(
	self: ^Check_Stalemate_Battle_End,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	parent := &self.check_general_battle_end
	status := battle_state_get_status(check_general_battle_end_get_battle_state(parent))
	if !battle_status_is_over(status) && check_general_battle_end_is_stalemate(parent) {
		battle_actions_end_battle(
			check_general_battle_end_get_battle_actions(parent),
			.DRAW,
			bridge,
		)
	}
}
