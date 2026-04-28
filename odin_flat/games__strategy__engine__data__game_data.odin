package game

// games.strategy.engine.data.GameData
//
// Root of the game state. Every collection is owned by Game_Data and stored
// behind a pointer so other structs can reference Game_Data freely.

// Uuid: 16 raw bytes (Java UUID.toString() unhex'd by json_loader.string_to_uuid).
Uuid :: [16]u8

Game_Data :: struct {
	game_name:              string,
	dice_sides:             i32,
	sequence:               ^Game_Sequence,
	resource_list:          ^Resource_List,
	unit_type_list:         ^Unit_Type_List,
	player_list:            ^Player_List,
	game_map:               ^Game_Map,
	units_list:             ^Units_List,
	alliances:              ^Alliance_Tracker,
	properties:             ^Game_Properties,
	relationships:          ^Relationship_Tracker,
	relationship_type_list: ^Relationship_Type_List,
}
