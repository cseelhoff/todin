package game

Lobby_Watcher_Thread :: struct {
	lobby_watcher:            ^In_Game_Lobby_Watcher_Wrapper,
	game_selector_model:      ^Game_Selector_Model,
	server_messenger:         ^I_Server_Messenger,
	watcher_thread_messaging: ^Watcher_Thread_Messaging,
}

lobby_watcher_thread_get_lobby_watcher :: proc(self: ^Lobby_Watcher_Thread) -> ^In_Game_Lobby_Watcher_Wrapper {
	return self.lobby_watcher
}
