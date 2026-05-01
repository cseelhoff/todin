package game

import "core:slice"

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

// games.strategy.triplea.delegate.AbstractMoveDelegate#getRouteUsedToMoveInto(java.util.List,games.strategy.engine.data.Unit,games.strategy.engine.data.Territory)
// Static helper: walk the undoable-move list backwards and return the
// route of the most recent move that included `unit` and ended at `end`.
// Java's `Optional<Route>` collapses to a `^Route` (nil ≡ Optional.empty()).
abstract_move_delegate_get_route_used_to_move_into :: proc(undoable_moves: [dynamic]^Undoable_Move, unit: ^Unit, end: ^Territory) -> ^Route {
	for i := len(undoable_moves) - 1; i >= 0; i -= 1 {
		move := undoable_moves[i]
		if !slice.contains(move.units[:], unit) {
			continue
		}
		route := undoable_move_get_route(move)
		if route_get_end(route) == end {
			return route
		}
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#loadState(java.io.Serializable)
// Restores the delegate from a previously saved Abstract_Move_Extended_Delegate_State.
// Skips overwriting `moves_to_undo` when the saved list is empty (mirrors the
// Java guard that protects undo state from being clobbered by a restore-from-undo).
abstract_move_delegate_load_state :: proc(self: ^Abstract_Move_Delegate, state: ^Abstract_Move_Extended_Delegate_State) {
	base_triple_a_delegate_load_state(&self.base_triple_a_delegate, (^Base_Delegate_State)(state.super_state))
	if state.moves_to_undo != nil {
		self.moves_to_undo = state.moves_to_undo
	}
	self.temp_move_performer = state.temp_move_performer
}

