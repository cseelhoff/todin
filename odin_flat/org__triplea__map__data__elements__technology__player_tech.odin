package game

Technology_Player_Tech :: struct {
	player:     string,
	categories: [dynamic]^Technology_Player_Tech_Category,
}

technology_player_tech_get_categories :: proc(self: ^Technology_Player_Tech) -> [dynamic]^Technology_Player_Tech_Category {
	return self.categories
}

technology_player_tech_get_player :: proc(self: ^Technology_Player_Tech) -> string {
	return self.player
}
