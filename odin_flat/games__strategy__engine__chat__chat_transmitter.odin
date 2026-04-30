package game

// Java owner: games.strategy.engine.chat.ChatTransmitter (interface)
//
// Pure-callback interface modeled as a struct of proc-typed fields;
// concrete implementers install their functions at construction time.
// Dispatch procs (`chat_transmitter_*`) are the public entry points.

Chat_Transmitter :: struct {
	set_chat_client:     proc(self: ^Chat_Transmitter, chat_client: ^Chat_Client),
	connect:             proc(self: ^Chat_Transmitter) -> [dynamic]^Chat_Participant,
	disconnect:          proc(self: ^Chat_Transmitter),
	send_message:        proc(self: ^Chat_Transmitter, message: string),
	slap:                proc(self: ^Chat_Transmitter, user_name: ^User_Name),
	update_status:       proc(self: ^Chat_Transmitter, status: string),
	get_local_user_name: proc(self: ^Chat_Transmitter) -> ^User_Name,
}

// games.strategy.engine.chat.ChatTransmitter#setChatClient(games.strategy.engine.chat.ChatClient)
chat_transmitter_set_chat_client :: proc(self: ^Chat_Transmitter, chat_client: ^Chat_Client) {
	self.set_chat_client(self, chat_client)
}

// games.strategy.engine.chat.ChatTransmitter#connect()
chat_transmitter_connect :: proc(self: ^Chat_Transmitter) -> [dynamic]^Chat_Participant {
	return self.connect(self)
}

// games.strategy.engine.chat.ChatTransmitter#disconnect()
chat_transmitter_disconnect :: proc(self: ^Chat_Transmitter) {
	self.disconnect(self)
}

// games.strategy.engine.chat.ChatTransmitter#sendMessage(java.lang.String)
chat_transmitter_send_message :: proc(self: ^Chat_Transmitter, message: string) {
	self.send_message(self, message)
}

// games.strategy.engine.chat.ChatTransmitter#slap(org.triplea.domain.data.UserName)
chat_transmitter_slap :: proc(self: ^Chat_Transmitter, user_name: ^User_Name) {
	self.slap(self, user_name)
}

// games.strategy.engine.chat.ChatTransmitter#updateStatus(java.lang.String)
chat_transmitter_update_status :: proc(self: ^Chat_Transmitter, status: string) {
	self.update_status(self, status)
}

// games.strategy.engine.chat.ChatTransmitter#getLocalUserName()
chat_transmitter_get_local_user_name :: proc(self: ^Chat_Transmitter) -> ^User_Name {
	return self.get_local_user_name(self)
}

