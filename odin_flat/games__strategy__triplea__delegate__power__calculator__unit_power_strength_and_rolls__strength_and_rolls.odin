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
