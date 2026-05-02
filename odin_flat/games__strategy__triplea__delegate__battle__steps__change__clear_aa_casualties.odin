package game

Clear_Aa_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.ClearAaCasualties

clear_aa_casualties_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Clear_Aa_Casualties {
	self := new(Clear_Aa_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

clear_aa_casualties_get_all_step_details :: proc(
	self: ^Clear_Aa_Casualties,
) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

clear_aa_casualties_get_order :: proc(
	self: ^Clear_Aa_Casualties,
) -> Battle_Step_Order {
	return .AA_REMOVE_CASUALTIES
}

clear_aa_casualties_execute :: proc(
	self: ^Clear_Aa_Casualties,
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
