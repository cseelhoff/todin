package game

Retreater_General :: struct {
	using retreater: Retreater,
	battle_state: ^Battle_State,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral

retreater_general_new :: proc(battle_state: ^Battle_State) -> ^Retreater_General {
	self := new(Retreater_General)
	self.battle_state = battle_state
	return self
}

retreater_general_get_retreat_type :: proc(self: ^Retreater_General) -> Must_Fight_Battle_Retreat_Type {
	return .DEFAULT
}

