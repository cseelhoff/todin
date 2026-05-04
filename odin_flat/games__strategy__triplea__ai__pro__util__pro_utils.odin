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

// Port of ProUtils.getAlliedPlayers (private static) — returns every
// player in `data.getPlayerList()` that is allied to `player`.
pro_utils_get_allied_players :: proc(player: ^Game_Player) -> [dynamic]^Game_Player {
	data := game_player_get_data(player)
	pred, ctx := matches_is_allied(player)
	return pro_utils_get_filtered_players(&data.game_state, pred, ctx)
}

// Port of ProUtils.getEnemyPlayers — returns every player in
// `data.getPlayerList()` that is NOT allied to `player`
// (Java: Matches.isAllied(player).negate()).
pro_utils_get_enemy_players :: proc(player: ^Game_Player) -> [dynamic]^Game_Player {
	data := game_player_get_data(player)
	pred, ctx := matches_is_allied(player)
	result := make([dynamic]^Game_Player)
	players := player_list_get_players(game_state_get_player_list(&data.game_state))
	defer delete(players)
	for p in players {
		if !pred(ctx, p) {
			append(&result, p)
		}
	}
	return result
}

// Port of ProUtils.getAlliedPlayersInTurnOrder — others-in-turn-order,
// keeping only those allied to `player` per
// `relationshipTracker.isAllied(player, currentPlayer)`.
pro_utils_get_allied_players_in_turn_order :: proc(
	player: ^Game_Player,
) -> [dynamic]^Game_Player {
	rt := game_data_get_relationship_tracker(game_player_get_data(player))
	others := pro_utils_get_other_players_in_turn_order(player)
	defer delete(others)
	pred, pred_ctx := matches_relationship_type_is_allied()
	result := make([dynamic]^Game_Player)
	for current_player in others {
		rtype := relationship_tracker_get_relationship_type(rt, player, current_player)
		if pred(pred_ctx, rtype) {
			append(&result, current_player)
		}
	}
	return result
}

// Port of ProUtils.getEnemyPlayersInTurnOrder — others-in-turn-order,
// keeping only those NOT allied to `player`.
pro_utils_get_enemy_players_in_turn_order :: proc(
	player: ^Game_Player,
) -> [dynamic]^Game_Player {
	rt := game_data_get_relationship_tracker(game_player_get_data(player))
	others := pro_utils_get_other_players_in_turn_order(player)
	defer delete(others)
	pred, pred_ctx := matches_relationship_type_is_allied()
	result := make([dynamic]^Game_Player)
	for current_player in others {
		rtype := relationship_tracker_get_relationship_type(rt, player, current_player)
		if !pred(pred_ctx, rtype) {
			append(&result, current_player)
		}
	}
	return result
}

// Port of ProUtils.getPotentialEnemyPlayers — players that are neither
// allied to `player` nor passive-neutral.
// Java: not(Matches.isAllied(player)).and(not(ProUtils::isPassiveNeutralPlayer)).
pro_utils_get_potential_enemy_players :: proc(player: ^Game_Player) -> [dynamic]^Game_Player {
	data := game_player_get_data(player)
	allied_pred, allied_ctx := matches_is_allied(player)
	result := make([dynamic]^Game_Player)
	players := player_list_get_players(game_state_get_player_list(&data.game_state))
	defer delete(players)
	for p in players {
		if !allied_pred(allied_ctx, p) && !pro_utils_is_passive_neutral_player(p) {
			append(&result, p)
		}
	}
	return result
}

// Port of ProUtils#lambda$isNeutralPlayer$4 — captured nothing; tests
// `isPassiveNeutralPlayer(a) || (a.isHidden() && (a.isDefaultTypeAi() || a.isDefaultTypeDoesNothing()))`.
pro_utils_lambda__is_neutral_player__4 :: proc(a: ^Game_Player) -> bool {
	return pro_utils_is_passive_neutral_player(a) ||
	       (game_player_is_hidden(a) &&
			       (game_player_is_default_type_ai(a) ||
					       game_player_is_default_type_does_nothing(a)))
}

// Port of ProUtils.isNeutralPlayer — true when every ally of `player`
// (including `player` itself) is "neutral" per lambda 4 above. Null
// players are short-circuited to neutral.
pro_utils_is_neutral_player :: proc(player: ^Game_Player) -> bool {
	if game_player_is_null(player) {
		return true
	}
	rt := game_data_get_relationship_tracker(game_player_get_data(player))
	allies := relationship_tracker_get_allies(rt, player, true)
	defer delete(allies)
	for a in allies {
		if !pro_utils_lambda__is_neutral_player__4(a) {
			return false
		}
	}
	return true
}

// Port of ProUtils#lambda$isPassiveNeutralPlayer$6 — body
// `GameStep.isCombatMoveStepName(s.getName())`. No captured state.
pro_utils_lambda__is_passive_neutral_player__6 :: proc(s: ^Game_Step) -> bool {
	return game_step_is_combat_move_step_name(game_step_get_name(s))
}

// Port of ProUtils.isFfa — true if the game is a free-for-all, i.e.
// any of `player`'s non-neutral enemies is at war with another of
// `player`'s non-neutral enemies.
pro_utils_is_ffa :: proc(data: ^Game_State, player: ^Game_Player) -> bool {
	relationship_tracker := game_state_get_relationship_tracker(data)
	enemies := relationship_tracker_get_enemies(relationship_tracker, player)
	defer delete(enemies)
	enemies_without_neutrals := make(map[^Game_Player]struct{})
	defer delete(enemies_without_neutrals)
	for p in enemies {
		if !pro_utils_is_neutral_player(p) {
			enemies_without_neutrals[p] = {}
		}
	}
	for e in enemies_without_neutrals {
		if pro_utils_lambda__is_ffa__3(
			   relationship_tracker,
			   enemies_without_neutrals,
			   e,
		   ) {
			return true
		}
	}
	return false
}

// Port of ProUtils.summarizeUnits — histograms units by their
// toString() representation, sorts ascending by key, and joins
// "<key>" or "<count> <key>" with ", " inside "[...]".
pro_utils_summarize_units :: proc(units: [dynamic]^Unit) -> string {
	counts := make(map[string]i32)
	defer delete(counts)
	for u in units {
		k := unit_to_string(u)
		if existing, ok := counts[k]; ok {
			counts[k] = existing + 1
		} else {
			counts[k] = 1
		}
	}
	keys := make([dynamic]string, 0, len(counts))
	defer delete(keys)
	for k in counts {
		append(&keys, k)
	}
	// Insertion sort ascending — Map.Entry.comparingByKey() on String.
	for i in 1 ..< len(keys) {
		j := i
		for j > 0 && keys[j] < keys[j - 1] {
			keys[j], keys[j - 1] = keys[j - 1], keys[j]
			j -= 1
		}
	}
	b := strings.builder_make()
	strings.write_byte(&b, '[')
	for k, idx in keys {
		if idx > 0 {
			strings.write_string(&b, ", ")
		}
		strings.write_string(&b, pro_utils_lambda_summarize_units_7(k, counts[k]))
	}
	strings.write_byte(&b, ']')
	return strings.to_string(b)
}

// Port of ProUtils.isNeutralLand —
// `!t.isWater() && ProUtils.isNeutralPlayer(t.getOwner())`.
pro_utils_is_neutral_land :: proc(t: ^Territory) -> bool {
	return !territory_is_water(t) && pro_utils_is_neutral_player(territory_get_owner(t))
}

// Port of ProUtils#lambda$isFfa$2 — captured nothing; body is
// `!isNeutralPlayer(p)`, used in
// `enemies.stream().filter(p -> !isNeutralPlayer(p))`.
pro_utils_lambda__is_ffa__2 :: proc(p: ^Game_Player) -> bool {
	return !pro_utils_is_neutral_player(p)
}

// Port of ProUtils#lambda$getAlliedPlayersInTurnOrder$0 — captured
// `(relationshipTracker, player)`; body is
// `!relationshipTracker.isAllied(player, currentPlayer)` (the removeIf
// predicate keeps non-allies, so true means "remove").
pro_utils_lambda__get_allied_players_in_turn_order__0 :: proc(
	relationship_tracker: ^Relationship_Tracker,
	player: ^Game_Player,
	current_player: ^Game_Player,
) -> bool {
	return !relationship_tracker_is_allied(relationship_tracker, player, current_player)
}

// Port of ProUtils#lambda$getEnemyPlayersInTurnOrder$1 — captured
// `(relationshipTracker, player)`; body is
// `relationshipTracker.isAllied(player, currentPlayer)`.
pro_utils_lambda__get_enemy_players_in_turn_order__1 :: proc(
	relationship_tracker: ^Relationship_Tracker,
	player: ^Game_Player,
	current_player: ^Game_Player,
) -> bool {
	return relationship_tracker_is_allied(relationship_tracker, player, current_player)
}

// Port of ProUtils.getLiveAlliedCapitals — friendly capitals that are
// still owned by a friendly power, are not impassable to land units
// for `player`, and are currently allied to `player`.
pro_utils_get_live_allied_capitals :: proc(
	data: ^Game_State,
	player: ^Game_Player,
) -> [dynamic]^Territory {
	capitals := make([dynamic]^Territory)
	players := pro_utils_get_allied_players(player)
	defer delete(players)
	game_map := game_state_get_map(data)
	for allied_player in players {
		owned := territory_attachment_get_all_currently_owned_capitals(allied_player, game_map)
		defer delete(owned)
		for c in owned {
			append(&capitals, c)
		}
	}
	imp_pred, imp_ctx := matches_territory_is_not_impassable_to_land_units(player)
	all_pred, all_ctx := matches_is_territory_allied(player)
	filtered := make([dynamic]^Territory)
	for t in capitals {
		if imp_pred(imp_ctx, t) && all_pred(all_ctx, t) {
			append(&filtered, t)
		}
	}
	delete(capitals)
	return filtered
}

// Port of ProUtils.getLiveEnemyCapitals — enemy capitals still owned
// by enemy players, that are not impassable to `player`'s land units,
// and that are currently owned by one of `player`'s potential enemies.
pro_utils_get_live_enemy_capitals :: proc(
	data: ^Game_State,
	player: ^Game_Player,
) -> [dynamic]^Territory {
	enemy_capitals := make([dynamic]^Territory)
	enemy_players := pro_utils_get_enemy_players(player)
	defer delete(enemy_players)
	game_map := game_state_get_map(data)
	for other_player in enemy_players {
		owned := territory_attachment_get_all_currently_owned_capitals(other_player, game_map)
		defer delete(owned)
		for c in owned {
			append(&enemy_capitals, c)
		}
	}
	imp_pred, imp_ctx := matches_territory_is_not_impassable_to_land_units(player)
	potential := pro_utils_get_potential_enemy_players(player)
	defer delete(potential)
	owned_pred, owned_ctx := matches_is_territory_owned_by_any_of(potential)
	filtered := make([dynamic]^Territory)
	for t in enemy_capitals {
		if imp_pred(imp_ctx, t) && owned_pred(owned_ctx, t) {
			append(&filtered, t)
		}
	}
	delete(enemy_capitals)
	return filtered
}

