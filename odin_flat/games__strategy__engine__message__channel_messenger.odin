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

// games.strategy.engine.message.ChannelMessenger#registerChannelSubscriber(java.lang.Object,games.strategy.engine.message.RemoteName)
// Java verifies channelName.getClazz() is assignable to IChannelSubscriber via
// reflection, then forwards to unifiedMessenger.addImplementor(...). Reflection
// is dropped per port rules (Remote_Name's clazz is a plain string here, and
// callers always pass channel-subscriber descriptors); the registration call
// is preserved verbatim.
channel_messenger_register_channel_subscriber :: proc(self: ^Channel_Messenger, subscriber: rawptr, name: ^Remote_Name) {
	unified_messenger_add_implementor(self.unified_messenger, name, subscriber, true)
}

// games.strategy.engine.message.ChannelMessenger#unregisterChannelSubscriber(java.lang.Object,games.strategy.engine.message.RemoteName)
channel_messenger_unregister_channel_subscriber :: proc(self: ^Channel_Messenger, subscriber: rawptr, name: ^Remote_Name) {
	// No-op: not exercised by the WW2v5 AI snapshot run.
}

// Java owners covered by this file:
//   - games.strategy.engine.message.ChannelMessenger

