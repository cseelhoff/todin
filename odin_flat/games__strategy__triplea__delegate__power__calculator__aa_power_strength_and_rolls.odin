package game

Aa_Power_Strength_And_Rolls :: struct {
	best_strength:                          int,
	dice_sides:                             int,
	calculator:                             ^Combat_Value,
	total_strength_and_total_rolls_by_unit: map[^Unit]Unit_Power_Strength_And_Rolls,
	target_count:                           int,
	active_strength_and_rolls:              [dynamic]Unit_Power_Strength_And_Rolls,
}
