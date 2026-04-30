package game

// Anonymous inner subclass of GamePlayer used to define NULL_GAME_PLAYER.
// Overrides isNull() to return true; no captured fields.
Game_Player_1 :: struct {
	using base: Game_Player,
}

