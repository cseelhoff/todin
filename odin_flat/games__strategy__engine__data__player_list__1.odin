package game

// Anonymous inner class: games.strategy.engine.data.PlayerList$1
// Source: PlayerList.createNullPlayer -> new GamePlayer(...) { isNull() = true }
// No captured locals; overrides isNull() only.
Player_List_1 :: struct {
	using game_player: Game_Player,
}

// Java: anonymous `new GamePlayer(name, true, false, null, false, data) { ... }`.
// Mirrors GamePlayer's six-arg constructor; only behavioral override is isNull().
player_list_1_new :: proc(
	name: string,
	optional: bool,
	can_be_disabled: bool,
	default_type: string,
	hidden: bool,
	game_data: ^Game_Data,
) -> ^Player_List_1 {
	self := new(Player_List_1)
	parent := game_player_new(name, optional, can_be_disabled, default_type, hidden, game_data)
	self.game_player = parent^
	free(parent)
	return self
}

player_list_1_is_null :: proc(self: ^Player_List_1) -> bool {
	return true
}

