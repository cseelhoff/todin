package game

Defensive_Subs_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

defensive_subs_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Defensive_Subs_Retreat {
	self := new(Defensive_Subs_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

