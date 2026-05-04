package game

Battle_Actions :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.BattleActions

// Java's BattleActions.getRemotePlayer default method may construct
// `new WeakAi(name)` and return it as a Player. In Odin, Weak_Ai does
// not embed the Player vtable directly, so we wrap a freshly-allocated
// Weak_Ai inside a small Player wrapper whose proc fields delegate to
// the AI's AbstractBasePlayer/AbstractAi behavior.

@(private = "file")
Weak_Ai_Player_Wrapper :: struct {
	using player: Player,
	ai:           ^Weak_Ai,
}

@(private = "file")
weak_ai_player_get_name :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.name
}

@(private = "file")
weak_ai_player_get_player_label :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.player_label
}

@(private = "file")
weak_ai_player_is_ai :: proc(self: ^Player) -> bool {
	return true
}

@(private = "file")
weak_ai_player_get_game_player :: proc(self: ^Player) -> ^Game_Player {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.game_player
}

@(private = "file")
weak_ai_player_initialize :: proc(
	self: ^Player,
	bridge: ^Player_Bridge,
	game_player: ^Game_Player,
) {
	w := cast(^Weak_Ai_Player_Wrapper)self
	w.ai.player_bridge = bridge
	w.ai.game_player = game_player
}

// games.strategy.triplea.delegate.battle.BattleActions#getRemotePlayer(
//     games.strategy.engine.data.GamePlayer,
//     games.strategy.engine.delegate.IDelegateBridge)
//
//   default Player getRemotePlayer(final GamePlayer player, final IDelegateBridge bridge) {
//     // if its the null player, return a do nothing proxy
//     if (player.isNull()) {
//       return new WeakAi(player.getName());
//     }
//     return bridge.getRemotePlayer(player);
//   }
battle_actions_get_remote_player :: proc(
	self: ^Battle_Actions,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) -> ^Player {
	if game_player_is_null(player) {
		w := new(Weak_Ai_Player_Wrapper)
		w.ai = weak_ai_new(player.name)
		w.get_name = weak_ai_player_get_name
		w.get_player_label = weak_ai_player_get_player_label
		w.is_ai = weak_ai_player_is_ai
		w.get_game_player = weak_ai_player_get_game_player
		w.initialize = weak_ai_player_initialize
		return &w.player
	}
	return i_delegate_bridge_get_remote_player(bridge, player)
}
