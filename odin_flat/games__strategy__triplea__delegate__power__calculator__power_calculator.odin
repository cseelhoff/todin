package game

Power_Calculator :: struct {
	strength_calculator: ^Strength_Calculator,
	roll_calculator:     ^Roll_Calculator,
	choose_best_roll:    proc(unit: ^Unit) -> bool,
	get_dice_sides:      proc(unit: ^Unit) -> i32,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.PowerCalculator

