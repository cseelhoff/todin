package game

Move_Performer :: struct {
	move_delegate:           ^Abstract_Move_Delegate,
	bridge:                  ^IDelegate_Bridge,
	player:                  ^Game_Player,
	aa_in_move_util:         ^Aa_In_Move_Util,
	execution_stack:         ^Execution_Stack,
	current_move:            ^Undoable_Move,
	air_transport_dependents: map[^Unit][dynamic]^Unit,
	arriving_units:          [dynamic]^Unit,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MovePerformer

