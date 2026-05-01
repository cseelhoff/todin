package game

// Ported from games.strategy.engine.display.IDisplay$BroadcastMessageMessage

Broadcast_Message_Message :: struct {
	message: string,
	title:   string,
}

make_I_Display_Broadcast_Message_Message :: proc(message: string, title: string) -> Broadcast_Message_Message {
	return Broadcast_Message_Message{
		message = message,
		title   = title,
	}
}

// Lombok @Builder generated static: BroadcastMessageMessage.builder()
i_display_broadcast_message_message_builder :: proc() -> ^I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder {
	b := new(I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder)
	b^ = I_Display_Broadcast_Message_Message_Broadcast_Message_Message_Builder{}
	return b
}

