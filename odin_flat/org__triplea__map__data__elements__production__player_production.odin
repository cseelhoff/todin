package game

Production_Player_Production :: struct {
	player:   string,
	frontier: string,
}

production_player_production_get_frontier :: proc(self: ^Production_Player_Production) -> string {
	return self.frontier
}

production_player_production_get_player :: proc(self: ^Production_Player_Production) -> string {
	return self.player
}

