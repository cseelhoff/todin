package game

Defensive_First_Strike :: struct {
	using battle_step:  Battle_Step,
	battle_state:    ^Battle_State,
	battle_actions:  ^Battle_Actions,
	state:           Defensive_First_Strike_State,
	return_fire:     Must_Fight_Battle_Return_Fire,
}

defensive_first_strike_get_order :: proc(self: ^Defensive_First_Strike) -> Battle_Step_Order {
	if self.state == .REGULAR {
		return .FIRST_STRIKE_DEFENSIVE_REGULAR
	}
	return .FIRST_STRIKE_DEFENSIVE
}
