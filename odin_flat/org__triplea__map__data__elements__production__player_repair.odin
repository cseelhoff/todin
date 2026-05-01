package game

Production_Player_Repair :: struct {
	player:   string,
	frontier: string,
}

production_player_repair_get_frontier :: proc(self: ^Production_Player_Repair) -> string {
	return self.frontier
}

production_player_repair_get_player :: proc(self: ^Production_Player_Repair) -> string {
	return self.player
}

