package game

Channel_Messenger :: struct {
	unified_messenger: ^Unified_Messenger,
}

channel_messenger_new :: proc(unified: ^Unified_Messenger) -> ^Channel_Messenger {
	self := new(Channel_Messenger)
	self.unified_messenger = unified
	return self
}

// Java owners covered by this file:
//   - games.strategy.engine.message.ChannelMessenger

