package game

// Java owner: games.strategy.engine.player.Player (interface)
//
// Modeled with proc-typed fields installed by concrete implementers,
// matching the convention used elsewhere for pure-callback Java
// interfaces (e.g. ChatMessageListener, IChatChannel). Dispatch procs
// (`player_*`) are the public entry points.

Player :: struct {
	using i_remote:   I_Remote,
	get_game_player:  proc(self: ^Player) -> ^Game_Player,
	is_ai:            proc(self: ^Player) -> bool,
	get_name:         proc(self: ^Player) -> string,
	get_player_label: proc(self: ^Player) -> string,
	initialize:       proc(self: ^Player, bridge: ^Player_Bridge, game_player: ^Game_Player),
	start:            proc(self: ^Player, step_name: string),
	select_bombarding_territory: proc(
		self: ^Player,
		unit: ^Unit,
		unit_territory: ^Territory,
		territories: [dynamic]^Territory,
		none_available: bool,
	) -> ^Territory,
}

// games.strategy.engine.player.Player#selectBombardingTerritory(Unit, Territory, Collection, boolean)
player_select_bombarding_territory :: proc(
	self: ^Player,
	unit: ^Unit,
	unit_territory: ^Territory,
	territories: [dynamic]^Territory,
	none_available: bool,
) -> ^Territory {
	return self.select_bombarding_territory(self, unit, unit_territory, territories, none_available)
}

// games.strategy.engine.player.Player#start(java.lang.String)
player_start :: proc(self: ^Player, step_name: string) {
	if self != nil && self.start != nil {
		self.start(self, step_name)
	}
}

// games.strategy.engine.player.Player#getGamePlayer()
player_get_game_player :: proc(self: ^Player) -> ^Game_Player {
	return self.get_game_player(self)
}

// games.strategy.engine.player.Player#isAi()
player_is_ai :: proc(self: ^Player) -> bool {
	return self.is_ai(self)
}

// games.strategy.engine.player.Player#getName()
player_get_name :: proc(self: ^Player) -> string {
	return self.get_name(self)
}

// games.strategy.engine.player.Player#getPlayerLabel()
player_get_player_label :: proc(self: ^Player) -> string {
	return self.get_player_label(self)
}

// games.strategy.engine.player.Player#initialize(PlayerBridge, GamePlayer)
player_initialize :: proc(self: ^Player, bridge: ^Player_Bridge, game_player: ^Game_Player) {
	self.initialize(self, bridge, game_player)
}

