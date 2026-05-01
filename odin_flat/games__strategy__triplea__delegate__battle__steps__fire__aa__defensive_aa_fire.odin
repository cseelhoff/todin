package game

Defensive_Aa_Fire :: struct {
	using aa_fire_and_casualty_step: Aa_Fire_And_Casualty_Step,
}

defensive_aa_fire_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Defensive_Aa_Fire {
	self := new(Defensive_Aa_Fire)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

defensive_aa_fire_get_order :: proc(self: ^Defensive_Aa_Fire) -> Battle_Step_Order {
	return .AA_DEFENSIVE
}

defensive_aa_fire_get_side :: proc(self: ^Defensive_Aa_Fire) -> Battle_State_Side {
	return .DEFENSE
}
