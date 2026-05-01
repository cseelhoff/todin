package game

// Java owner: games.strategy.engine.player.Player (interface)
//
// Modeled with proc-typed fields installed by concrete implementers,
// matching the convention used elsewhere for pure-callback Java
// interfaces (e.g. ChatMessageListener, IChatChannel). Dispatch procs
// (`player_*`) are the public entry points.

Player :: struct {
	using i_remote:  I_Remote,
	get_game_player: proc(self: ^Player) -> ^Game_Player,
	is_ai:           proc(self: ^Player) -> bool,
}

// games.strategy.engine.player.Player#getGamePlayer()
player_get_game_player :: proc(self: ^Player) -> ^Game_Player {
	return self.get_game_player(self)
}

// games.strategy.engine.player.Player#isAi()
player_is_ai :: proc(self: ^Player) -> bool {
	return self.is_ai(self)
}

