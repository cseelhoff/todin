package game

Retreater_Partial_Amphibious :: struct {
	battle_state: ^Battle_State,
}

retreater_partial_amphibious_new :: proc(battle_state: ^Battle_State) -> ^Retreater_Partial_Amphibious {
	self := new(Retreater_Partial_Amphibious)
	self.battle_state = battle_state
	return self
}
