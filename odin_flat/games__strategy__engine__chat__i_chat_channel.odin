package game

// Java owner: games.strategy.engine.chat.IChatChannel
//
// Java declares IChatChannel as a pure-callback interface (extends
// IChannelSubscriber) with no fields. Each abstract method is modeled
// as a proc-typed field; concrete implementers install their function
// at construction time. Dispatch procs (`i_chat_channel_*`) are the
// public entry points.

I_Chat_Channel :: struct {
	chat_occurred: proc(self: ^I_Chat_Channel, message: string),
	slap_occurred: proc(self: ^I_Chat_Channel, user_name: ^User_Name),
	speaker_added: proc(self: ^I_Chat_Channel, chat_participant: ^Chat_Participant),
	speaker_removed: proc(self: ^I_Chat_Channel, user_name: ^User_Name),
	ping:          proc(self: ^I_Chat_Channel),
	status_changed: proc(self: ^I_Chat_Channel, user_name: ^User_Name, status: string),
}

// games.strategy.engine.chat.IChatChannel#chatOccurred(java.lang.String)
i_chat_channel_chat_occurred :: proc(self: ^I_Chat_Channel, message: string) {
	self.chat_occurred(self, message)
}

// games.strategy.engine.chat.IChatChannel#slapOccurred(org.triplea.domain.data.UserName)
i_chat_channel_slap_occurred :: proc(self: ^I_Chat_Channel, user_name: ^User_Name) {
	self.slap_occurred(self, user_name)
}

// games.strategy.engine.chat.IChatChannel#speakerAdded(org.triplea.domain.data.ChatParticipant)
i_chat_channel_speaker_added :: proc(self: ^I_Chat_Channel, chat_participant: ^Chat_Participant) {
	self.speaker_added(self, chat_participant)
}

// games.strategy.engine.chat.IChatChannel#speakerRemoved(org.triplea.domain.data.UserName)
i_chat_channel_speaker_removed :: proc(self: ^I_Chat_Channel, user_name: ^User_Name) {
	self.speaker_removed(self, user_name)
}

// games.strategy.engine.chat.IChatChannel#ping()
i_chat_channel_ping :: proc(self: ^I_Chat_Channel) {
	self.ping(self)
}

// games.strategy.engine.chat.IChatChannel#statusChanged(org.triplea.domain.data.UserName,java.lang.String)
i_chat_channel_status_changed :: proc(self: ^I_Chat_Channel, user_name: ^User_Name, status: string) {
	self.status_changed(self, user_name, status)
}

