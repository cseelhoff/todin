package game

Xml_Player_List_Player :: struct {
	name:            string,
	optional:        bool,
	can_be_disabled: bool,
	default_type:    string,
	is_hidden:       bool,
}

xml_player_list_player_get_name :: proc(self: ^Xml_Player_List_Player) -> string {
	return self.name
}

xml_player_list_player_get_optional :: proc(self: ^Xml_Player_List_Player) -> bool {
	return self.optional
}

xml_player_list_player_get_can_be_disabled :: proc(self: ^Xml_Player_List_Player) -> bool {
	return self.can_be_disabled
}

xml_player_list_player_get_default_type :: proc(self: ^Xml_Player_List_Player) -> string {
	return self.default_type
}

xml_player_list_player_get_is_hidden :: proc(self: ^Xml_Player_List_Player) -> bool {
	return self.is_hidden
}
