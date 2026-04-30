package game

// Ported from games.strategy.engine.chat.IChatChannel$SlapMessage

I_Chat_Channel_Slap_Message :: struct {
	to: ^User_Name,
}

make_I_Chat_Channel_Slap_Message :: proc(to: ^User_Name) -> I_Chat_Channel_Slap_Message {
	return I_Chat_Channel_Slap_Message{to = to}
}
