package game

Abstract_Move_Extended_Delegate_State :: struct {
	super_state:         rawptr,
	moves_to_undo:       [dynamic]^Undoable_Move,
	temp_move_performer: ^Move_Performer,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.AbstractMoveExtendedDelegateState

