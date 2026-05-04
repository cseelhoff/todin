package game

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

