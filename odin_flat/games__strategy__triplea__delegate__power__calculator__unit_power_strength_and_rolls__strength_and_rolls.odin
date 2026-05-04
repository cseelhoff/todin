package game

Unit_Power_Strength_And_Rolls_Strength_And_Rolls :: struct {
	strength: ^Strength_Value,
	rolls:    ^Roll_Value,
}

unit_power_strength_and_rolls_strength_and_rolls_get_strength :: proc(self: ^Unit_Power_Strength_And_Rolls_Strength_And_Rolls) -> ^Strength_Value {
	return self.strength
}

unit_power_strength_and_rolls_strength_and_rolls_get_rolls :: proc(self: ^Unit_Power_Strength_And_Rolls_Strength_And_Rolls) -> ^Roll_Value {
	return self.rolls
}

// Java: UnitPowerStrengthAndRolls$StrengthAndRolls#<init>(StrengthValue, RollValue)
// If either argument is zero, both fields are stored as zero-valued; otherwise
// the supplied values are stored verbatim. Note: returns the package-level
// shim type `Strength_And_Rolls` (i32 fields) per the porting contract.
strength_and_rolls_new :: proc(strength: ^Strength_Value, rolls: ^Roll_Value) -> ^Strength_And_Rolls {
	self := new(Strength_And_Rolls)
	if strength_value_is_zero(strength) || roll_value_is_zero(rolls) {
		self.strength = 0
		self.rolls = 0
	} else {
		self.strength = strength_value_get_value(strength)
		self.rolls = roll_value_get_value(rolls)
	}
	return self
}

// Java: UnitPowerStrengthAndRolls$StrengthAndRolls#of(StrengthValue, RollValue)
// Lombok @Value(staticConstructor = "of"): public static factory that
// delegates to the private constructor's zero-normalisation logic.
unit_power_strength_and_rolls_strength_and_rolls_of :: proc(
	strength: ^Strength_Value,
	rolls: ^Roll_Value,
) -> ^Unit_Power_Strength_And_Rolls_Strength_And_Rolls {
	self := new(Unit_Power_Strength_And_Rolls_Strength_And_Rolls)
	if strength_value_is_zero(strength) || roll_value_is_zero(rolls) {
		self.strength = strength_value_to_value(strength, 0)
		self.rolls = roll_value_to_value(rolls, 0)
	} else {
		self.strength = strength
		self.rolls = rolls
	}
	return self
}
