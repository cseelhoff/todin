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
	select_fixed_dice: proc(
		self: ^Player,
		num_dice: i32,
		hit_at: i32,
		title: string,
		dice_sides: i32,
	) -> [dynamic]i32,
	select_bombarding_territory: proc(
		self: ^Player,
		unit: ^Unit,
		unit_territory: ^Territory,
		territories: [dynamic]^Territory,
		none_available: bool,
	) -> ^Territory,
        get_number_of_fighters_to_move_to_new_carrier: proc(
                self: ^Player,
                fighters_that_can_be_moved: [dynamic]^Unit,
                from: ^Territory,
        ) -> [dynamic]^Unit,
        select_territory_for_air_to_land: proc(
                self: ^Player,
                candidates: [dynamic]^Territory,
                current_territory: ^Territory,
                unit_message: string,
        ) -> ^Territory,
}

// games.strategy.engine.player.Player#getNumberOfFightersToMoveToNewCarrier(Collection, Territory)
//   Vtable dispatch through the proc field. AI implementations
//   (AbstractAi, AbstractProAi, DummyPlayer) all default to returning
//   null in Java; absent dispatch (nil field) is treated as such and
//   yields an empty list — the caller checks "null or empty" anyway.
player_get_number_of_fighters_to_move_to_new_carrier :: proc(
        self: ^Player,
        fighters_that_can_be_moved: [dynamic]^Unit,
        from: ^Territory,
) -> [dynamic]^Unit {
        if self != nil && self.get_number_of_fighters_to_move_to_new_carrier != nil {
                return self.get_number_of_fighters_to_move_to_new_carrier(self, fighters_that_can_be_moved, from)
        }
        return make([dynamic]^Unit)
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

// games.strategy.engine.player.Player#selectFixedDice(int,int,String,int)
//   Vtable dispatch. AI/snapshot harness implementations may leave
//   the field nil; the Java contract on those impls returns an empty
//   array (or a deterministic array of zeros) — we mirror the latter
//   so callers iterating `dice[i]` get well-defined zero rolls.
player_select_fixed_dice :: proc(
	self: ^Player,
	num_dice: i32,
	hit_at: i32,
	title: string,
	dice_sides: i32,
) -> [dynamic]i32 {
	if self != nil && self.select_fixed_dice != nil {
		return self.select_fixed_dice(self, num_dice, hit_at, title, dice_sides)
	}
	out := make([dynamic]i32, num_dice)
	return out
}

// games.strategy.engine.player.Player#selectTerritoryForAirToLand(java.util.Collection,games.strategy.engine.data.Territory,java.lang.String)
//   Vtable dispatch through the proc field. AI/snapshot harness
//   implementations may leave the field nil; mirroring Java's
//   "deterministic non-null fallback" for headless runs we return the
//   first candidate (or nil if there are none) so the caller's null-fallback
//   in BattleDelegate#checkDefendingPlanesCanLand still has well-defined
//   behaviour.
player_select_territory_for_air_to_land :: proc(
	self: ^Player,
	candidates: [dynamic]^Territory,
	current_territory: ^Territory,
	unit_message: string,
) -> ^Territory {
	if self != nil && self.select_territory_for_air_to_land != nil {
		return self.select_territory_for_air_to_land(self, candidates, current_territory, unit_message)
	}
	if len(candidates) > 0 {
		return candidates[0]
	}
	return nil
}

