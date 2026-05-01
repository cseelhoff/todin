package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.EndRoundDelegate

End_Round_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	game_over:    bool,
	winners:      [dynamic]^Game_Player,
}

// games.strategy.triplea.delegate.EndRoundDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
end_round_delegate_get_remote_type :: proc(self: ^End_Round_Delegate) -> typeid {
	return nil
}

