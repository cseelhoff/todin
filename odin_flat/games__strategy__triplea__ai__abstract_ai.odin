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
