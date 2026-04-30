package game

import "core:fmt"

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

// Synthetic lambda: `throwable -> log.warn("Error updating status", throwable)`
// Source: MessengersChatTransmitter.updateStatus, passed to
// AsyncRunner.runAsync(...).exceptionally(...). The slf4j `log.warn(msg, t)`
// call maps to a stderr write here (same convention as the rest of the port).
messengers_chat_transmitter_lambda_update_status_8 :: proc(throwable: ^Throwable) {
	if throwable != nil {
		fmt.eprintln("Error updating status", throwable.message)
	} else {
		fmt.eprintln("Error updating status")
	}
}

messengers_chat_transmitter_get_messengers :: proc(self: ^Messengers_Chat_Transmitter) -> ^Messengers {
	return self.messengers
}

