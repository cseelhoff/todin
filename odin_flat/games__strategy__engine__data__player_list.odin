package game

// games.strategy.engine.data.PlayerList
//
// Wrapper around the set of players in a game.

Player_List :: struct {
	using parent: Game_Data_Component,
	players:      map[string]^Game_Player,
	null_player:  ^Game_Player,
}
