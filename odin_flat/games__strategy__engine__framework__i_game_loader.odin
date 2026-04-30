package game

// Java owner: games.strategy.engine.framework.IGameLoader
//
// IGameLoader is a pure-callback interface (extends Serializable). Each
// abstract method is modeled as a proc-typed field; concrete
// implementers install their function at construction time. Dispatch
// procs (`i_game_loader_*`) are the public entry points.

I_Game_Loader :: struct {
	new_players: proc(self: ^I_Game_Loader, players: map[string]string) -> [dynamic]^Player,
	start_game:  proc(self: ^I_Game_Loader, game: ^I_Game, players: [dynamic]^Player, launch_action: ^Launch_Action, chat: ^Chat),
	shut_down:   proc(self: ^I_Game_Loader),
}

// games.strategy.engine.framework.IGameLoader#newPlayers(java.util.Map)
i_game_loader_new_players :: proc(self: ^I_Game_Loader, players: map[string]string) -> [dynamic]^Player {
	return self.new_players(self, players)
}

// games.strategy.engine.framework.IGameLoader#startGame(games.strategy.engine.framework.IGame,java.util.Set,games.strategy.engine.framework.startup.launcher.LaunchAction,games.strategy.engine.chat.Chat)
i_game_loader_start_game :: proc(self: ^I_Game_Loader, game: ^I_Game, players: [dynamic]^Player, launch_action: ^Launch_Action, chat: ^Chat) {
	self.start_game(self, game, players, launch_action, chat)
}

// games.strategy.engine.framework.IGameLoader#shutDown()
i_game_loader_shut_down :: proc(self: ^I_Game_Loader) {
	self.shut_down(self)
}

