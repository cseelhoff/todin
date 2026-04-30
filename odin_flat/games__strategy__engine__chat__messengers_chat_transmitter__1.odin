package game

// Java owners covered by this file:
//   - games.strategy.engine.chat.MessengersChatTransmitter$1
//
// Anonymous inner class implementing IChatChannel, returned by
// MessengersChatTransmitter.chatChannelSubscriber(ChatClient). Captures the
// enclosing transmitter's userName and the chatClient parameter.

Messengers_Chat_Transmitter_1 :: struct {
	user_name:   ^User_Name,
	chat_client: ^Chat_Client,
}

make_Messengers_Chat_Transmitter_1 :: proc(
	outer: ^Messengers_Chat_Transmitter,
	chat_client: ^Chat_Client,
) -> ^Messengers_Chat_Transmitter_1 {
	self := new(Messengers_Chat_Transmitter_1)
	self.user_name = outer.user_name
	self.chat_client = chat_client
	return self
}
