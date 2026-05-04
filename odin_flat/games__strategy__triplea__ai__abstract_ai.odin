package game

import "core:math/rand"

Abstract_Ai :: struct {
	using abstract_base_player: Abstract_Base_Player,
}

// Java owners covered by this file:
//   - games.strategy.triplea.ai.AbstractAi

abstract_ai_end_turn :: proc(self: ^Abstract_Ai, end_turn_forum_poster_delegate: ^I_Abstract_Forum_Poster_Delegate, player: ^Game_Player) {
	// we should not override this...
}

abstract_ai_is_ai :: proc(self: ^Abstract_Ai) -> bool {
	return true
}

abstract_ai_confirm_enemy_casualties :: proc(self: ^Abstract_Ai, battle_id: ^Uuid, message: string, hit_player: ^Game_Player) {
}

abstract_ai_lambda_pick_territory_and_units_2 :: proc(t: ^Territory) -> bool {
	return true
}

abstract_ai_lambda_pick_territory_and_units_1 :: proc(t: ^Territory) -> bool {
        return true
}

abstract_ai_lambda_pick_territory_and_units_3 :: proc(t: ^Territory) -> bool {
	return true
}

abstract_ai_lambda_pick_territory_and_units_4 :: proc(t: ^Territory) -> bool {
	return true
}

abstract_ai_report_message :: proc(self: ^Abstract_Ai, message: string, title: string) {
}

// Java synthetic lambda from `selectKamikazeSuicideAttacks`:
//   kamikazeSuicideAttacks.computeIfAbsent(t, key -> new HashMap<>())
// Non-capturing; returns a fresh empty inner map keyed by ^Unit
// with IntegerMap<Resource> values. The `key` parameter (the absent
// territory) is ignored, mirroring the Java lambda's body.
abstract_ai_lambda_select_kamikaze_suicide_attacks_0 :: proc(
	key: ^Territory,
) -> map[^Unit]^Integer_Map {
	return make(map[^Unit]^Integer_Map)
}

// games.strategy.triplea.ai.AbstractAi#<init>(java.lang.String,java.lang.String)
//   public AbstractAi(final String name, final String playerLabel) {
//     super(name, playerLabel);
//   }
abstract_ai_new :: proc(name: string, player_label: string) -> ^Abstract_Ai {
	self := new(Abstract_Ai)
	self.name = name
	self.player_label = player_label
	return self
}

// games.strategy.triplea.ai.AbstractAi#battle(games.strategy.triplea.delegate.remote.IBattleDelegate)
//   Loop until all battles in the listing are fought. For each battle, call
//   fightBattle; tolerate dependency-error messages (those mean the battle
//   must wait for a prerequisite). Other errors are logged.
abstract_ai_battle :: proc(self: ^Abstract_Ai, battle_delegate: ^I_Battle_Delegate) {
	// I_Battle_Delegate is a marker interface; the concrete remote delegate
	// returned by getPlayerBridge().getRemoteDelegate() is a Battle_Delegate.
	bd := cast(^Battle_Delegate)battle_delegate
	for {
		listing := battle_delegate_get_battle_listing(bd)
		if battle_listing_is_empty(listing) {
			return
		}
		for bt, territories in battle_listing_get_battles_map(listing) {
			for current in territories {
				error := battle_delegate_fight_battle(
					bd,
					current,
					i_battle_battle_type_is_bombing_run(bt),
					bt,
				)
				if error != "" && !battle_delegate_is_battle_dependency_error_message(error) {
					// Java: log.warn(error)
				}
			}
		}
	}
}

// games.strategy.triplea.ai.AbstractAi#movePause()
//   Java sleeps for ClientSetting.aiMovePauseDuration to let a human watch.
//   Snapshot harness is single-threaded with no UI; no-op.
abstract_ai_move_pause :: proc() {
}

// games.strategy.triplea.ai.AbstractAi#combatStepPause()
//   Java sleeps for ClientSetting.aiCombatStepPauseDuration. No-op for harness.
abstract_ai_combat_step_pause :: proc() {
}

// games.strategy.triplea.ai.AbstractAi#confirmOwnCasualties(java.util.UUID,java.lang.String)
//   public void confirmOwnCasualties(final UUID battleId, final String message) {
//     combatStepPause();
//   }
abstract_ai_confirm_own_casualties :: proc(self: ^Abstract_Ai, battle_id: ^Uuid, message: string) {
	abstract_ai_combat_step_pause()
}

// games.strategy.triplea.ai.AbstractAi#politicalActions()
//   Resolves the politics delegate, the AI's current GamePlayer and the
//   total player count, then with 50% probability either tries some
//   towards-war actions or some non-war actions. Each branch shuffles its
//   candidate list, picks a Math.random()-driven cap on how many actions
//   to attempt, filters out actions whose conditions don't currently hold
//   (and, on the non-war branch, ones the player cannot afford), and
//   submits the survivors via the politics delegate's attemptAction. The
//   Java side casts `getPlayerBridge().getRemoteDelegate()` to
//   IPoliticsDelegate; the Odin port shortcuts the remote indirection
//   (mirroring `pro_politics_ai_do_actions`) and calls
//   `politics_delegate_attempt_action` on the delegate from game data.
abstract_ai_political_actions :: proc(self: ^Abstract_Ai) {
	data := abstract_base_player_get_game_data(&self.abstract_base_player)
	game_player := abstract_base_player_get_game_player(&self.abstract_base_player)
	players := player_list_get_players(game_data_get_player_list(data))
	num_players := f32(len(players))
	delete(players)
	politics_delegate := game_data_get_politics_delegate(data)
	// We want to test the conditions each time to make sure they are still valid
	if rand.float64() < 0.5 {
		action_choices_towards_war := ai_political_utils_get_political_actions_towards_war(
			game_player,
			politics_delegate_get_tested_conditions(politics_delegate),
			&data.game_state,
		)
		if len(action_choices_towards_war) > 0 {
			rand.shuffle(action_choices_towards_war[:])
			i: i32 = 0
			// should we use bridge's random source here?
			random := rand.float64()
			max_war_actions_per_turn: i32
			if random < 0.5 {
				max_war_actions_per_turn = 0
			} else if random < 0.9 {
				max_war_actions_per_turn = 1
			} else if random < 0.99 {
				max_war_actions_per_turn = 2
			} else {
				max_war_actions_per_turn = i32(num_players) / 2
			}
			if max_war_actions_per_turn > 0 {
				war_pred, war_ctx := matches_relationship_is_at_war()
				rels := relationship_tracker_get_relationships(
					game_data_get_relationship_tracker(data),
					game_player,
				)
				at_war_count: i32 = 0
				for r, _ in rels {
					if war_pred(war_ctx, r) {
						at_war_count += 1
					}
				}
				delete(rels)
				if f32(at_war_count) / num_players < 0.4 {
					if rand.float64() < 0.9 {
						max_war_actions_per_turn = 0
					} else {
						max_war_actions_per_turn = 1
					}
				}
			}
			can_be_attempted_pred, can_be_attempted_ctx :=
				matches_abstract_user_action_attachment_can_be_attempted(
					politics_delegate_get_tested_conditions(politics_delegate),
				)
			for action in action_choices_towards_war {
				if max_war_actions_per_turn <= 0 {
					break
				}
				if !can_be_attempted_pred(
					can_be_attempted_ctx,
					&action.abstract_user_action_attachment,
				) {
					continue
				}
				i += 1
				if i > max_war_actions_per_turn {
					break
				}
				politics_delegate_attempt_action(politics_delegate, action)
			}
		}
		delete(action_choices_towards_war)
	} else {
		action_choices_other := ai_political_utils_get_political_actions_other(
			game_player,
			politics_delegate_get_tested_conditions(politics_delegate),
			&data.game_state,
		)
		if len(action_choices_other) > 0 {
			rand.shuffle(action_choices_other[:])
			i: i32 = 0
			// should we use bridge's random source here?
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
			can_be_attempted_pred, can_be_attempted_ctx :=
				matches_abstract_user_action_attachment_can_be_attempted(
					politics_delegate_get_tested_conditions(politics_delegate),
				)
			for action in action_choices_other {
				if max_other_actions_per_turn <= 0 {
					break
				}
				if !can_be_attempted_pred(
					can_be_attempted_ctx,
					&action.abstract_user_action_attachment,
				) {
					continue
				}
				if !resource_collection_has(
					game_player_get_resources(game_player),
					&action.cost_resources,
				) {
					continue
				}
				i += 1
				if i > max_other_actions_per_turn {
					break
				}
				politics_delegate_attempt_action(politics_delegate, action)
			}
		}
		delete(action_choices_other)
	}
}

