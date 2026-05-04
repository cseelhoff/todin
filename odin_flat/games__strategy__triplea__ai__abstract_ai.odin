package game

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

