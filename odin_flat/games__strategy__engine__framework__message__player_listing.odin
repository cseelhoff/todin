package game

Player_Listing :: struct {
	player_to_node_listing:                   map[string]string,
	players_enabled_listing:                  map[string]bool,
	local_player_types:                       map[string]string,
	players_allowed_to_be_disabled:           [dynamic]string,
	game_name:                                string,
	game_round:                               string,
	player_names_and_alliances_in_turn_order: map[string]map[string]struct{},
}

