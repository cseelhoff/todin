package game

import "core:fmt"
import "core:strings"

// games.strategy.triplea.delegate.GameStepPropertiesHelper
//
// Lombok @UtilityClass — instance struct only exists to mirror Java's class
// shape; all entry points are package-level procs.
Game_Step_Properties_Helper :: struct {}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#getPlayersFromProperty
//
// Java reads a colon-separated list of player names from the current step's
// property map (e.g. "Russians:Germans") and resolves each to a GamePlayer
// via PlayerList. If a name is missing from PlayerList the Java code logs a
// warning and skips it. An optional default player is unioned in regardless
// of whether the property is set.
game_step_properties_helper_get_players_from_property :: proc(
	game_data:      ^Game_Data,
	property_key:   string,
	default_player: ^Game_Player,
) -> map[^Game_Player]struct{} {
	players := make(map[^Game_Player]struct{})
	if default_player != nil {
		players[default_player] = struct{}{}
	}

	game_data_acquire_read_lock(game_data)
	step := game_sequence_get_step(game_data_get_sequence(game_data))
	props := game_step_get_properties(step)
	encoded_player_names, ok := props[property_key]
	if ok {
		parts := strings.split(encoded_player_names, ":")
		defer delete(parts)
		for player_name in parts {
			player := player_list_get_player_id(game_data_get_player_list(game_data), player_name)
			if player != nil {
				players[player] = struct{}{}
			} else {
				// Java: log.warn("gameplay sequence step: {} stepProperty: {} player: {} DOES NOT EXIST", ...)
				fmt.eprintfln(
					"gameplay sequence step: %s stepProperty: %s player: %s DOES NOT EXIST",
					game_step_get_name(step),
					property_key,
					player_name,
				)
			}
		}
	}
	return players
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isAirborneDelegate(GameState)
game_step_properties_helper_is_airborne_delegate :: proc(data: ^Game_State) -> bool {
	return game_step_is_airborne_combat_move_step_name(game_step_get_name(game_sequence_get_step(game_state_get_sequence(data))))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isBidPlaceDelegate(GameState)
game_step_properties_helper_is_bid_place_delegate :: proc(data: ^Game_State) -> bool {
	return game_step_is_bid_place_step_name(game_step_get_name(game_sequence_get_step(game_state_get_sequence(data))))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isBidPurchaseDelegate(GameState)
game_step_properties_helper_is_bid_purchase_delegate :: proc(data: ^Game_State) -> bool {
	return game_step_is_bid_step_name(game_step_get_name(game_sequence_get_step(game_state_get_sequence(data))))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isCombatDelegate(GameState)
game_step_properties_helper_is_combat_delegate :: proc(data: ^Game_State) -> bool {
	return game_step_is_combat_move_step_name(game_step_get_name(game_sequence_get_step(game_state_get_sequence(data))))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isNonCombatDelegate(GameState)
game_step_properties_helper_is_non_combat_delegate :: proc(data: ^Game_State) -> bool {
	return game_step_is_non_combat_move_step_name(game_step_get_name(game_sequence_get_step(game_state_get_sequence(data))))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isResetUnitStateAtStart(GameData)
//
// Java reads the step property "resetUnitStateAtStart" and parses it as a
// boolean (Boolean.parseBoolean returns false for null). No fallback to a
// delegate-name check (unlike isResetUnitStateAtEnd).
game_step_properties_helper_is_reset_unit_state_at_start :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["resetUnitStateAtStart"]
	if !ok {
		return false
	}
	return strings.equal_fold(prop, "true")
}
