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

// games.strategy.triplea.ai.pro.ProScrambleAi#lambda$scrambleUnitsQuery$0(Territory, Unit)
// Java:
//   o -> ProBattleUtils.estimateStrength(scrambleTo, List.of(o), List.of(), false)
// Comparator key inside scrambleUnitsQuery; captured `scrambleTo` is supplied
// as the leading parameter per Java lambda desugaring. Returns the estimated
// defensive strength of just `o` at `scramble_to`.
pro_scramble_ai_lambda_scramble_units_query_0 :: proc(scramble_to: ^Territory, o: ^Unit) -> f64 {
	one_unit: [dynamic]^Unit
	append(&one_unit, o)
	empty_units: [dynamic]^Unit
	return pro_battle_utils_estimate_strength(scramble_to, one_unit, empty_units, false)
}

