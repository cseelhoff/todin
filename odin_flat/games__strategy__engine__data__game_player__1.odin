package game

// Anonymous inner subclass of GamePlayer used to define NULL_GAME_PLAYER.
// Overrides isNull() to return true; no captured fields.
Game_Player_1 :: struct {
	using parent: Game_Player,
}

// Java: anonymous-class constructor invokes
//   new GamePlayer(name, optional, canBeDisabled, defaultType, isHidden, data)
// with no extra captured state. We mirror that by delegating to
// game_player_new and copying the resulting Game_Player into the embedded base.
game_player_1_new :: proc(
	name: string,
	optional: bool,
	can_be_disabled: bool,
	default_type: string,
	hidden: bool,
	data: ^Game_Data,
) -> ^Game_Player_1 {
	self := new(Game_Player_1)
	parent := game_player_new(name, optional, can_be_disabled, default_type, hidden, data)
	self.parent = parent^
	free(parent)
	return self
}

