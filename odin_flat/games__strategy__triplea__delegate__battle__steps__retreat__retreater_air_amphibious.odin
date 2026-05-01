package game

Retreater_Air_Amphibious :: struct {
	battle_state: ^Battle_State,
}

retreater_air_amphibious_new :: proc(battle_state: ^Battle_State) -> ^Retreater_Air_Amphibious {
	self := new(Retreater_Air_Amphibious)
	self.battle_state = battle_state
	return self
}
