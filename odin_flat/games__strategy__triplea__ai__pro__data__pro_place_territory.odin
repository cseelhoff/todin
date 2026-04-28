package game

Pro_Place_Territory :: struct {
	territory:         ^Territory,
	place_units:       [dynamic]^Unit,
	defending_units:   [dynamic]^Unit,
	min_battle_result: ^Pro_Battle_Result,
	defense_value:     f64,
	strategic_value:   f64,
	can_hold:          bool,
}

