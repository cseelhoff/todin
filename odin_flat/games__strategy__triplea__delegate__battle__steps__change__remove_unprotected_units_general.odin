package game

Remove_Unprotected_Units_General :: struct {
	using remove_unprotected_units: Remove_Unprotected_Units,
}

remove_unprotected_units_general_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return remove_unprotected_units_general_get_all_step_details(cast(^Remove_Unprotected_Units_General)self)
}

remove_unprotected_units_general_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_Unprotected_Units_General {
	self := new(Remove_Unprotected_Units_General)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.battle_step.get_all_step_details = remove_unprotected_units_general_v_get_all_step_details
	return self
}

remove_unprotected_units_general_get_all_step_details :: proc(self: ^Remove_Unprotected_Units_General) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

remove_unprotected_units_general_get_order :: proc(self: ^Remove_Unprotected_Units_General) -> Battle_Step_Order {
	return .REMOVE_UNPROTECTED_UNITS_GENERAL
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnitsGeneral

