package game

// Anonymous IExecutable #2 (fireAa) inside MovePerformer.execute(...).
// Captures effectively-final locals `route`, `units` from the enclosing
// method, plus the outer MovePerformer instance (for fields
// `airTransportDependents` and `arrivingUnits`).
Move_Performer_2 :: struct {
	using i_executable: I_Executable,
	outer:              ^Move_Performer,
	route:              ^Route,
	units:              [dynamic]^Unit,
}

