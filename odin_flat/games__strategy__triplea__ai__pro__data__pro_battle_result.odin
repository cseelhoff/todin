package game

Pro_Battle_Result :: struct {
	win_percentage:              f64,
	tuv_swing:                   f64,
	has_land_unit_remaining:     bool,
	average_attackers_remaining: [dynamic]^Unit,
	average_defenders_remaining: [dynamic]^Unit,
	battle_rounds:               f64,
}

pro_battle_result_get_average_attackers_remaining :: proc(self: ^Pro_Battle_Result) -> [dynamic]^Unit {
	return self.average_attackers_remaining
}

pro_battle_result_get_average_defenders_remaining :: proc(self: ^Pro_Battle_Result) -> [dynamic]^Unit {
	return self.average_defenders_remaining
}

pro_battle_result_get_battle_rounds :: proc(self: ^Pro_Battle_Result) -> f64 {
	return self.battle_rounds
}

pro_battle_result_get_tuv_swing :: proc(self: ^Pro_Battle_Result) -> f64 {
	return self.tuv_swing
}

pro_battle_result_get_win_percentage :: proc(self: ^Pro_Battle_Result) -> f64 {
	return self.win_percentage
}

pro_battle_result_is_has_land_unit_remaining :: proc(self: ^Pro_Battle_Result) -> bool {
	return self.has_land_unit_remaining
}

pro_battle_result_new :: proc(
	win_percentage: f64,
	tuv_swing: f64,
	has_land_unit_remaining: bool,
	average_attackers_remaining: [dynamic]^Unit,
	average_defenders_remaining: [dynamic]^Unit,
	battle_rounds: f64,
) -> ^Pro_Battle_Result {
	self := new(Pro_Battle_Result)
	self.win_percentage = win_percentage
	self.tuv_swing = tuv_swing
	self.has_land_unit_remaining = has_land_unit_remaining
	self.average_attackers_remaining = average_attackers_remaining
	self.average_defenders_remaining = average_defenders_remaining
	self.battle_rounds = battle_rounds
	return self
}

pro_battle_result_new_empty :: proc() -> ^Pro_Battle_Result {
	return pro_battle_result_new(0, -1, false, make([dynamic]^Unit), make([dynamic]^Unit), 0)
}
