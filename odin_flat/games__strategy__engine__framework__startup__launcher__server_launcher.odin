package game

SERVER_LAUNCHER_RELAY_SERVER_PORT :: 6000

Server_Launcher :: struct {
	using parent:                              I_Launcher,
	game_data:                                 ^Game_Data,
	game_selector_model:                       ^Game_Selector_Model,
	launch_action:                             ^Launch_Action,
	client_count:                              i32,
	messengers:                                ^Messengers,
	player_listing:                            ^Player_Listing,
	remote_players:                            map[string]^I_Node,
	server_model:                              ^Server_Model,
	server_game:                               ^Server_Game,
	server_ready:                              ^Server_Launcher_Server_Ready,
	error_latch:                               ^Count_Down_Latch,
	is_launching:                              bool,
	abort_launch:                              bool,
	game_stopped:                              bool,
	observers_that_tried_to_join_during_startup: [dynamic]^I_Node,
	in_game_lobby_watcher:                     ^In_Game_Lobby_Watcher_Wrapper,
	game_relay_server:                         ^Game_Relay_Server,
}

