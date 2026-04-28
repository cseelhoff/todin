package game

// games.strategy.engine.data.PlayerList
//
// All players in the game, keyed by name (also keeps insertion order via
// the dynamic array for iteration parity with Java's List<GamePlayer>).

Player_List :: struct {
	players: map[string]^Game_Player,
	order:   [dynamic]^Game_Player,
}
