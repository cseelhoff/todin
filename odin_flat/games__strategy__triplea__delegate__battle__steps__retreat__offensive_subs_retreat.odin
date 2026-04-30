package game

Offensive_Subs_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_subs_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_Subs_Retreat {
	self := new(Offensive_Subs_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

