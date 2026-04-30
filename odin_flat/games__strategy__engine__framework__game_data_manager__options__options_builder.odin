package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataManager$Options$OptionsBuilder

Game_Data_Manager_Options_Options_Builder :: struct {
	with_delegates:           bool,
	with_history:             bool,
	with_attachment_xml_data: bool,
}

make_Game_Data_Manager_Options_Options_Builder :: proc() -> Game_Data_Manager_Options_Options_Builder {
	return Game_Data_Manager_Options_Options_Builder{}
}

game_data_manager_options_options_builder_with_attachment_xml_data :: proc(self: ^Game_Data_Manager_Options_Options_Builder, with_attachment_xml_data: bool) -> ^Game_Data_Manager_Options_Options_Builder {
	self.with_attachment_xml_data = with_attachment_xml_data
	return self
}

game_data_manager_options_options_builder_with_delegates :: proc(self: ^Game_Data_Manager_Options_Options_Builder, with_delegates: bool) -> ^Game_Data_Manager_Options_Options_Builder {
	self.with_delegates = with_delegates
	return self
}

game_data_manager_options_options_builder_with_history :: proc(self: ^Game_Data_Manager_Options_Options_Builder, with_history: bool) -> ^Game_Data_Manager_Options_Options_Builder {
	self.with_history = with_history
	return self
}

