package game

Server_Game_1 :: struct {
	using parent: I_Game_Modified_Channel,
	history_writer: ^History_Writer,
	outer: ^Server_Game,
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.ServerGame$1

