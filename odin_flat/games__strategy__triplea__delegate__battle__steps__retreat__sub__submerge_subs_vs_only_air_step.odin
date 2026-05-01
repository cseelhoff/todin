package game

Submerge_Subs_Vs_Only_Air_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

submerge_subs_vs_only_air_step_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Submerge_Subs_Vs_Only_Air_Step {
	self := new(Submerge_Subs_Vs_Only_Air_Step)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

submerge_subs_vs_only_air_step_get_order :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
) -> Battle_Step_Order {
	return Battle_Step_Order.SUBMERGE_SUBS_VS_ONLY_AIR
}

