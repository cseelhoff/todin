package game

import "core:fmt"
import "core:math/rand"

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProPoliticsAi

// Pro politics AI.
Pro_Politics_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_politics_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Politics_Ai {
	self := new(Pro_Politics_Ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

// Java: void doActions(List<PoliticalActionAttachment> actions)
// Resolves the politics delegate from the cached ProData, then for each
// requested action logs a debug line and dispatches the attempt through
// `politics_delegate_attempt_action` (which performs the cost/conditions
// checks and applies the relationship change on success).
pro_politics_ai_do_actions :: proc(
	self: ^Pro_Politics_Ai,
	actions: [dynamic]^Political_Action_Attachment,
) {
	data := pro_data_get_data(self.pro_data)
	politics_delegate := game_data_get_politics_delegate(data)
	for action in actions {
		pro_logger_debug(fmt.tprintf("Performing action: %s", action.name))
		politics_delegate_attempt_action(politics_delegate, action)
	}
}

// Java: List<PoliticalActionAttachment> politicalActions()
// Mirrors the Java AI: classifies the towards-war actions into enemy vs
// neutral targets, picks at most one war declaration weighted by attack
// coverage and game round, and (50% of turns) folds in some non-war
// actions filtered by `canBeAttempted` + affordability before dispatching
// the chosen actions through `pro_politics_ai_do_actions`.
pro_politics_ai_political_actions :: proc(
	self: ^Pro_Politics_Ai,
) -> [dynamic]^Political_Action_Attachment {
	data := pro_data_get_data(self.pro_data)
	player := pro_data_get_player(self.pro_data)
	players := player_list_get_players(game_data_get_player_list(data))
	num_players := f32(len(players))
	delete(players)
	round := f64(game_sequence_get_round(game_data_get_sequence(data)))
	territory_manager := pro_territory_manager_new(self.calc, self.pro_data)
	politics_delegate := game_data_get_politics_delegate(data)
	pro_logger_info(fmt.tprintf("Politics for %s", player.named.base.name))

	// Find valid war actions
	action_choices_towards_war := ai_political_utils_get_political_actions_towards_war(
		player,
		politics_delegate_get_tested_conditions(politics_delegate),
		&data.game_state,
	)
	pro_logger_trace(fmt.tprintf("War options: %v", action_choices_towards_war))
	can_be_attempted_pred, can_be_attempted_ctx :=
		matches_abstract_user_action_attachment_can_be_attempted(
			politics_delegate_get_tested_conditions(politics_delegate),
		)
	valid_war_actions: [dynamic]^Political_Action_Attachment
	for paa in action_choices_towards_war {
		if can_be_attempted_pred(can_be_attempted_ctx, &paa.abstract_user_action_attachment) {
			append(&valid_war_actions, paa)
		}
	}
	pro_logger_trace(fmt.tprintf("Valid War options: %v", valid_war_actions))

	// Divide war actions into enemy and neutral
	enemy_map: map[^Political_Action_Attachment][dynamic]^Game_Player
	neutral_map: map[^Political_Action_Attachment][dynamic]^Game_Player
	war_pred, war_ctx := matches_relationship_type_is_at_war()
	rel_tracker := game_data_get_relationship_tracker(data)
	for action in valid_war_actions {
		war_players: [dynamic]^Game_Player
		for change in political_action_attachment_get_relationship_changes(action) {
			p1 := change.player1
			p2 := change.player2
			old_relation := relationship_tracker_get_relationship_type(rel_tracker, p1, p2)
			new_relation := change.relationship_type
			if old_relation != new_relation &&
			   war_pred(war_ctx, new_relation) &&
			   (p1 == player || p2 == player) {
				war_player := p2
				if war_player == player {
					war_player = p1
				}
				append(&war_players, war_player)
			}
		}
		if len(war_players) > 0 {
			if pro_utils_is_neutral_player(war_players[0]) {
				neutral_map[action] = war_players
			} else {
				enemy_map[action] = war_players
			}
		}
	}
	pro_logger_debug(fmt.tprintf("Neutral options: %v", neutral_map))
	pro_logger_debug(fmt.tprintf("Enemy options: %v", enemy_map))
	results: [dynamic]^Political_Action_Attachment
	if len(enemy_map) > 0 {

		// Find all attack options
		pro_territory_manager_populate_potential_attack_options(territory_manager)
		attack_options :=
			pro_territory_manager_remove_potential_territories_that_cant_be_conquered(
				territory_manager,
			)
		pro_logger_trace(
			fmt.tprintf(
				"%s, numAttackOptions=%d, options=%v",
				player.named.base.name,
				len(attack_options),
				attack_options,
			),
		)

		// Find attack options per war action
		attack_percentage_map: map[^Political_Action_Attachment]f64
		for action in enemy_map {
			count: i32 = 0
			enemy_players := enemy_map[action]
			owned_pred, owned_ctx := matches_is_territory_owned_by_any_of(enemy_players)
			unit_owned_pred, unit_owned_ctx := matches_unit_is_owned_by_any_of(enemy_players)
			has_units_pred, has_units_ctx := matches_territory_has_units_that_match(
				unit_owned_pred,
				unit_owned_ctx,
			)
			for patd in attack_options {
				t := pro_territory_get_territory(patd)
				if owned_pred(owned_ctx, t) || has_units_pred(has_units_ctx, t) {
					count += 1
				}
			}
			attack_percentage := f64(count) / (f64(len(attack_options)) + 1.0)
			attack_percentage_map[action] = attack_percentage
			pro_logger_trace(
				fmt.tprintf(
					"%v, count=%d, attackPercentage=%f",
					enemy_players,
					count,
					attack_percentage,
				),
			)
		}

		// Decide whether to declare war on an enemy
		options: [dynamic]^Political_Action_Attachment
		for action in attack_percentage_map {
			append(&options, action)
		}
		rand.shuffle(options[:])
		for action in options {
			round_factor := (round - 1) * 0.05 // 0, .05, .1, .15, etc
			war_chance :=
				round_factor + attack_percentage_map[action] * (1 + 10 * round_factor)
			random := rand.float64()
			pro_logger_trace(
				fmt.tprintf(
					"%v, warChance=%f, random=%f",
					enemy_map[action],
					war_chance,
					random,
				),
			)
			if random <= war_chance {
				append(&results, action)
				pro_logger_debug(
					fmt.tprintf("---Declared war on %v", enemy_map[action]),
				)
				break
			}
		}
	} else if len(neutral_map) > 0 {

		// Decide whether to declare war on a neutral
		options: [dynamic]^Political_Action_Attachment
		for action in neutral_map {
			append(&options, action)
		}
		rand.shuffle(options[:])
		random := rand.float64()
		war_chance := 0.01
		pro_logger_debug(fmt.tprintf("warChance=%f, random=%f", war_chance, random))
		if random <= war_chance {
			append(&results, options[0])
			pro_logger_debug(
				fmt.tprintf("Declared war on %v", enemy_map[options[0]]),
			)
		}
	}

	// Old code used for non-war actions
	if rand.float64() < 0.5 {
		action_choices_other := ai_political_utils_get_political_actions_other(
			player,
			politics_delegate_get_tested_conditions(politics_delegate),
			&data.game_state,
		)
		if len(action_choices_other) > 0 {
			rand.shuffle(action_choices_other[:])
			i: i32 = 0
			random := rand.float64()
			max_other_actions_per_turn: i32
			if random < 0.3 {
				max_other_actions_per_turn = 0
			} else if random < 0.6 {
				max_other_actions_per_turn = 1
			} else if random < 0.9 {
				max_other_actions_per_turn = 2
			} else if random < 0.99 {
				max_other_actions_per_turn = 3
			} else {
				max_other_actions_per_turn = i32(num_players)
			}
			attempt_pred, attempt_ctx :=
				matches_abstract_user_action_attachment_can_be_attempted(
					politics_delegate_get_tested_conditions(politics_delegate),
				)
			for action in action_choices_other {
				if max_other_actions_per_turn <= 0 {
					break
				}
				if !attempt_pred(attempt_ctx, &action.abstract_user_action_attachment) {
					continue
				}
				if !resource_collection_has(
					game_player_get_resources(player),
					&action.cost_resources,
				) {
					continue
				}
				i += 1
				if i > max_other_actions_per_turn {
					break
				}
				append(&results, action)
			}
		}
	}
	pro_politics_ai_do_actions(self, results)
	return results
}

