package game

Power_Calculator :: struct {
	strength_calculator: ^Strength_Calculator,
	roll_calculator:     ^Roll_Calculator,
	choose_best_roll:    proc(unit: ^Unit) -> bool,
	get_dice_sides:      proc(unit: ^Unit) -> i32,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.PowerCalculator

power_calculator_new :: proc(
	strength_calculator: ^Strength_Calculator,
	roll_calculator: ^Roll_Calculator,
	choose_best_roll: proc(unit: ^Unit) -> bool,
	get_dice_sides: proc(unit: ^Unit) -> i32,
) -> ^Power_Calculator {
	self := new(Power_Calculator)
	self.strength_calculator = strength_calculator
	self.roll_calculator = roll_calculator
	self.choose_best_roll = choose_best_roll
	self.get_dice_sides = get_dice_sides
	return self
}

power_calculator_get_value_unit :: proc(self: ^Power_Calculator, unit: ^Unit) -> i32 {
	return power_calculator_get_value(
		self.choose_best_roll(unit),
		self.get_dice_sides(unit),
		strength_calculator_get_strength(self.strength_calculator, unit),
		roll_calculator_get_roll(self.roll_calculator, unit),
	)
}

power_calculator_get_value :: proc(
	choose_best_roll: bool,
	dice_sides: i32,
	unit_strength: ^Strength_Value,
	unit_rolls: ^Roll_Value,
) -> i32 {
	if strength_value_is_zero(unit_strength) || roll_value_is_zero(unit_rolls) {
		return 0
	}
	extra_roll_bonus := max(i32(1), dice_sides / 6)

	total_power: i32 = 0
	if roll_value_get_value(unit_rolls) == 1 {
		total_power += strength_value_get_value(unit_strength)
	} else {
		if choose_best_roll {
			total_power += min(
				strength_value_get_value(unit_strength) +
				extra_roll_bonus * (roll_value_get_value(unit_rolls) - 1),
				dice_sides,
			)
		} else {
			total_power += roll_value_get_value(unit_rolls) * strength_value_get_value(unit_strength)
		}
	}
	return total_power
}

