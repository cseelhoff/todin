package game

Random_Start_Delegate :: struct {
	using base: Base_Triple_A_Delegate,
	current_picking_player: ^Game_Player,
}

// games.strategy.triplea.delegate.RandomStartDelegate#<init>()
// Java's implicit no-arg constructor. The only declared field
// `currentPickingPlayer` has the Java initializer `= null`, which
// matches Odin's zero value for a pointer; embedded
// Base_Triple_A_Delegate is zero-initialized.
random_start_delegate_new :: proc() -> ^Random_Start_Delegate {
	self := new(Random_Start_Delegate)
	return self
}

