package game

Lobby_Watcher_Keep_Alive_Task_Builder :: struct {
	game_id:           string,
	game_id_setter:    proc(_: string),
	keep_alive_sender: proc(_: string) -> bool,
	game_poster:       proc() -> ^Game_Posting_Response,
}

lobby_watcher_keep_alive_task_builder_game_id :: proc(
	self: ^Lobby_Watcher_Keep_Alive_Task_Builder,
	game_id: string,
) -> ^Lobby_Watcher_Keep_Alive_Task_Builder {
	self.game_id = game_id
	return self
}

lobby_watcher_keep_alive_task_builder_game_id_setter :: proc(
	self: ^Lobby_Watcher_Keep_Alive_Task_Builder,
	game_id_setter: proc(_: string),
) -> ^Lobby_Watcher_Keep_Alive_Task_Builder {
	self.game_id_setter = game_id_setter
	return self
}

lobby_watcher_keep_alive_task_builder_keep_alive_sender :: proc(
	self: ^Lobby_Watcher_Keep_Alive_Task_Builder,
	keep_alive_sender: proc(_: string) -> bool,
) -> ^Lobby_Watcher_Keep_Alive_Task_Builder {
	self.keep_alive_sender = keep_alive_sender
	return self
}

lobby_watcher_keep_alive_task_builder_game_poster :: proc(
	self: ^Lobby_Watcher_Keep_Alive_Task_Builder,
	game_poster: proc() -> ^Game_Posting_Response,
) -> ^Lobby_Watcher_Keep_Alive_Task_Builder {
	self.game_poster = game_poster
	return self
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.ui.LobbyWatcherKeepAliveTask$LobbyWatcherKeepAliveTaskBuilder

make_Lobby_Watcher_Keep_Alive_Task_Lobby_Watcher_Keep_Alive_Task_Builder :: proc() -> Lobby_Watcher_Keep_Alive_Task_Builder {
	return Lobby_Watcher_Keep_Alive_Task_Builder{}
}

