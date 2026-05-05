package game

// Java owner: games.strategy.triplea.delegate.NoPuEndTurnDelegate
// Pure subclass of EndTurnDelegate; no instance fields.
No_Pu_End_Turn_Delegate :: struct {
	using base: End_Turn_Delegate,
}


// Stub: not on WW2v5 AI test path.
no_pu_end_turn_delegate_new :: proc() -> ^No_Pu_End_Turn_Delegate {
	return new(No_Pu_End_Turn_Delegate)
}
