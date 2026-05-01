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

