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

// games.strategy.triplea.delegate.GameStepPropertiesHelper#getCombinedTurns(GameData, GamePlayer)
//
// Java: returns the set of GamePlayers whose phases are intermeshed with the
// given player. Reads the colon-separated COMBINED_TURNS property and unions
// in the optional default player. Equivalent to a HashSet<GamePlayer> in
// Java; Odin uses map[^Game_Player]struct{}. Caller owns the returned map.
game_step_properties_helper_get_combined_turns :: proc(
	data:   ^Game_Data,
	player: ^Game_Player,
) -> map[^Game_Player]struct{} {
	// Java starts with `checkNotNull(data)`; here `data == nil` would crash on
	// the first dereference inside `getPlayersFromProperty`, matching Java's
	// NullPointerException semantics.
	return game_step_properties_helper_get_players_from_property(data, "combinedTurns", player)
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isAirborneMove(GameData)
//
// Java: read the AIRBORNE_MOVE step property; if set, parse as boolean
// (Boolean.parseBoolean returns false for anything that is not "true"
// case-insensitively). If unset, fall back to the airborne-combat-move
// step-name suffix check.
game_step_properties_helper_is_airborne_move :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["airborneMove"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	return game_step_properties_helper_is_airborne_delegate(cast(^Game_State)data)
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isBid(GameData)
//
// Java: read the BID step property; if set, parse as boolean. Otherwise
// the step is a bid step iff its delegate-name suffix marks it as a bid
// purchase or bid placement step.
game_step_properties_helper_is_bid :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["bid"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	state := cast(^Game_State)data
	return game_step_properties_helper_is_bid_purchase_delegate(state) ||
		game_step_properties_helper_is_bid_place_delegate(state)
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isCombatMove(GameData, boolean)
// games.strategy.triplea.delegate.GameStepPropertiesHelper#isCombatMove(GameData)
//
// Java: read the COMBAT_MOVE step property; if set, parse as boolean. If
// unset, decide from the delegate kind:
//   - combat delegate         → true
//   - non-combat delegate     → false
//   - other:
//       doNotThrowErrorIfNotMoveDelegate true  → false
//       doNotThrowErrorIfNotMoveDelegate false → IllegalStateException
//
// Java provides a no-arg overload `isCombatMove(GameData)` that delegates
// to `isCombatMove(data, false)`. The Odin port collapses both methods
// into this single proc by giving the second parameter a default of
// `false`, so callers may pass either one or two arguments.
game_step_properties_helper_is_combat_move :: proc(
	data: ^Game_Data,
	do_not_throw_error_if_not_move_delegate: bool = false,
) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["combatMove"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	state := cast(^Game_State)data
	if game_step_properties_helper_is_combat_delegate(state) {
		return true
	}
	if game_step_properties_helper_is_non_combat_delegate(state) || do_not_throw_error_if_not_move_delegate {
		return false
	}
	fmt.panicf("Cannot determine combat or not: %s", game_step_get_name(step))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isGiveBonusMovement(GameData)
//
// Java: read GIVE_BONUS_MOVEMENT; if set, parse as boolean. Otherwise true
// iff the current step is a combat-move delegate.
game_step_properties_helper_is_give_bonus_movement :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["giveBonusMovement"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	return game_step_properties_helper_is_combat_delegate(cast(^Game_State)data)
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isNonCombatMove(GameData, boolean)
//
// Java: branch on `step.isNonCombat()` (which itself reads the
// NON_COMBAT_MOVE step property and falls back to the step-name suffix).
// If the step is non-combat, return true. Otherwise:
//   - combat delegate                           → false
//   - doNotThrowErrorIfNotMoveDelegate == true  → false
//   - else → IllegalStateException
game_step_properties_helper_is_non_combat_move :: proc(
	data: ^Game_Data,
	do_not_throw_error_if_not_move_delegate: bool,
) -> bool {
	game_data_acquire_read_lock(data)
	step := game_sequence_get_step(game_data_get_sequence(data))
	if game_step_is_non_combat(step) {
		return true
	}
	state := cast(^Game_State)data
	if game_step_properties_helper_is_combat_delegate(state) || do_not_throw_error_if_not_move_delegate {
		return false
	}
	fmt.panicf("Cannot determine combat or not: %s", game_step_get_name(step))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isRemoveAirThatCanNotLand(GameData)
//
// Java: read REMOVE_AIR_THAT_CAN_NOT_LAND; if set, parse as boolean.
// Otherwise return
//   (delegate is empty OR delegate's class is NOT NoAirCheckPlaceDelegate)
//   AND (current step is a noncombat-move delegate OR step name ends in "Place").
//
// Java identifies NoAirCheckPlaceDelegate via `Class.equals` reflection.
// Odin lacks first-class class identity, so the port follows the same
// pattern used elsewhere (see PoliticalActionAttachment#getPoliticalActionAttachments)
// and approximates by the XML delegate-name convention used throughout
// TripleA's map XMLs (`<delegate javaClass="NoAirCheckPlaceDelegate"
// name="placeNoAirCheck"/>`). Any step whose delegate is named
// "placeNoAirCheck" is treated as backed by NoAirCheckPlaceDelegate.
game_step_properties_helper_is_remove_air_that_can_not_land :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["removeAirThatCanNotLand"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	delegate := game_step_get_delegate_optional(step)
	is_no_air_check := delegate != nil && i_delegate_get_name(delegate) == "placeNoAirCheck"
	state := cast(^Game_State)data
	return (delegate == nil || !is_no_air_check) &&
		(game_step_properties_helper_is_non_combat_delegate(state) ||
			game_step_is_place_step_name(game_step_get_name(step)))
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isResetUnitStateAtEnd(GameData)
//
// Java: read RESET_UNIT_STATE_AT_END; if set, parse as boolean. Otherwise
// fall back to whether the current step is a noncombat-move delegate.
game_step_properties_helper_is_reset_unit_state_at_end :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["resetUnitStateAtEnd"]
	if ok {
		return strings.equal_fold(prop, "true")
	}
	return game_step_properties_helper_is_non_combat_delegate(cast(^Game_State)data)
}

// games.strategy.triplea.delegate.GameStepPropertiesHelper#isRepairUnits(GameData)
//
// Java: repair-units phase decision.
//   - If both Properties.getBattleshipsRepairAtBeginningOfRound and
//     Properties.getBattleshipsRepairAtEndOfRound are false, repairing is
//     globally disabled regardless of the per-step REPAIR_UNITS property.
//   - Otherwise, the REPAIR_UNITS step property, if present, wins.
//   - If the property is unset, repairing happens iff
//       (current step is a combat-move delegate AND repair-at-start is on)
//       OR
//       (current step name ends in "EndTurn" AND repair-at-end is on).
game_step_properties_helper_is_repair_units :: proc(data: ^Game_Data) -> bool {
	game_data_acquire_read_lock(data)
	gprops := game_data_get_properties(data)
	repair_at_start_and_only_own := properties_get_battleships_repair_at_beginning_of_round(gprops)
	repair_at_end_and_all        := properties_get_battleships_repair_at_end_of_round(gprops)
	// if both are off, we do no repairing, no matter what
	if !repair_at_start_and_only_own && !repair_at_end_and_all {
		return false
	}

	step  := game_sequence_get_step(game_data_get_sequence(data))
	props := game_step_get_properties(step)
	prop, ok := props["repairUnits"]
	if ok {
		return strings.equal_fold(prop, "true")
	}

	state := cast(^Game_State)data
	step_name := game_step_get_name(step)
	return (game_step_properties_helper_is_combat_delegate(state) && repair_at_start_and_only_own) ||
		(strings.has_suffix(step_name, "EndTurn") && repair_at_end_and_all)
}
