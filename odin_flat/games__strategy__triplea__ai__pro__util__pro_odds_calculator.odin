package game



Pro_Odds_Calculator :: struct {
	calc:    ^I_Battle_Calculator,
	stopped: bool,
}

pro_odds_calculator_new :: proc(calculator: ^I_Battle_Calculator) -> ^Pro_Odds_Calculator {
	self := new(Pro_Odds_Calculator)
	self.calc = calculator
	self.stopped = false
	return self
}

