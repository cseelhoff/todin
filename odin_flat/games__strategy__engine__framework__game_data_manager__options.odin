package game

Game_Data_Manager_Options :: struct {
	with_delegates:           bool,
	with_history:             bool,
	with_attachment_xml_data: bool,
}

make_Game_Data_Manager_Options :: proc(
	with_delegates: bool,
	with_history: bool,
	with_attachment_xml_data: bool,
) -> Game_Data_Manager_Options {
	return Game_Data_Manager_Options{
		with_delegates           = with_delegates,
		with_history             = with_history,
		with_attachment_xml_data = with_attachment_xml_data,
	}
}

game_data_manager_options_default_with_attachment_xml_data :: proc() -> bool {
	return false
}

game_data_manager_options_default_with_delegates :: proc() -> bool {
	return false
}

game_data_manager_options_default_with_history :: proc() -> bool {
	return false
}

game_data_manager_options_builder :: proc() -> ^Game_Data_Manager_Options_Options_Builder {
	b := new(Game_Data_Manager_Options_Options_Builder)
	b^ = make_Game_Data_Manager_Options_Options_Builder()
	return b
}

game_data_manager_options_for_save_game :: proc() -> ^Game_Data_Manager_Options {
	// Omit attachment data as it uses a lot of memory and is only needed for XML
	// exports, which now read it from the original XML instead.
	b := game_data_manager_options_builder()
	game_data_manager_options_options_builder_with_delegates(b, true)
	game_data_manager_options_options_builder_with_history(b, true)
	game_data_manager_options_options_builder_with_attachment_xml_data(b, false)
	return game_data_manager_options_options_builder_build(b)
}

game_data_manager_options_for_battle_calculator :: proc() -> ^Game_Data_Manager_Options {
	b := game_data_manager_options_builder()
	return game_data_manager_options_options_builder_build(b)
}

