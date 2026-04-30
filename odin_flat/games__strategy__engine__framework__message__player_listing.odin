package game

import "core:fmt"

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

// games.strategy.engine.framework.message.PlayerListing#getLocalPlayerTypeMap
// Java: localPlayerTypes.entrySet().stream()
//   .collect(Collectors.toMap(Entry::getKey, e -> playerTypes.fromLabel(e.getValue())));
// Resolves each stored label string back to its ^Player_Types_Type via
// player_types_from_label and returns the new map.
player_listing_get_local_player_type_map :: proc(
	self: ^Player_Listing,
	player_types: ^Player_Types,
) -> map[string]^Player_Types_Type {
	result := make(map[string]^Player_Types_Type)
	for k, v in self.local_player_types {
		result[k] = player_types_from_label(player_types, v)
	}
	return result
}

// Java synthetic lambda: PlayerListing#lambda$doPreGameStartDataModifications$4(GamePlayer).
// Source: `gameData.preGameDisablePlayers(p -> !playersEnabledListing.get(p.getName()))`.
// Captures `playersEnabledListing` — under the rawptr-ctx convention `self`
// is passed as the userdata pointer (call sites cast ^Player_Listing as rawptr).
player_listing_lambda_do_pre_game_start_data_modifications_4 :: proc(
	self: ^Player_Listing,
	p: ^Game_Player,
) -> bool {
	return !self.players_enabled_listing[p.named.base.name]
}

// Java synthetic lambda: PlayerListing#lambda$new$1(Map.Entry).
// Source: the `e -> e.getValue().getLabel()` value-mapper inside the
// constructor's `Collectors.toMap(Entry::getKey, e -> e.getValue().getLabel())`
// over `localPlayerTypes` (Map<String, PlayerTypes.Type>). No Map_Entry shim
// exists in odin_flat/, so this takes the entry's value (^Player_Types_Type)
// directly per the convention noted in the dispatch prompt.
player_listing_lambda_new_1 :: proc(value: ^Player_Types_Type) -> string {
	return value.label
}


// Java synthetic lambda: PlayerListing#lambda$new$2(Collection, Collection).
// Source: the merge function passed to `Collectors.toMap(..., (u, v) -> {
//   throw new IllegalStateException(String.format("Duplicate key %s", u)); })`
// inside the constructor over `playerNamesAndAlliancesInTurnOrder`. Since the
// upstream key is unique per Map.Entry this branch is only ever reached on a
// programmer error, so it panics like the Java IllegalStateException.
player_listing_lambda_new_2 :: proc(u: [dynamic]string, v: [dynamic]string) -> [dynamic]string {
	panic(fmt.tprintf("Duplicate key %v", u))
}
