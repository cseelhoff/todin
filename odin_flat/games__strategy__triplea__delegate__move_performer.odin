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

move_performer_lambda_mark_transports_movement_0 :: proc(u: ^Unit) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// games.strategy.triplea.delegate.MovePerformer#<init>()
//
//   MovePerformer() {}
//   private final ExecutionStack executionStack = new ExecutionStack();
move_performer_new :: proc() -> ^Move_Performer {
	self := new(Move_Performer)
	self.execution_stack = execution_stack_new()
	return self
}

// games.strategy.triplea.delegate.MovePerformer#getRemotePlayer(games.strategy.engine.data.GamePlayer)
//
//   return bridge.getRemotePlayer(gamePlayer);
move_performer_get_remote_player :: proc(self: ^Move_Performer, game_player: ^Game_Player) -> ^Player {
	return i_delegate_bridge_get_remote_player(self.bridge, game_player)
}

