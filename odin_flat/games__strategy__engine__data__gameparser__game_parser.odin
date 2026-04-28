package game

Game_Parser :: struct {
	data:                              ^Game_Data,
	xml_uri:                           string,
	xml_game_element_mapper:           ^Xml_Game_Element_Mapper,
	variables:                         ^Game_Data_Variables,
	engine_version:                    ^Version,
	collect_attachment_order_and_values: bool,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.gameparser.GameParser

