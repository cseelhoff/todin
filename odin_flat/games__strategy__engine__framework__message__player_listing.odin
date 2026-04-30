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

make_Player_Listing :: proc(
	player_to_node_listing: map[string]string,
	players_enabled_listing: map[string]bool,
	local_player_types: map[string]string,
	game_name: string,
	game_round: string,
	players_allowed_to_be_disabled: [dynamic]string,
	player_names_and_alliances_in_turn_order: map[string]map[string]struct{},
) -> Player_Listing {
	return Player_Listing{
		player_to_node_listing                   = player_to_node_listing,
		players_enabled_listing                  = players_enabled_listing,
		local_player_types                       = local_player_types,
		players_allowed_to_be_disabled           = players_allowed_to_be_disabled,
		game_name                                = game_name,
		game_round                               = game_round,
		player_names_and_alliances_in_turn_order = player_names_and_alliances_in_turn_order,
	}
}

