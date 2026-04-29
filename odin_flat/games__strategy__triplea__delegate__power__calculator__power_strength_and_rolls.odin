package game

// Port of games.strategy.triplea.delegate.power.calculator.PowerStrengthAndRolls.
// Computes total power, strength, and roll for a collection of units.
Power_Strength_And_Rolls :: struct {
	calculator:                             Combat_Value,
	dice_sides:                             i32,
	total_strength_and_total_rolls_by_unit: map[^Unit]Unit_Power_Strength_And_Rolls,
	sorted_strength_and_rolls:              [dynamic]Unit_Power_Strength_And_Rolls,
	unit_support_power_map:                 map[^Unit]Integer_Map,
	unit_support_rolls_map:                 map[^Unit]Integer_Map,
}
