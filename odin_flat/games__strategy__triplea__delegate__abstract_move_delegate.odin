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

// games.strategy.triplea.delegate.AbstractMoveDelegate#<init>()
// Java's implicit no-arg constructor. Mirrors the field initializer
// `movesToUndo = new ArrayList<>()`; tempMovePerformer defaults to
// nil. The embedded Base_Triple_A_Delegate / Abstract_Delegate slots
// zero-initialize, matching Java's superclass implicit init.
abstract_move_delegate_new :: proc() -> ^Abstract_Move_Delegate {
	self := new(Abstract_Move_Delegate)
	self.moves_to_undo = make([dynamic]^Undoable_Move)
	return self
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#getRouteUsedToMoveInto(games.strategy.engine.data.Unit,games.strategy.engine.data.Territory)
// Instance form of the static three-arg sibling above. Suffix `_1`
// disambiguates the overload (project convention; see
// territory_effect_attachment_get_1).
abstract_move_delegate_get_route_used_to_move_into_1 :: proc(self: ^Abstract_Move_Delegate, unit: ^Unit, end: ^Territory) -> ^Route {
	return abstract_move_delegate_get_route_used_to_move_into(self.moves_to_undo, unit, end)
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#saveState()
// Java returns `Serializable`; the concrete type is always
// AbstractMoveExtendedDelegateState. The Odin port returns the
// concrete pointer. `super_state` is stored as rawptr so a
// Base_Delegate_State pointer can be packed in.
abstract_move_delegate_save_state :: proc(self: ^Abstract_Move_Delegate) -> ^Abstract_Move_Extended_Delegate_State {
	state := abstract_move_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.moves_to_undo = self.moves_to_undo
	state.temp_move_performer = self.temp_move_performer
	return state
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

