package game

Two_If_By_Sea_End_Turn_Delegate :: struct {
	using base: Abstract_End_Turn_Delegate,
	game_over:  bool,
}


// Stub: not on WW2v5 AI test path.
two_if_by_sea_end_turn_delegate_new :: proc() -> ^Two_If_By_Sea_End_Turn_Delegate {
	return new(Two_If_By_Sea_End_Turn_Delegate)
}
