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

// games.strategy.engine.framework.ServerGame$1#startHistoryEvent(java.lang.String,java.lang.Object)
server_game_1_start_history_event_with_data :: proc(
	self: ^Server_Game_1,
	event: string,
	rendering_data: any,
) {
	server_game_1_start_history_event(self, event)
	if rendering_data.data != nil {
		server_game_1_set_rendering_data(self, rendering_data)
	}
}

// games.strategy.engine.framework.ServerGame$1#gameDataChanged(games.strategy.engine.data.Change)
server_game_1_game_data_changed :: proc(self: ^Server_Game_1, change: ^Change) {
	server_game_1_assert_correct_caller(self)
	game_data_perform_change(self.outer.game_data, change)
	history_writer_add_change(self.history_writer, change)
}

// games.strategy.engine.framework.ServerGame$1#addChildToEvent(java.lang.String,java.lang.Object)
server_game_1_add_child_to_event :: proc(
	self: ^Server_Game_1,
	text: string,
	rendering_data: any,
) {
	server_game_1_assert_correct_caller(self)
	ec := new(Event_Child)
	ec.text = text
	ec.rendering_data = rendering_data
	history_writer_add_child_to_event(self.history_writer, ec)
}

// games.strategy.engine.framework.ServerGame$1#setRenderingData(java.lang.Object)
server_game_1_set_rendering_data :: proc(self: ^Server_Game_1, rendering_data: any) {
	server_game_1_assert_correct_caller(self)
	history_writer_set_rendering_data(self.history_writer, rendering_data)
}

// games.strategy.engine.framework.ServerGame$1#stepChanged(java.lang.String,java.lang.String,games.strategy.engine.data.GamePlayer,int,java.lang.String,boolean)
server_game_1_step_changed :: proc(
	self: ^Server_Game_1,
	step_name: string,
	delegate_name: string,
	player: ^Game_Player,
	round: i32,
	display_name: string,
	loaded_from_saved_game: bool,
) {
	server_game_1_assert_correct_caller(self)
	if loaded_from_saved_game {
		return
	}
	history_writer_start_next_step(
		self.history_writer,
		step_name,
		delegate_name,
		player,
		display_name,
	)
}

