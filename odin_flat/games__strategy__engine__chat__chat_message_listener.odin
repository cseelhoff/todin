package game

// Java owner: games.strategy.engine.chat.ChatMessageListener (interface)
//
// Pure-callback interface modeled with proc-typed fields installed by
// concrete implementers. Dispatch procs (`chat_message_listener_*`) are
// the public entry points.

Chat_Message_Listener :: struct {
	event_received:   proc(self: ^Chat_Message_Listener, event_text: string),
	message_received: proc(self: ^Chat_Message_Listener, from_player: ^User_Name, chat_message: string),
	slapped:          proc(self: ^Chat_Message_Listener, from: ^User_Name),
	player_joined:    proc(self: ^Chat_Message_Listener, message: string),
	player_left:      proc(self: ^Chat_Message_Listener, message: string),
}

// games.strategy.engine.chat.ChatMessageListener#slapped(org.triplea.domain.data.UserName)
chat_message_listener_slapped :: proc(self: ^Chat_Message_Listener, from: ^User_Name) {
	self.slapped(self, from)
}

// games.strategy.engine.chat.ChatMessageListener#playerJoined(java.lang.String)
chat_message_listener_player_joined :: proc(self: ^Chat_Message_Listener, message: string) {
	self.player_joined(self, message)
}

// games.strategy.engine.chat.ChatMessageListener#eventReceived(java.lang.String)
chat_message_listener_event_received :: proc(self: ^Chat_Message_Listener, event_text: string) {
	self.event_received(self, event_text)
}

// games.strategy.engine.chat.ChatMessageListener#messageReceived(org.triplea.domain.data.UserName,java.lang.String)
chat_message_listener_message_received :: proc(self: ^Chat_Message_Listener, from_player: ^User_Name, chat_message: string) {
	self.message_received(self, from_player, chat_message)
}

// games.strategy.engine.chat.ChatMessageListener#playerLeft(java.lang.String)
chat_message_listener_player_left :: proc(self: ^Chat_Message_Listener, message: string) {
	self.player_left(self, message)
}

