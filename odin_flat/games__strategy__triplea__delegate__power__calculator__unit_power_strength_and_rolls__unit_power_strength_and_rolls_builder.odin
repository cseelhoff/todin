package game

// Lombok @Builder for UnitPowerStrengthAndRolls. Mirrors the fields of
// games.strategy.triplea.delegate.power.calculator.UnitPowerStrengthAndRolls.
Unit_Power_Strength_And_Rolls_Builder :: struct {
	power:              i32,
	strength_and_rolls: ^Strength_And_Rolls,
	unit:               ^Unit,
	power_calculator:   ^Power_Calculator,
	choose_best_roll:   bool,
	dice_sides:         i32,
}

