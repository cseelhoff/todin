package game

Xml_Player_List :: struct {
	players:   [dynamic]^Xml_Player_List_Player,
	alliances: [dynamic]^Xml_Player_List_Alliance,
}

xml_player_list_get_players :: proc(self: ^Xml_Player_List) -> [dynamic]^Xml_Player_List_Player {
	return self.players
}

xml_player_list_get_alliances :: proc(self: ^Xml_Player_List) -> [dynamic]^Xml_Player_List_Alliance {
	return self.alliances
}

