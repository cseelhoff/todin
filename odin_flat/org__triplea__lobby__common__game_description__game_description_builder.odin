package game

Game_Description_Builder :: struct {
	hosted_by:       ^I_Node,
	start_date_time: Instant,
	game_name:       string,
	player_count:    i32,
	round:           i32,
	status:          Game_Description_Game_Status,
	comment:         string,
	passworded:      bool,
}

