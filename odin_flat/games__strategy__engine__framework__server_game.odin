package game

import "core:strings"

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

server_game_is_game_sequence_running :: proc(self: ^Server_Game) -> bool {
	return !self.delegate_execution_stopped
}

server_game_is_or_are :: proc(self: ^Server_Game, player_name: string) -> string {
	if strings.has_suffix(player_name, "s") ||
	   strings.has_suffix(player_name, "ese") ||
	   strings.has_suffix(player_name, "ish") {
		return "are"
	}
	return "is"
}


server_game_set_random_source :: proc(self: ^Server_Game, random_source: ^I_Random_Source) {
        self.random_source = random_source
        self.delegate_random_source = nil
}
