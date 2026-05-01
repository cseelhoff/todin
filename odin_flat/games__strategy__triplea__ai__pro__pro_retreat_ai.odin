package game

Pro_Retreat_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_retreat_ai_new :: proc(ai: ^Abstract_Pro_Ai, allocator := context.allocator) -> ^Pro_Retreat_Ai {
	self := new(Pro_Retreat_Ai, allocator)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

