package game

// Java owners covered by this file:
//   - games.strategy.triplea.util.TuvCostsCalculator

Tuv_Costs_Calculator :: struct {
	costs_all:        map[^Unit_Type]i32,
	costs_per_player: map[^Game_Player]map[^Unit_Type]i32,
}

tuv_costs_calculator_new :: proc() -> ^Tuv_Costs_Calculator {
	self := new(Tuv_Costs_Calculator)
	self.costs_per_player = make(map[^Game_Player]map[^Unit_Type]i32)
	// costs_all is left as nil map (Java: @Nullable, lazily set)
	return self
}

// Lambda: differentCosts.computeIfAbsent(ut, key -> new ArrayList<>())
tuv_costs_calculator_lambda_get_costs_for_tuv_for_all_players_merged_and_averaged_0 :: proc(
	key: ^Unit_Type,
) -> [dynamic]i32 {
	return make([dynamic]i32)
}

