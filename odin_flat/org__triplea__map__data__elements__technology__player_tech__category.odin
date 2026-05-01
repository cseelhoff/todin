package game

Technology_Player_Tech_Category :: struct {
	name:  string,
	techs: [dynamic]^Technology_Player_Tech_Category_Tech,
}

technology_player_tech_category_get_name :: proc(self: ^Technology_Player_Tech_Category) -> string {
	return self.name
}

technology_player_tech_category_get_techs :: proc(self: ^Technology_Player_Tech_Category) -> [dynamic]^Technology_Player_Tech_Category_Tech {
	return self.techs
}

