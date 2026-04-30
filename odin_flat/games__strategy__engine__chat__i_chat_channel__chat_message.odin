package game

// Ported from games.strategy.engine.chat.IChatChannel$ChatMessage

I_Chat_Channel_Chat_Message :: struct {
	message: string,
}

make_I_Chat_Channel_Chat_Message :: proc(message: string) -> I_Chat_Channel_Chat_Message {
	return I_Chat_Channel_Chat_Message{message = message}
}

