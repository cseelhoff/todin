package game

Delegate_History_Writer :: struct {
	channel:   ^I_Game_Modified_Channel,
	game_data: ^Game_Data,
}

// Java owners covered by this file:
//   - games.strategy.engine.history.DelegateHistoryWriter

@(private="file")
delegate_history_writer_new_internal :: proc(channel: ^I_Game_Modified_Channel, game_data: ^Game_Data) -> ^Delegate_History_Writer {
	self := new(Delegate_History_Writer)
	self.channel = channel
	self.game_data = game_data
	return self
}

// games.strategy.engine.history.DelegateHistoryWriter#<init>(games.strategy.engine.message.IChannelMessenger,games.strategy.engine.data.GameData)
delegate_history_writer_new :: proc(messenger: ^I_Channel_Messenger, game_data: ^Game_Data) -> ^Delegate_History_Writer {
	assert(game_data != nil)
	channel := cast(^I_Game_Modified_Channel)i_channel_messenger_get_channel_broadcaster(
		messenger,
		"games.strategy.engine.framework.IGame.GAME_MODIFICATION_CHANNEL",
	)
	return delegate_history_writer_new_internal(channel, game_data)
}

// games.strategy.engine.history.DelegateHistoryWriter#createNoOpImplementation()
delegate_history_writer_create_no_op_implementation :: proc() -> ^Delegate_History_Writer {
	return delegate_history_writer_new_internal(nil, nil)
}

