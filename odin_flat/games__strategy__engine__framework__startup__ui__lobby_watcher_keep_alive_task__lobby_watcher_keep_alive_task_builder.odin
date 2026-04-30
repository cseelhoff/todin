package game

Lobby_Watcher_Keep_Alive_Task_Builder :: struct {
	game_id:               string,
	game_id_setter:        proc(rawptr, string),
	game_id_setter_ctx:    rawptr,
	keep_alive_sender:     proc(rawptr, string) -> bool,
	keep_alive_sender_ctx: rawptr,
	game_poster:           proc(rawptr) -> ^Game_Posting_Response,
	game_poster_ctx:       rawptr,
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.ui.LobbyWatcherKeepAliveTask$LobbyWatcherKeepAliveTaskBuilder

make_Lobby_Watcher_Keep_Alive_Task_Lobby_Watcher_Keep_Alive_Task_Builder :: proc() -> Lobby_Watcher_Keep_Alive_Task_Builder {
	return Lobby_Watcher_Keep_Alive_Task_Builder{}
}

