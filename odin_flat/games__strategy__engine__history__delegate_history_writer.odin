package game

import "core:strings"

@(private="file")
DELEGATE_HISTORY_WRITER_COMMENT_PREFIX :: "COMMENT: "

Delegate_History_Writer :: struct {
	channel:   ^I_Game_Modified_Channel,
	game_data: ^Game_Data,
}

// =============================================================================
// TEST-ONLY DEBUG INSTRUMENTATION
//
// Used by conversion/odin_tests/dep_write_units_to_history. When
// `dbg_history_capture_enabled` is true, every entry into a history-writer
// dispatch records the (kind, text, has_data) tuple in `dbg_history_capture_events`.
// All four dispatchers below honour the flag, but `add_child_to_event(no-data)`
// funnels through `add_child_to_event_with_data`, so a single hook in the
// `_with_data` form captures both call shapes (avoids double-recording).
//
// Behaviour is unchanged when the flag is false; the only cost is one bool
// branch at the top of each dispatcher.
// =============================================================================
Dbg_History_Event :: struct {
	kind:     string,
	text:     string,
	has_data: bool,
}

dbg_history_capture_enabled: bool
dbg_history_capture_events:  [dynamic]Dbg_History_Event

@(private="file")
dbg_history_capture :: proc(kind: string, text: string, has_data: bool) {
	if !dbg_history_capture_enabled {
		return
	}
	append(&dbg_history_capture_events, Dbg_History_Event{
		kind     = kind,
		text     = text,
		has_data = has_data,
	})
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
	// Java: IGame.GAME_MODIFICATION_CHANNEL = new RemoteName(
	//   IGame.class.getName() + ".GAME_MODIFICATION_CHANNEL",
	//   IGameModifiedChannel.class)
	channel := cast(^I_Game_Modified_Channel)i_channel_messenger_get_channel_broadcaster(
		messenger,
		remote_name_new(
			"games.strategy.engine.framework.IGame.GAME_MODIFICATION_CHANNEL",
			class_new("games.strategy.engine.framework.IGameModifiedChannel", "IGameModifiedChannel"),
		),
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

// games.strategy.engine.history.DelegateHistoryWriter#startEvent(java.lang.String,java.lang.Object)
delegate_history_writer_start_event_with_data :: proc(self: ^Delegate_History_Writer, event_name: string, rendering_data: rawptr) {
	dbg_history_capture("start_event", event_name, true)
	if self.channel != nil {
		i_game_modified_channel_start_history_event_with_data(
			self.channel,
			delegate_history_writer_add_prefix_on_edit_mode(self, event_name),
			rendering_data,
		)
	}
}

// games.strategy.engine.history.DelegateHistoryWriter#startEvent(java.lang.String)
delegate_history_writer_start_event :: proc(self: ^Delegate_History_Writer, event_name: string) {
	dbg_history_capture("start_event", event_name, false)
	if self.channel != nil {
		i_game_modified_channel_start_history_event(
			self.channel,
			delegate_history_writer_add_prefix_on_edit_mode(self, event_name),
		)
	}
}

// games.strategy.engine.history.DelegateHistoryWriter#addChildToEvent(java.lang.String,java.lang.Object)
delegate_history_writer_add_child_to_event_with_data :: proc(self: ^Delegate_History_Writer, child: string, rendering_data: rawptr) {
	dbg_history_capture("add_child", child, rendering_data != nil)
	if self.channel != nil {
		i_game_modified_channel_add_child_to_event(
			self.channel,
			delegate_history_writer_add_prefix_on_edit_mode(self, child),
			rendering_data,
		)
	}
}

// games.strategy.engine.history.DelegateHistoryWriter#addChildToEvent(java.lang.String)
delegate_history_writer_add_child_to_event :: proc(self: ^Delegate_History_Writer, child: string) {
	delegate_history_writer_add_child_to_event_with_data(self, child, nil)
}

