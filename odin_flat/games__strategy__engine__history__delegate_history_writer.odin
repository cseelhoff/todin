package game

import "core:strings"

@(private="file")
DELEGATE_HISTORY_WRITER_COMMENT_PREFIX :: "COMMENT: "

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

// games.strategy.engine.history.DelegateHistoryWriter#getEventPrefix()
@(private="file")
delegate_history_writer_get_event_prefix :: proc(self: ^Delegate_History_Writer) -> string {
	assert(self.game_data != nil, "If channel is non-null so should gameData")
	if edit_delegate_get_edit_mode(game_data_get_properties(self.game_data)) {
		return "EDIT: "
	}
	return ""
}

// games.strategy.engine.history.DelegateHistoryWriter#addPrefixOnEditMode(java.lang.String)
@(private="file")
delegate_history_writer_add_prefix_on_edit_mode :: proc(self: ^Delegate_History_Writer, event_name: string) -> string {
	if strings.has_prefix(event_name, DELEGATE_HISTORY_WRITER_COMMENT_PREFIX) {
		return event_name
	}
	return strings.concatenate({delegate_history_writer_get_event_prefix(self), event_name})
}

