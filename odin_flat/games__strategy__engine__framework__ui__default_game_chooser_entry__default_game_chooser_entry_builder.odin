package game

Default_Game_Chooser_Entry_Builder :: struct {
	installed_map: ^Installed_Map,
	game_name:     string,
}

make_Default_Game_Chooser_Entry_Default_Game_Chooser_Entry_Builder :: proc() -> Default_Game_Chooser_Entry_Builder {
	return Default_Game_Chooser_Entry_Builder{}
}

