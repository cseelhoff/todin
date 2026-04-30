package game

Clear_Bombardment_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.ClearBombardmentCasualties

clear_bombardment_casualties_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Clear_Bombardment_Casualties {
	self := new(Clear_Bombardment_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

clear_bombardment_casualties_get_order :: proc(
	self: ^Clear_Bombardment_Casualties,
) -> Battle_Step_Order {
	return .NAVAL_BOMBARDMENT_REMOVE_CASUALTIES
}

