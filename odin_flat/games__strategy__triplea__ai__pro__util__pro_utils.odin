package game

import "core:fmt"
import "core:strconv"
import "core:strings"

Pro_Utils :: struct {}

// Port of ProUtils.getFilteredPlayers — filters
// data.getPlayerList().getPlayers() through the supplied predicate
// (Predicate<GamePlayer> in Java; Odin pairs a proc with a captured
// rawptr context).
pro_utils_get_filtered_players :: proc(
	data: ^Game_State,
	filter: proc(rawptr, ^Game_Player) -> bool,
	filter_ctx: rawptr,
) -> [dynamic]^Game_Player {
	result := make([dynamic]^Game_Player)
	players := player_list_get_players(game_state_get_player_list(data))
	defer delete(players)
	for p in players {
		if filter(filter_ctx, p) {
			append(&result, p)
		}
	}
	return result
}

// Port of ProUtils.getOtherPlayersInTurnOrder — returns every distinct
// non-`player` GamePlayer that owns a "*CombatMove" step, walking the
// sequence starting at the current step index and wrapping around.
pro_utils_get_other_players_in_turn_order :: proc(
	player: ^Game_Player,
) -> [dynamic]^Game_Player {
	players := make([dynamic]^Game_Player)
	sequence := game_data_get_sequence(game_player_get_data(player))
	start_index := game_sequence_get_step_index(sequence)
	size := game_sequence_size(sequence)
	for i in 0 ..< size {
		current_index := start_index + i
		if current_index >= size {
			current_index -= size
		}
		step := game_sequence_get_step_at(sequence, current_index)
		step_player := game_step_get_player_id(step)
		if strings.has_suffix(game_step_get_name(step), "CombatMove") &&
		   step_player != nil &&
		   step_player != player {
			already := false
			for existing in players {
				if existing == step_player {
					already = true
					break
				}
			}
			if !already {
				append(&players, step_player)
			}
		}
	}
	return players
}

// Port of ProUtils.isPassiveNeutralPlayer — true iff the player is the
// Null player or has no CombatMove step in the sequence.
pro_utils_is_passive_neutral_player :: proc(player: ^Game_Player) -> bool {
	if game_player_is_null(player) {
		return true
	}
	sequence := game_data_get_sequence(game_player_get_data(player))
	for s in game_sequence_iterator(sequence) {
		if !pro_utils_lambda__is_passive_neutral_player__5(player, s) {
			continue
		}
		if game_step_is_combat_move_step_name(game_step_get_name(s)) {
			return false
		}
	}
	return true
}

// Port of ProUtils#lambda$isFfa$3 — captured (relationshipTracker,
// enemiesWithoutNeutrals); body is
// `relationshipTracker.isAtWarWithAnyOfThesePlayers(e, enemiesWithoutNeutrals)`.
pro_utils_lambda__is_ffa__3 :: proc(
	relationship_tracker: ^Relationship_Tracker,
	enemies_without_neutrals: map[^Game_Player]struct{},
	e: ^Game_Player,
) -> bool {
	enemies_list := make([dynamic]^Game_Player, 0, len(enemies_without_neutrals))
	defer delete(enemies_list)
	for k in enemies_without_neutrals {
		append(&enemies_list, k)
	}
	return relationship_tracker_is_at_war_with_any_of_these_players(
		relationship_tracker,
		e,
		enemies_list,
	)
}

// Port of ProUtils#lambda$isPassiveNeutralPlayer$5 — captured `player`;
// body is `player.equals(s.getPlayerId())`.
pro_utils_lambda__is_passive_neutral_player__5 :: proc(
	player: ^Game_Player,
	s: ^Game_Step,
) -> bool {
	return player == game_step_get_player_id(s)
}

// Port of ProUtils.isPlayersTurnFirst — walks the player turn order and
// returns true iff player1 appears before player2 (or neither is present).
pro_utils_is_players_turn_first :: proc(
	players_in_order: [dynamic]^Game_Player,
	player1: ^Game_Player,
	player2: ^Game_Player,
) -> bool {
	for p in players_in_order {
		if p == player1 {
			return true
		} else if p == player2 {
			return false
		}
	}
	return true
}

// Port of ProUtils#lambda$summarizeUnits$7. The Java lambda receives a
// Map.Entry<String, Integer> from IntegerMap<String>.entrySet() and
// produces either the bare key (count == 1) or "<count> <key>".
pro_utils_lambda_summarize_units_7 :: proc(key: string, value: i32) -> string {
	if value == 1 {
		return key
	}
	buf: [32]u8
	count_str := strconv.itoa(buf[:], int(value))
	return fmt.aprintf("%s %s", count_str, key)
}

