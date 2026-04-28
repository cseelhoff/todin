package game

// games.strategy.engine.data.RelationshipTracker$RelatedPlayers
//
// Unordered pair of Game_Player pointers used as a map key.

Related_Players :: struct {
	a: ^Game_Player,
	b: ^Game_Player,
}

Related_Players :: struct {
	player1: ^Game_Player,
	player2: ^Game_Player,
}
