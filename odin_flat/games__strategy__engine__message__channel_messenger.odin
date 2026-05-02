package game

Channel_Messenger :: struct {
	unified_messenger: ^Unified_Messenger,
}

channel_messenger_new :: proc(unified: ^Unified_Messenger) -> ^Channel_Messenger {
	self := new(Channel_Messenger)
	self.unified_messenger = unified
	return self
}

// games.strategy.engine.message.ChannelMessenger#getChannelBroadcaster(games.strategy.engine.message.RemoteName)
// Java builds a Proxy via Proxy.newProxyInstance backed by a
// UnifiedInvocationHandler bound to (unifiedMessenger, channelName.getName(),
// ignoreResults=true). The Odin port has no reflection; I_Channel_Subscriber
// is an empty marker struct used as an opaque interface pointer. We construct
// the same UnifiedInvocationHandler and return its pointer cast to the
// marker type, so callers (which cast to the specific channel interface)
// receive a stable handle backed by the unified-messenger dispatch helper.
channel_messenger_get_channel_broadcaster :: proc(self: ^Channel_Messenger, name: ^Remote_Name) -> ^I_Channel_Subscriber {
	ih := unified_invocation_handler_new(self.unified_messenger, remote_name_get_name(name), true)
	return cast(^I_Channel_Subscriber)ih
}

// Java owners covered by this file:
//   - games.strategy.engine.message.ChannelMessenger

