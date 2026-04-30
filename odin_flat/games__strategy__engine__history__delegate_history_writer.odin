package game

Delegate_History_Writer :: struct {
	channel:   ^I_Game_Modified_Channel,
	game_data: ^Game_Data,
}

// Java owners covered by this file:
//   - games.strategy.engine.history.DelegateHistoryWriter

delegate_history_writer_new :: proc(channel: ^I_Game_Modified_Channel, game_data: ^Game_Data) -> ^Delegate_History_Writer {
	self := new(Delegate_History_Writer)
	self.channel = channel
	self.game_data = game_data
	return self
}

