package game

// games.strategy.engine.data.GameData
//
// Root of the game state. Every collection is owned by Game_Data and stored
// behind a pointer so other structs can reference Game_Data freely.

// Uuid: 16 raw bytes (Java UUID.toString() unhex'd by json_loader.string_to_uuid).
Uuid :: [16]u8

Game_Data :: struct {
	using game_state:               Game_State,
	game_name:                      string,
	game_version:                   ^Version,
	dice_sides:                     i32,
	force_in_swing_event_thread:    bool,
	alliances:                      ^Alliance_Tracker,
	relationships:                  ^Relationship_Tracker,
	game_map:                       ^Game_Map,
	player_list:                    ^Player_List,
	production_frontier_list:       ^Production_Frontier_List,
	production_rule_list:           ^Production_Rule_List,
	repair_frontier_list:           ^Repair_Frontier_List,
	repair_rules:                   ^Repair_Rules,
	resource_list:                  ^Resource_List,
	sequence:                       ^Game_Sequence,
	unit_type_list:                 ^Unit_Type_List,
	relationship_type_list:         ^Relationship_Type_List,
	properties:                     ^Game_Properties,
	units_list:                     ^Units_List,
	technology_frontier:            ^Technology_Frontier,
	loader:                         ^I_Game_Loader,
	territory_effect_list:          map[string]^Territory_Effect,
	battle_records_list:            ^Battle_Records_List,
	territory_listeners:            [dynamic]^Territory_Listener,
	data_change_listeners:          [dynamic]^Game_Data_Change_Listener,
	delegates:                      map[string]^I_Delegate,
	game_history:                   ^History,
	state:                          ^Game_Data_State,
	attachment_order_and_values:    [dynamic]^Tuple(^I_Attachment, [dynamic]^Tuple(string, string)),
	game_data_event_listeners:      ^Game_Data_Event_Listeners,
}

// Nested interface GameData.Unlocker (extends java.io.Closeable; no fields).
Unlocker :: struct {}
