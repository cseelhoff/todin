package game

Special_Move_Delegate :: struct {
	using abstract_move_delegate: Abstract_Move_Delegate,
	need_to_initialize: bool,
}

// games.strategy.triplea.delegate.SpecialMoveDelegate constructor.
// Implicit Java no-arg form; field initializer sets needToInitialize = true.
// Wires the `pus_already_lost` vtable slot to the constant-zero impl
// (Java: `public int pusAlreadyLost(Territory t) { return 0; }`).
special_move_delegate_new :: proc() -> ^Special_Move_Delegate {
	self := new(Special_Move_Delegate)
	self.moves_to_undo = make([dynamic]^Undoable_Move)
	self.need_to_initialize = true
	self.pus_already_lost = proc(_: ^Abstract_Move_Delegate, _: ^Territory) -> i32 {
		return 0
	}
	return self
}
