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

