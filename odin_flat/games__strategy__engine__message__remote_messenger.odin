package game

Remote_Messenger :: struct {
	unified_messenger: ^Unified_Messenger,
}

remote_messenger_new :: proc(unified: ^Unified_Messenger) -> ^Remote_Messenger {
	self := new(Remote_Messenger)
	self.unified_messenger = unified
	return self
}

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteMessenger

