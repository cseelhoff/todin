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

