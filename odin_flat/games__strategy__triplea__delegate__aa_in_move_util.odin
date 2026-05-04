package game

Aa_In_Move_Util :: struct {
	bridge:          ^I_Delegate_Bridge,
	player:          ^Game_Player,
	casualties:      [dynamic]^Unit,
	execution_stack: ^Execution_Stack,
}

// games.strategy.triplea.delegate.AaInMoveUtil#<init>()
aa_in_move_util_new :: proc() -> ^Aa_In_Move_Util {
	self := new(Aa_In_Move_Util)
	self.casualties = make([dynamic]^Unit)
	self.execution_stack = execution_stack_new()
	return self
}

// games.strategy.triplea.delegate.AaInMoveUtil#getData()
aa_in_move_util_get_data :: proc(self: ^Aa_In_Move_Util) -> ^Game_Data {
	return i_delegate_bridge_get_data(self.bridge)
}

// games.strategy.triplea.delegate.AaInMoveUtil#initialize(games.strategy.engine.delegate.IDelegateBridge)
aa_in_move_util_initialize :: proc(self: ^Aa_In_Move_Util, bridge: ^I_Delegate_Bridge) {
	self.bridge = bridge
	self.player = i_delegate_bridge_get_game_player(bridge)
}

// games.strategy.triplea.delegate.AaInMoveUtil#movingPlayer(java.util.Collection)
aa_in_move_util_moving_player :: proc(self: ^Aa_In_Move_Util, units: [dynamic]^Unit) -> ^Game_Player {
	for u in units {
		if u != nil && unit_is_owned_by(u, self.player) {
			return self.player
		}
	}
	for u in units {
		if u == nil {
			continue
		}
		owner := unit_get_owner(u)
		if owner != nil {
			return owner
		}
	}
	return player_list_get_null_player(game_data_get_player_list(game_player_get_data(self.player)))
}

// games.strategy.triplea.delegate.AaInMoveUtil#getBattleTracker()
aa_in_move_util_get_battle_tracker :: proc(self: ^Aa_In_Move_Util) -> ^Battle_Tracker {
	return battle_delegate_get_battle_tracker(game_data_get_battle_delegate(aa_in_move_util_get_data(self)))
}
