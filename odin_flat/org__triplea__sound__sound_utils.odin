package game

import "core:strings"

Sound_Utils :: struct {}

// games.strategy.engine.data.GamePlayer attacker
// java.util.List<Unit> attackingUnits, defendingUnits
// games.strategy.engine.delegate.IDelegateBridge bridge
sound_utils_play_battle_type :: proc(
	attacker: ^Game_Player,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
) {
	sea_p, sea_c := matches_unit_is_sea()
	evade_p, evade_c := matches_unit_can_evade()
	air_p, air_c := matches_unit_is_air()

	any_attacker_sea := false
	for u in attacking_units {
		if sea_p(sea_c, u) {
			any_attacker_sea = true
			break
		}
	}
	any_defender_sea := false
	for u in defending_units {
		if sea_p(sea_c, u) {
			any_defender_sea = true
			break
		}
	}
	channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	if any_attacker_sea || any_defender_sea {
		all_attackers_evade := len(attacking_units) > 0
		for u in attacking_units {
			if !evade_p(evade_c, u) {
				all_attackers_evade = false
				break
			}
		}
		any_attacker_evade := false
		for u in attacking_units {
			if evade_p(evade_c, u) {
				any_attacker_evade = true
				break
			}
		}
		any_defender_evade := false
		for u in defending_units {
			if evade_p(evade_c, u) {
				any_defender_evade = true
				break
			}
		}
		if all_attackers_evade || (any_attacker_evade && any_defender_evade) {
			headless_sound_channel_play_sound_for_all(channel, "battle_sea_subs", attacker)
		} else {
			headless_sound_channel_play_sound_for_all(channel, "battle_sea_normal", attacker)
		}
		return
	}
	if len(attacking_units) > 0 && len(defending_units) > 0 {
		all_attackers_air := true
		for u in attacking_units {
			if !air_p(air_c, u) {
				all_attackers_air = false
				break
			}
		}
		all_defenders_air := true
		for u in defending_units {
			if !air_p(air_c, u) {
				all_defenders_air = false
				break
			}
		}
		if all_attackers_air && all_defenders_air {
			headless_sound_channel_play_sound_for_all(channel, "battle_air", attacker)
			return
		}
	}
	headless_sound_channel_play_sound_for_all(channel, "battle_land", attacker)
}

// games.strategy.engine.data.GamePlayer firingPlayer
// java.lang.String aaType
// boolean isHit
// games.strategy.engine.delegate.IDelegateBridge bridge
sound_utils_play_fire_battle_aa :: proc(
	firing_player: ^Game_Player,
	aa_type: string,
	is_hit: bool,
	bridge: ^I_Delegate_Bridge,
) {
	channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	if aa_type == "AA" {
		if is_hit {
			headless_sound_channel_play_sound_for_all(channel, "battle_aa_hit", firing_player)
		} else {
			headless_sound_channel_play_sound_for_all(channel, "battle_aa_miss", firing_player)
		}
		return
	}
	lower := strings.to_lower(aa_type)
	defer delete(lower)
	suffix := "_hit" if is_hit else "_miss"
	clip := strings.concatenate({"battle_", lower, suffix})
	defer delete(clip)
	headless_sound_channel_play_sound_for_all(channel, clip, firing_player)
}

// games.strategy.engine.data.GamePlayer attacker
// java.util.List<Unit> attackingUnits
// boolean isWater
// games.strategy.engine.delegate.IDelegateBridge bridge
sound_utils_play_attacker_wins_air_or_sea :: proc(
	attacker: ^Game_Player,
	attacking_units: [dynamic]^Unit,
	is_water: bool,
	bridge: ^I_Delegate_Bridge,
) {
	channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	air_p, air_c := matches_unit_is_air()
	all_air := len(attacking_units) > 0
	for u in attacking_units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	if is_water {
		if all_air {
			headless_sound_channel_play_sound_for_all(channel, "battle_air_successful", attacker)
		} else {
			headless_sound_channel_play_sound_for_all(channel, "battle_sea_successful", attacker)
		}
	} else {
		if all_air {
			headless_sound_channel_play_sound_for_all(channel, "battle_air_successful", attacker)
		}
	}
}
