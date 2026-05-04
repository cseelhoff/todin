package game

Unit_Power_Strength_And_Rolls :: struct {
	power:              i32,
	strength_and_rolls: ^Strength_And_Rolls,
	unit:               ^Unit,
	power_calculator:   ^Power_Calculator,
	choose_best_roll:   bool,
	dice_sides:         i32,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.UnitPowerStrengthAndRolls

unit_power_strength_and_rolls_new :: proc(
	power: i32,
	strength_and_rolls: ^Strength_And_Rolls,
	unit: ^Unit,
	power_calculator: ^Power_Calculator,
	choose_best_roll: bool,
	dice_sides: i32,
) -> ^Unit_Power_Strength_And_Rolls {
	self := new(Unit_Power_Strength_And_Rolls)
	self.power = power
	self.strength_and_rolls = strength_and_rolls
	self.unit = unit
	self.power_calculator = power_calculator
	self.choose_best_roll = choose_best_roll
	self.dice_sides = dice_sides
	return self
}

unit_power_strength_and_rolls_get_power :: proc(self: ^Unit_Power_Strength_And_Rolls) -> i32 {
	return self.power
}

unit_power_strength_and_rolls_get_choose_best_roll :: proc(self: ^Unit_Power_Strength_And_Rolls) -> bool {
	return self.choose_best_roll
}

unit_power_strength_and_rolls_get_dice_sides :: proc(self: ^Unit_Power_Strength_And_Rolls) -> i32 {
	return self.dice_sides
}

unit_power_strength_and_rolls_get_strength :: proc(self: ^Unit_Power_Strength_And_Rolls) -> i32 {
	return self.strength_and_rolls.strength
}

unit_power_strength_and_rolls_get_rolls :: proc(self: ^Unit_Power_Strength_And_Rolls) -> i32 {
	return self.strength_and_rolls.rolls
}

unit_power_strength_and_rolls_builder :: proc() -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	return unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_new()
}

unit_power_strength_and_rolls_to_builder :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	b := unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_new()
	b.power = self.power
	b.strength_and_rolls = self.strength_and_rolls
	b.unit = self.unit
	b.power_calculator = self.power_calculator
	b.choose_best_roll = self.choose_best_roll
	b.dice_sides = self.dice_sides
	return b
}

// Java: private UnitPowerStrengthAndRolls#update(StrengthValue, RollValue)
unit_power_strength_and_rolls_update :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
	new_strength: ^Strength_Value,
	new_rolls: ^Roll_Value,
) -> ^Unit_Power_Strength_And_Rolls {
	b := unit_power_strength_and_rolls_to_builder(self)
	b.strength_and_rolls = strength_and_rolls_new(new_strength, new_rolls)
	b.power = power_calculator_get_value(
		self.choose_best_roll,
		self.dice_sides,
		new_strength,
		new_rolls,
	)
	return unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_build(b)
}

// Java: UnitPowerStrengthAndRolls#toZero()
unit_power_strength_and_rolls_to_zero :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
) -> ^Unit_Power_Strength_And_Rolls {
	new_strength := strength_value_of(self.dice_sides, 0)
	new_rolls := roll_value_of(0)
	b := unit_power_strength_and_rolls_to_builder(self)
	b.strength_and_rolls = strength_and_rolls_new(new_strength, new_rolls)
	b.power = power_calculator_get_value(
		self.choose_best_roll,
		self.dice_sides,
		new_strength,
		new_rolls,
	)
	return unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_build(b)
}

// Java: UnitPowerStrengthAndRolls#subtractStrength(int)
unit_power_strength_and_rolls_subtract_strength :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
	strength_to_subtract: i32,
) -> ^Unit_Power_Strength_And_Rolls {
	cur_strength := strength_value_of(self.dice_sides, self.strength_and_rolls.strength)
	cur_rolls := roll_value_of(self.strength_and_rolls.rolls)
	new_strength := strength_value_add(cur_strength, -1 * strength_to_subtract)
	return unit_power_strength_and_rolls_update(self, new_strength, cur_rolls)
}

// Java: UnitPowerStrengthAndRolls#subtractRolls(int)
unit_power_strength_and_rolls_subtract_rolls :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
	rolls_to_subtract: i32,
) -> ^Unit_Power_Strength_And_Rolls {
	cur_strength := strength_value_of(self.dice_sides, self.strength_and_rolls.strength)
	cur_rolls := roll_value_of(self.strength_and_rolls.rolls)
	new_rolls := roll_value_add(cur_rolls, -1 * rolls_to_subtract)
	return unit_power_strength_and_rolls_update(self, cur_strength, new_rolls)
}

// Java: UnitPowerStrengthAndRolls#updateRolls(int)
unit_power_strength_and_rolls_update_rolls :: proc(
	self: ^Unit_Power_Strength_And_Rolls,
	new_rolls_value: i32,
) -> ^Unit_Power_Strength_And_Rolls {
	cur_strength := strength_value_of(self.dice_sides, self.strength_and_rolls.strength)
	cur_rolls := roll_value_of(self.strength_and_rolls.rolls)
	new_rolls := roll_value_to_value(cur_rolls, new_rolls_value)
	return unit_power_strength_and_rolls_update(self, cur_strength, new_rolls)
}
