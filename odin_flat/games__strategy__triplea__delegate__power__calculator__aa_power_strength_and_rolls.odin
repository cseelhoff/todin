package game

Aa_Power_Strength_And_Rolls :: struct {
	best_strength:                          int,
	dice_sides:                             int,
	calculator:                             ^Combat_Value,
	total_strength_and_total_rolls_by_unit: map[^Unit]Unit_Power_Strength_And_Rolls,
	target_count:                           int,
	active_strength_and_rolls:              [dynamic]Unit_Power_Strength_And_Rolls,
}

aa_power_strength_and_rolls_get_active_units :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return self.active_strength_and_rolls
}

aa_power_strength_and_rolls_calculate_total_power :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for entry in self.active_strength_and_rolls {
		sum += entry.power
	}
	return sum
}

aa_power_strength_and_rolls_calculate_total_rolls :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	sum: i32 = 0
	for entry in self.active_strength_and_rolls {
		if entry.strength_and_rolls != nil {
			sum += entry.strength_and_rolls.rolls
		}
	}
	return sum
}

aa_power_strength_and_rolls_get_best_strength :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	return i32(self.best_strength)
}

aa_power_strength_and_rolls_get_dice_sides :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> i32 {
	return i32(self.dice_sides)
}

aa_power_strength_and_rolls_is_same_strength :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
) -> bool {
	seen: map[i32]struct {}
	defer delete(seen)
	for entry in self.active_strength_and_rolls {
		s: i32 = 0
		if entry.strength_and_rolls != nil {
			s = entry.strength_and_rolls.strength
		}
		seen[s] = {}
	}
	return len(seen) == 1
}
