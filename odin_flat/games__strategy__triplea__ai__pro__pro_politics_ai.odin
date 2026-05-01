package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProPoliticsAi

// Pro politics AI.
Pro_Politics_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_politics_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Politics_Ai {
	self := new(Pro_Politics_Ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

