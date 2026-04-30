package game

Server_Game_1 :: struct {
	using i_game_modified_channel: I_Game_Modified_Channel,
	history_writer: ^History_Writer,
	outer: ^Server_Game,
}

// Java owners covered by this file:
//   - games.strategy.engine.framework.ServerGame$1

make_Server_Game_1 :: proc(this_0: ^Server_Game, history_writer: ^History_Writer) -> ^Server_Game_1 {
	self := new(Server_Game_1)
	self.outer = this_0
	self.history_writer = history_writer
	return self
}

