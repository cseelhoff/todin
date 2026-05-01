package game

Pro_Scramble_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_scramble_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Scramble_Ai {
	self := new(Pro_Scramble_Ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

