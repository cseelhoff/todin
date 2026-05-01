package game

Player_Bridge_Game_Over_Invocation_Handler :: struct {
	delegate: rawptr,
	game:     ^I_Game,
}

player_bridge_game_over_invocation_handler_new :: proc(delegate: rawptr, game: ^I_Game) -> ^Player_Bridge_Game_Over_Invocation_Handler {
	self := new(Player_Bridge_Game_Over_Invocation_Handler)
	self.delegate = delegate
	self.game = game
	return self
}

// Java owners covered by this file:
//   - games.strategy.engine.player.PlayerBridge$GameOverInvocationHandler

// games.strategy.engine.player.PlayerBridge$GameOverInvocationHandler#invoke(Object, Method, Object[])
// Java:
//   if (gameOver) throw new GameOverException("Game Over");
//   return method.invoke(implementor, args);
// The proxy is bypassed in player_bridge_get_remote_that_checks_for_game_over
// (which returns the implementor directly), so this is unreachable in the
// Odin harness. Reflection is dropped; we preserve only the gameOver gate.
player_bridge__game_over_invocation_handler_invoke :: proc(
	self:   ^Player_Bridge_Game_Over_Invocation_Handler,
	proxy:  rawptr,
	method: rawptr,
	args:   []rawptr,
) -> rawptr {
	_ = proxy
	_ = method
	_ = args
	if self.game != nil && i_game_is_game_over(self.game) {
		panic("Game Over")
	}
	return nil
}

