package game

// Java owners covered by this file:
//   - games.strategy.engine.chat.IChatController$SetChatStatusMessage

Set_Chat_Status_Message :: struct {
	status: string,
}

make_I_Chat_Controller_Set_Chat_Status_Message :: proc(status: string) -> Set_Chat_Status_Message {
	return Set_Chat_Status_Message{status = status}
}

