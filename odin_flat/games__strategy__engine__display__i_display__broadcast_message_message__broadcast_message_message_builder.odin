package game

// Java owners covered by this file:
//   - games.strategy.engine.display.IDisplay$BroadcastMessageMessage$BroadcastMessageMessageBuilder

I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder :: struct {
	message: string,
	title:   string,
}

make_I_Display_Broadcast_Message_Message_Builder :: proc() -> I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder {
	return I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder{}
}

i_display_broadcast_message_message_broadcast_message_message_builder_message :: proc(self: ^I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder, message: string) -> ^I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder {
	self.message = message
	return self
}

i_display_broadcast_message_message_broadcast_message_message_builder_title :: proc(self: ^I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder, title: string) -> ^I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder {
	self.title = title
	return self
}

