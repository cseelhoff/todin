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

power_strength_and_rolls_get_active_units :: proc(
	self: ^Power_Strength_And_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return self.sorted_strength_and_rolls
}

power_strength_and_rolls_calculate_total_power :: proc(
	self: ^Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for _, v in self.total_strength_and_total_rolls_by_unit {
		sum += v.power
	}
	return sum
}

power_strength_and_rolls_calculate_total_rolls :: proc(
	self: ^Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for _, v in self.total_strength_and_total_rolls_by_unit {
		if v.strength_and_rolls != nil {
			sum += v.strength_and_rolls.rolls
		}
	}
	return sum
}

power_strength_and_rolls_get_total_strength_and_total_rolls_by_unit :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Unit_Power_Strength_And_Rolls {
	return self.total_strength_and_total_rolls_by_unit
}

power_strength_and_rolls_get_unit_support_power_map :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Integer_Map {
	return self.unit_support_power_map
}

power_strength_and_rolls_get_unit_support_rolls_map :: proc(
	self: ^Power_Strength_And_Rolls,
) -> map[^Unit]Integer_Map {
	return self.unit_support_rolls_map
}
