package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProAi

Pro_Ai :: struct {
	using parent: Abstract_Pro_Ai,
}

// Static field on ProAi: shared across all ProAi instances.
@(private)
pro_ai_concurrent_calc: ^Concurrent_Battle_Calculator
