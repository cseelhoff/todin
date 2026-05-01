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


