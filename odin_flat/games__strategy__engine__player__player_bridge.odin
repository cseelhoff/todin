package game

Player_Bridge :: struct {
	game:             ^IGame,
	step_name:        string,
	current_delegate: string,
}

player_bridge_get_step_name :: proc(self: ^Player_Bridge) -> string {
	return self.step_name
}

// games.strategy.engine.player.PlayerBridge#getGameData()
player_bridge_get_game_data :: proc(self: ^Player_Bridge) -> ^Game_Data {
	return i_game_get_data(self.game)
}

// games.strategy.engine.player.PlayerBridge#isGameOver()
player_bridge_is_game_over :: proc(self: ^Player_Bridge) -> bool {
	return i_game_is_game_over(self.game)
}

// games.strategy.engine.player.PlayerBridge#getRemoteThatChecksForGameOver(IRemote)
// Java wraps `implementor` in a JDK dynamic proxy whose only job is to convert
// RemoteNotFoundException / post-game-over invocation failures into
// GameOverException. The Odin port has no exceptions and no reflection, so the
// proxy is a semantic no-op — return the implementor directly.
player_bridge_get_remote_that_checks_for_game_over :: proc(self: ^Player_Bridge, implementor: ^I_Remote) -> ^I_Remote {
	return implementor
}
