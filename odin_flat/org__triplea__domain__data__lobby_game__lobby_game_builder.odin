package game

Lobby_Game_Builder :: struct {
	host_address:             string,
	host_port:                i32,
	host_name:                string,
	map_name:                 string,
	player_count:             i32,
	game_round:               i32,
	epoch_milli_time_started: i64,
	passworded:               bool,
	status:                   string,
	comments:                 string,
}
