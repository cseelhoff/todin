package game

Remove_Unprotected_Units :: struct {
	using battle_step: Battle_Step,
	battle_state:      ^Battle_State,
	battle_actions:    ^Battle_Actions,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits

remove_unprotected_units_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_Unprotected_Units {
	self := new(Remove_Unprotected_Units)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

remove_unprotected_units_get_order :: proc(self: ^Remove_Unprotected_Units) -> Battle_Step_Order {
	return .REMOVE_UNPROTECTED_UNITS
}

