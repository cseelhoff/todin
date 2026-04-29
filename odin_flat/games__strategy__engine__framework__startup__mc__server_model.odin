package game

// Java owner: games.strategy.engine.framework.startup.mc.ServerModel
// Phase A: type fields only.

Server_Model :: struct {
	using observable:                         Observable,
	object_stream_factory:                    ^Game_Object_Stream_Factory,
	server_messenger:                         ^Server_Messenger,
	messengers:                               ^Messengers,
	data:                                     ^Game_Data,
	players_to_node_listing:                  map[string]string,
	players_to_nodes_mapping_persisted:       bool,
	players_enabled_listing:                  map[string]bool,
	players_allowed_to_be_disabled:           map[string]struct{},
	player_names_and_alliances_in_turn_order: map[string]map[string]struct{},
	remote_model_listener:                    ^I_Remote_Model_Listener,
	game_selector_model:                      ^Game_Selector_Model,
	launch_action:                            ^Launch_Action,
	chat_model:                               ^Chat_Model,
	chat_controller:                          ^Chat_Controller,
	local_player_types:                       map[string]^Player_Types_Type,
	server_launcher:                          ^Server_Launcher,
	remove_connections_latch:                 ^Count_Down_Latch,
	game_selector_observer:                   proc(observable: ^Observable, value: rawptr),
	lobby_watcher_thread:                     ^Lobby_Watcher_Thread,
	game_to_lobby_connection:                 ^Game_To_Lobby_Connection,
}
