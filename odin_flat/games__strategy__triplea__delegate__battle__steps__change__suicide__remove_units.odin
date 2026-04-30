package game

Suicide_Remove_Units :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.suicide.RemoveUnits

suicide_remove_units_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Suicide_Remove_Units {
	self := new(Suicide_Remove_Units)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

