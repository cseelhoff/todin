package game

// Java owners covered by this file:
//   - games.strategy.triplea.util.TuvCostsCalculator

Tuv_Costs_Calculator :: struct {
	costs_all:        map[^Unit_Type]i32,
	costs_per_player: map[^Game_Player]map[^Unit_Type]i32,
}

