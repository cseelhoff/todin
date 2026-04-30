package game

Aa_Fire_And_Casualty_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

aa_fire_and_casualty_step_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Aa_Fire_And_Casualty_Step {
	self := new(Aa_Fire_And_Casualty_Step)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}
