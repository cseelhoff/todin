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

// Java synthetic lambda from calculateActiveStrengthAndRolls (filter for the
// best-infinite search): `unit -> calculator.getDiceSides(unit) == diceSides`.
// Each unit's dice sides were cached into `total_strength_and_total_rolls_by_unit`
// at construction (via `addUnits`, using `calculator.getDiceSides(unit)`), so the
// per-unit cached value equals what the lambda would compute on the calculator.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_0 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> bool {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	return int(entry.dice_sides) == self.dice_sides
}

// Java synthetic lambda from calculateActiveStrengthAndRolls
// (key extractor for `Comparator.comparingInt`):
// `unit -> totalStrengthAndTotalRollsByUnit.get(unit).getStrength()`.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_1 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> i32 {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	if entry.strength_and_rolls != nil {
		return entry.strength_and_rolls.strength
	}
	return 0
}

// Java synthetic lambda from calculateActiveStrengthAndRolls
// (mapper for `Optional.map` extracting the best infinite unit's strength):
// `unit -> totalStrengthAndTotalRollsByUnit.get(unit).getStrength()`.
aa_power_strength_and_rolls_lambda_calculate_active_strength_and_rolls_2 :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	unit: ^Unit,
) -> i32 {
	entry := self.total_strength_and_total_rolls_by_unit[unit]
	if entry.strength_and_rolls != nil {
		return entry.strength_and_rolls.strength
	}
	return 0
}

// Java: AaPowerStrengthAndRolls#addUnits(Collection<Unit>) — populates
// `totalStrengthAndTotalRollsByUnit` with a UnitPowerStrengthAndRolls entry per
// unit, computed via the calculator's strength/roll/power calculators.
aa_power_strength_and_rolls_add_units :: proc(
	self: ^Aa_Power_Strength_And_Rolls,
	units: [dynamic]^Unit,
) {
	if self.total_strength_and_total_rolls_by_unit == nil {
		self.total_strength_and_total_rolls_by_unit = make(
			map[^Unit]Unit_Power_Strength_And_Rolls,
		)
	}
	strength_calculator := combat_value_get_strength(self.calculator)
	roll_calculator := combat_value_get_roll(self.calculator)
	power_calculator := combat_value_get_power(self.calculator)
	for unit in units {
		b := unit_power_strength_and_rolls_builder()
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_unit(b, unit)
		sar := strength_and_rolls_new(
			strength_calculator_get_strength(strength_calculator, unit),
			roll_calculator_get_roll(roll_calculator, unit),
		)
		b =
			unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_strength_and_rolls(
				b,
				sar,
			)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power(
			b,
			power_calculator_get_value_unit(power_calculator, unit),
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power_calculator(
			b,
			power_calculator,
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_dice_sides(
			b,
			combat_value_get_dice_sides(self.calculator, unit),
		)
		b = unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_choose_best_roll(
			b,
			combat_value_choose_best_roll(self.calculator, unit),
		)
		built := unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_build(b)
		self.total_strength_and_total_rolls_by_unit[unit] = built^
	}
}
