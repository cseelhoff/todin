package game

import "core:fmt"

Abstract_Base_Player :: struct {
	name:          string,
	player_label:  string,
	game_player:   ^Game_Player,
	player_bridge: ^Player_Bridge,
}

// Java owners covered by this file:
//   - games.strategy.triplea.player.AbstractBasePlayer

abstract_base_player_new :: proc(name: string, player_label: string) -> ^Abstract_Base_Player {
	self := new(Abstract_Base_Player)
	self.name = name
	self.player_label = player_label
	return self
}

abstract_base_player_get_game_player :: proc(self: ^Abstract_Base_Player) -> ^Game_Player {
	return self.game_player
}

abstract_base_player_get_player_bridge :: proc(self: ^Abstract_Base_Player) -> ^Player_Bridge {
	return self.player_bridge
}

abstract_base_player_get_player_label :: proc(self: ^Abstract_Base_Player) -> string {
	return self.player_label
}

abstract_base_player_initialize :: proc(self: ^Abstract_Base_Player, player_bridge: ^Player_Bridge, game_player: ^Game_Player) {
	self.player_bridge = player_bridge
	self.game_player = game_player
}

abstract_base_player_get_game_data :: proc(self: ^Abstract_Base_Player) -> ^Game_Data {
	return player_bridge_get_game_data(self.player_bridge)
}

// Java: AbstractBasePlayer#start(String stepName) — Player interface entry
// point invoked when a new game step begins. The method polls the
// (asynchronously updated) PlayerBridge until its step name catches up
// with the requested step, sleeping 100ms between checks. After 30 ticks
// (~3s) it logs a warning; after 310 ticks (~31s) it logs an error and
// gives up so the caller can proceed (a downstream ClassCastException is
// expected if the bridge is genuinely out of sync).
abstract_base_player_start :: proc(self: ^Abstract_Base_Player, step_name: string) {
	if len(step_name) == 0 {
		// Java guard: `if (stepName != null)`. Odin strings are not nullable;
		// the closest analogue is the empty string sentinel.
		return
	}
	bridge := abstract_base_player_get_player_bridge(self)
	bridge_step := player_bridge_get_step_name(bridge)
	i: i32 = 0
	for step_name != bridge_step {
		interruptibles_sleep(100)
		i += 1
		if i == 30 {
			fmt.eprintf(
				"Start step: %s does not match player bridge step: %s. Player Bridge GameOver=%v, PlayerId: %s, Game: %s. Something wrong or very laggy. Will keep trying for 30 more seconds. \n",
				step_name,
				bridge_step,
				player_bridge_is_game_over(abstract_base_player_get_player_bridge(self)),
				named_get_name(&abstract_base_player_get_game_player(self).named),
				game_data_get_game_name(abstract_base_player_get_game_data(self)),
			)
		}
		if i > 310 {
			fmt.eprintf(
				"Start step: %s still does not match player bridge step: %s even after waiting more than 30 seconds. This will probably result in a ClassCastException very soon. Player Bridge GameOver=%v, PlayerId: %s, Game: %s\n",
				step_name,
				bridge_step,
				player_bridge_is_game_over(abstract_base_player_get_player_bridge(self)),
				named_get_name(&abstract_base_player_get_game_player(self).named),
				game_data_get_game_name(abstract_base_player_get_game_data(self)),
			)
			break
		}
		bridge_step = player_bridge_get_step_name(abstract_base_player_get_player_bridge(self))
	}
}

