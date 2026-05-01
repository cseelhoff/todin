package game

Xml_Player_List_Alliance :: struct {
	player:   string,
	alliance: string,
}

xml_player_list_alliance_get_player :: proc(self: ^Xml_Player_List_Alliance) -> string {
	return self.player
}

xml_player_list_alliance_get_alliance :: proc(self: ^Xml_Player_List_Alliance) -> string {
	return self.alliance
}

