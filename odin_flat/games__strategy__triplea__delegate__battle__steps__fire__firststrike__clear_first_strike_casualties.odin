package game

Clear_First_Strike_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	offense_state:  Clear_First_Strike_Casualties_State,
	defense_state:  Clear_First_Strike_Casualties_State,
}

clear_first_strike_casualties_get_order :: proc(self: ^Clear_First_Strike_Casualties) -> Battle_Step_Order {
	return .FIRST_STRIKE_REMOVE_CASUALTIES
}

clear_first_strike_casualties_offense_has_sneak_attack :: proc(self: ^Clear_First_Strike_Casualties) -> bool {
	return self.offense_state == .SNEAK_ATTACK
}

clear_first_strike_casualties_defense_has_sneak_attack :: proc(self: ^Clear_First_Strike_Casualties) -> bool {
	return self.defense_state == .SNEAK_ATTACK
}

