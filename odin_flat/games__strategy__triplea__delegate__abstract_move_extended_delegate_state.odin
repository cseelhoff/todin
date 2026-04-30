package game

Abstract_Move_Extended_Delegate_State :: struct {
	super_state:         rawptr,
	moves_to_undo:       [dynamic]^Undoable_Move,
	temp_move_performer: ^Move_Performer,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.AbstractMoveExtendedDelegateState

abstract_move_extended_delegate_state_new :: proc() -> ^Abstract_Move_Extended_Delegate_State {
	s := new(Abstract_Move_Extended_Delegate_State)
	s.moves_to_undo = make([dynamic]^Undoable_Move)
	return s
}

