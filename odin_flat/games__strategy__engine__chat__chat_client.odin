package game

// Java owner: games.strategy.engine.chat.ChatClient (interface)
//
// Java declares ChatClient as a pure-callback interface with no fields.
// Each abstract method is modeled as a proc-typed field; concrete
// implementers install their function at construction time. Dispatch
// procs (`chat_client_*`) are the public entry points.

Chat_Client :: struct {
	event_received:      proc(self: ^Chat_Client, chat_event: string),
	message_received:    proc(self: ^Chat_Client, sender: ^User_Name, message: string),
	participant_added:   proc(self: ^Chat_Client, chat_participant: ^Chat_Participant),
	participant_removed: proc(self: ^Chat_Client, user_name: ^User_Name),
	slapped_by:          proc(self: ^Chat_Client, slapper: ^User_Name),
	status_updated:      proc(self: ^Chat_Client, player: ^User_Name, status: string),
}

// games.strategy.engine.chat.ChatClient#eventReceived(java.lang.String)
chat_client_event_received :: proc(self: ^Chat_Client, chat_event: string) {
	self.event_received(self, chat_event)
}

// games.strategy.engine.chat.ChatClient#messageReceived(org.triplea.domain.data.UserName, java.lang.String)
chat_client_message_received :: proc(self: ^Chat_Client, sender: ^User_Name, message: string) {
	self.message_received(self, sender, message)
}

// games.strategy.engine.chat.ChatClient#participantAdded(org.triplea.domain.data.ChatParticipant)
chat_client_participant_added :: proc(self: ^Chat_Client, chat_participant: ^Chat_Participant) {
	self.participant_added(self, chat_participant)
}

// games.strategy.engine.chat.ChatClient#participantRemoved(org.triplea.domain.data.UserName)
chat_client_participant_removed :: proc(self: ^Chat_Client, user_name: ^User_Name) {
	self.participant_removed(self, user_name)
}

// games.strategy.engine.chat.ChatClient#slappedBy(org.triplea.domain.data.UserName)
chat_client_slapped_by :: proc(self: ^Chat_Client, slapper: ^User_Name) {
	self.slapped_by(self, slapper)
}

// games.strategy.engine.chat.ChatClient#statusUpdated(org.triplea.domain.data.UserName, java.lang.String)
chat_client_status_updated :: proc(self: ^Chat_Client, player: ^User_Name, status: string) {
	self.status_updated(self, player, status)
}
