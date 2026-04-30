package game

Abstract_Move_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	moves_to_undo: [dynamic]^Undoable_Move,
	temp_move_performer: ^Move_Performer,
}

Abstract_Move_Delegate_Move_Type :: enum {
	DEFAULT,
	SPECIAL,
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#getRemoteType()
// Java returns `Class<IMoveDelegate>`; Odin mirrors IDelegate#getRemoteType
// and returns the corresponding `typeid`.
abstract_move_delegate_get_remote_type :: proc(self: ^Abstract_Move_Delegate) -> typeid {
	return I_Move_Delegate
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#lambda$updateUndoableMoveIndexes$0(int)
// Body of `i -> movesToUndo.get(i).setIndex(i)` from updateUndoableMoveIndexes.
abstract_move_delegate_lambda_update_undoable_move_indexes_0 :: proc(self: ^Abstract_Move_Delegate, i: i32) {
	move := self.moves_to_undo[i]
	abstract_undoable_move_set_index(&move.abstract_undoable_move, i)
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#updateUndoableMoveIndexes()
// Reassigns the `index` field of every undoable move to its current list position.
abstract_move_delegate_update_undoable_move_indexes :: proc(self: ^Abstract_Move_Delegate) {
	n := i32(len(self.moves_to_undo))
	for i: i32 = 0; i < n; i += 1 {
		abstract_move_delegate_lambda_update_undoable_move_indexes_0(self, i)
	}
}

