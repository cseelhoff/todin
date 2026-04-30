package game

// Java owners covered by this file:
//   - games.strategy.engine.chat.MessengersChatTransmitter

Messengers_Chat_Transmitter :: struct {
	user_name:               ^User_Name,
	messengers:              ^Messengers,
	chat_channel_subscriber: ^I_Chat_Channel,
	chat_name:               string,
	chat_channel_name:       string,
	client_network_bridge:   ^Client_Network_Bridge,
}

