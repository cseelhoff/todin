package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.EndRoundDelegate

End_Round_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	game_over:    bool,
	winners:      [dynamic]^Game_Player,
}

