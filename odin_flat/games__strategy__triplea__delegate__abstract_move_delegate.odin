package game

import "core:slice"

Abstract_Move_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	moves_to_undo: [dynamic]^Undoable_Move,
	temp_move_performer: ^Move_Performer,
	// Vtable slot for the abstract `int pusAlreadyLost(Territory)`.
	// MoveDelegate wires this to its IntegerMap-backed lookup;
	// SpecialMoveDelegate wires it to a constant-zero proc.
	pus_already_lost: proc(self: ^Abstract_Move_Delegate, t: ^Territory) -> i32,
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

// games.strategy.triplea.delegate.AbstractMoveDelegate#pusAlreadyLost(Territory)
//   Vtable dispatch through the proc field. A nil slot models the
//   abstract default (no PU losses recorded), which matches
//   SpecialMoveDelegate's `return 0;` and any harness/stub path that
//   never installed a delegate.
abstract_move_delegate_pus_already_lost :: proc(self: ^Abstract_Move_Delegate, t: ^Territory) -> i32 {
	if self != nil && self.pus_already_lost != nil {
		return self.pus_already_lost(self, t)
	}
	return 0
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

// games.strategy.triplea.delegate.AbstractMoveDelegate#getBattleTracker(games.strategy.engine.data.GameData)
// Static helper: returns the BattleTracker owned by the GameData's BattleDelegate.
abstract_move_delegate_get_battle_tracker :: proc(data: ^Game_Data) -> ^Battle_Tracker {
	return battle_delegate_get_battle_tracker(game_data_get_battle_delegate(data))
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#getUnitsOwner(java.util.Collection)
// In edit mode (and given a non-empty unit collection), returns the owner of
// any one of the units; otherwise falls back to the delegate's current player.
abstract_move_delegate_get_units_owner :: proc(self: ^Abstract_Move_Delegate, units: [dynamic]^Unit) -> ^Game_Player {
	if len(units) == 0 || !edit_delegate_get_edit_mode(game_data_get_properties(i_delegate_bridge_get_data(self.bridge))) {
		return self.player
	}
	return unit_get_owner(units[0])
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#updateUndoableMoves(games.strategy.triplea.delegate.UndoableMove)
// Appends `current_move` to the undo list after wiring up its dependencies on
// the prior moves, then renumbers every move's index to its new position.
abstract_move_delegate_update_undoable_moves :: proc(self: ^Abstract_Move_Delegate, current_move: ^Undoable_Move) {
	undoable_move_initialize_dependencies(current_move, self.moves_to_undo)
	append(&self.moves_to_undo, current_move)
	abstract_move_delegate_update_undoable_move_indexes(self)
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#start()
// Calls super.start(); if a tempMovePerformer was suspended in a prior
// turn, re-bind it to this delegate, resume the in-progress move, then
// clear the slot.
abstract_move_delegate_start :: proc(self: ^Abstract_Move_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	if self.temp_move_performer != nil {
		move_performer_initialize(self.temp_move_performer, self)
		move_performer_resume(self.temp_move_performer)
		self.temp_move_performer = nil
	}
}

// games.strategy.triplea.delegate.AbstractMoveDelegate#end()
// Calls super.end() and clears the undoable-move list for the turn.
abstract_move_delegate_end :: proc(self: ^Abstract_Move_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	clear(&self.moves_to_undo)
}

