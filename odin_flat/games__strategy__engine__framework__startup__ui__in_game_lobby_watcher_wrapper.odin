package game

In_Game_Lobby_Watcher_Wrapper :: struct {
	lobby_watcher: ^In_Game_Lobby_Watcher,
}

make_In_Game_Lobby_Watcher_Wrapper :: proc() -> In_Game_Lobby_Watcher_Wrapper {
	return In_Game_Lobby_Watcher_Wrapper{}
}

in_game_lobby_watcher_wrapper_get_game_id :: proc(self: ^In_Game_Lobby_Watcher_Wrapper) -> string {
	if self == nil || self.lobby_watcher == nil {
		return ""
	}
	return self.lobby_watcher.game_id
}
