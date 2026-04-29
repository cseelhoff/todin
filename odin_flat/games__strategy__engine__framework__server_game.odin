package game

Server_Game :: struct {
	using abstract_game: Abstract_Game,
	random_stats:                       ^Random_Stats,
	random_source:                      ^I_Random_Source,
	delegate_random_source:             ^I_Random_Source,
	delegate_execution_manager:         ^Delegate_Execution_Manager,
	in_game_lobby_watcher:              ^In_Game_Lobby_Watcher_Wrapper,
	need_to_initialize:                 bool,
	launch_action:                      ^Launch_Action,
	delegate_autosaves_enabled:         bool,
	delegate_execution_stopped_latch:   ^Count_Down_Latch,
	delegate_execution_stopped:         bool,
	stop_game_on_delegate_execution_stop: bool,
}

