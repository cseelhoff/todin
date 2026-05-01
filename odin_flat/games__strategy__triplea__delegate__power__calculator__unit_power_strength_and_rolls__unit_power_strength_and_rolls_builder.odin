package game

// Lombok @Builder for UnitPowerStrengthAndRolls. Mirrors the fields of
// games.strategy.triplea.delegate.power.calculator.UnitPowerStrengthAndRolls.
Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder :: struct {
	power:              i32,
	strength_and_rolls: ^Strength_And_Rolls,
	unit:               ^Unit,
	power_calculator:   ^Power_Calculator,
	choose_best_roll:   bool,
	dice_sides:         i32,
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_new :: proc() -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self := new(Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder)
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, power: i32) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.power = power
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_strength_and_rolls :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, strength_and_rolls: ^Strength_And_Rolls) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.strength_and_rolls = strength_and_rolls
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_unit :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, unit: ^Unit) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.unit = unit
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_power_calculator :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, power_calculator: ^Power_Calculator) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.power_calculator = power_calculator
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_choose_best_roll :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, choose_best_roll: bool) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.choose_best_roll = choose_best_roll
	return self
}

unit_power_strength_and_rolls_unit_power_strength_and_rolls_builder_dice_sides :: proc(self: ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder, dice_sides: i32) -> ^Unit_Power_Strength_And_Rolls_Unit_Power_Strength_And_Rolls_Builder {
	self.dice_sides = dice_sides
	return self
}

