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
	stop_game:        proc(self: ^Player),
	select_shore_bombard: proc(self: ^Player, unit_territory: ^Territory) -> bool,
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

// games.strategy.engine.player.Player#stopGame()
//   Vtable dispatch through the proc field. AI-snapshot harness
//   instances may leave the field nil (no-op stop semantics in the
//   single-threaded test loop); we treat a nil dispatch as a no-op
//   to mirror Java's "best effort" stopGame contract.
player_stop_game :: proc(self: ^Player) {
	if self != nil && self.stop_game != nil {
		self.stop_game(self)
	}
}

// games.strategy.engine.player.Player#selectShoreBombard(Territory)
//   Returns whether the human/AI player chose to fire a shore-
//   bombardment salvo from the given territory. Vtable dispatch.
player_select_shore_bombard :: proc(self: ^Player, unit_territory: ^Territory) -> bool {
	return self.select_shore_bombard(self, unit_territory)
}

