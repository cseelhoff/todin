package game

Technology_Player_Tech_Category_Tech :: struct {
	name: string,
}

technology_player_tech_category_tech_get_name :: proc(self: ^Technology_Player_Tech_Category_Tech) -> string {
	return self.name
}

