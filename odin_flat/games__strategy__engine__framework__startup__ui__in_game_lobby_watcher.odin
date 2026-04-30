package game

In_Game_Lobby_Watcher :: struct {
	is_shutdown:                  bool,
	game_id:                      string,
	game_selector_model:          ^Game_Selector_Model,
	game_selector_model_observer: Observer_Callback,
	game:                         ^I_Game,
	game_description:             ^Game_Description,
	connection_change_listener:   ^I_Connection_Change_Listener,
	human_player:                 bool,
	game_to_lobby_connection:     ^Game_To_Lobby_Connection,
	server_messenger:             ^I_Server_Messenger,
	keep_alive_timer:             ^Scheduled_Timer,
}

in_game_lobby_watcher_clean_up_game_model_listener :: proc(self: ^In_Game_Lobby_Watcher) {
	if self.game_selector_model != nil {
		observable_delete_observer(&self.game_selector_model.observable, self.game_selector_model_observer)
	}
}

in_game_lobby_watcher_get_game_id :: proc(self: ^In_Game_Lobby_Watcher) -> string {
	return self.game_id
}

in_game_lobby_watcher_is_active :: proc(self: ^In_Game_Lobby_Watcher) -> bool {
	return !self.is_shutdown
}

in_game_lobby_watcher_lambda_clean_up_game_model_listener_7 :: proc(self: ^In_Game_Lobby_Watcher, selector_model: ^Game_Selector_Model) {
	observable_delete_observer(&selector_model.observable, self.game_selector_model_observer)
}

in_game_lobby_watcher_lambda_new_1 :: proc(old: ^In_Game_Lobby_Watcher) -> ^I_Game {
	return old.game
}

in_game_lobby_watcher_lambda_new_2 :: proc(old: ^In_Game_Lobby_Watcher) -> ^Game_Description {
	return old.game_description
}

in_game_lobby_watcher_lambda_new_4 :: proc(self: ^In_Game_Lobby_Watcher, id: string) {
	self.game_id = id
}
