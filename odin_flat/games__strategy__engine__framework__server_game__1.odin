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

// games.strategy.engine.framework.ServerGame$1#assertCorrectCaller()
server_game_1_assert_correct_caller :: proc(self: ^Server_Game_1) {
	if message_context_get_sender() != messengers_get_server_node(abstract_game_get_messengers(&self.outer.abstract_game)) {
		panic("Only server can change game data")
	}
}

// games.strategy.engine.framework.ServerGame$1#startHistoryEvent(java.lang.String)
server_game_1_start_history_event :: proc(self: ^Server_Game_1, event: string) {
	server_game_1_assert_correct_caller(self)
	history_writer_start_event(self.history_writer, event)
}

