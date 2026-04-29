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
