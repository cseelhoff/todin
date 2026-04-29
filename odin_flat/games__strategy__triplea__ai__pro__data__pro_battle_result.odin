package game

Pro_Battle_Result :: struct {
	win_percentage:              f64,
	tuv_swing:                   f64,
	has_land_unit_remaining:     bool,
	average_attackers_remaining: [dynamic]^Unit,
	average_defenders_remaining: [dynamic]^Unit,
	battle_rounds:               f64,
}
