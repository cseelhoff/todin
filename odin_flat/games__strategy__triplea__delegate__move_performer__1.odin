package game

Move_Performer_1 :: struct {
	using parent: I_Executable,
	outer:        ^Move_Performer,
	route:        ^Route,
	units:        [dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MovePerformer$1

