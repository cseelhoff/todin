package game

Messengers :: struct {
	messenger:         ^I_Messenger,
	remote_messenger:  ^I_Remote_Messenger,
	channel_messenger: ^I_Channel_Messenger,
}

// Java owners covered by this file:
//   - games.strategy.net.Messengers

// games.strategy.net.Messengers#<init>(games.strategy.net.IMessenger)
// Java:
//   public Messengers(final IMessenger messenger) {
//     this.messenger = messenger;
//     final UnifiedMessenger unifiedMessenger = new UnifiedMessenger(messenger);
//     channelMessenger = new ChannelMessenger(unifiedMessenger);
//     remoteMessenger = new RemoteMessenger(unifiedMessenger);
//   }
// The Messengers struct stores its remote_messenger / channel_messenger as
// opaque ^I_Remote_Messenger / ^I_Channel_Messenger marker pointers (the
// I_* types are empty interface shims in the port). Concrete
// Channel_Messenger / Remote_Messenger pointers are cast to those marker
// types so callers (which dispatch through the i_*_messenger_* helpers)
// see a stable handle.
messengers_new :: proc(messenger: ^I_Messenger) -> ^Messengers {
	self := new(Messengers)
	self.messenger = messenger
	unified := unified_messenger_new(messenger)
	self.channel_messenger = cast(^I_Channel_Messenger)channel_messenger_new(unified)
	self.remote_messenger = cast(^I_Remote_Messenger)remote_messenger_new(unified)
	return self
}

// games.strategy.net.Messengers#getChannelBroadcaster(games.strategy.engine.message.RemoteName)
messengers_get_channel_broadcaster :: proc(self: ^Messengers, channel_name: ^Remote_Name) -> ^I_Channel_Subscriber {
	return i_channel_messenger_get_channel_broadcaster(self.channel_messenger, channel_name)
}

// games.strategy.net.Messengers#getLocalNode()
messengers_get_local_node :: proc(self: ^Messengers) -> ^I_Node {
	return i_messenger_get_local_node(self.messenger)
}

// games.strategy.net.Messengers#getRemote(games.strategy.engine.message.RemoteName)
messengers_get_remote :: proc(self: ^Messengers, name: ^Remote_Name) -> ^I_Remote {
	return i_remote_messenger_get_remote(self.remote_messenger, name)
}

// games.strategy.net.Messengers#getServerNode()
messengers_get_server_node :: proc(self: ^Messengers) -> ^I_Node {
	return i_messenger_get_server_node(self.messenger)
}

// games.strategy.net.Messengers#registerChannelSubscriber(java.lang.Object,games.strategy.engine.message.RemoteName)
messengers_register_channel_subscriber :: proc(self: ^Messengers, implementor: rawptr, channel_name: ^Remote_Name) {
	i_channel_messenger_register_channel_subscriber(self.channel_messenger, implementor, channel_name)
}

// games.strategy.net.Messengers#registerRemote(java.lang.Object,games.strategy.engine.message.RemoteName)
messengers_register_remote :: proc(self: ^Messengers, implementor: rawptr, name: ^Remote_Name) {
	i_remote_messenger_register_remote(self.remote_messenger, implementor, name)
}

// games.strategy.net.Messengers#unregisterChannelSubscriber(java.lang.Object,games.strategy.engine.message.RemoteName)
messengers_unregister_channel_subscriber :: proc(self: ^Messengers, implementor: rawptr, channel_name: ^Remote_Name) {
	i_channel_messenger_unregister_channel_subscriber(self.channel_messenger, implementor, channel_name)
}

// games.strategy.net.Messengers#unregisterRemote(games.strategy.engine.message.RemoteName)
messengers_unregister_remote :: proc(self: ^Messengers, name: ^Remote_Name) {
	i_remote_messenger_unregister_remote(self.remote_messenger, name)
}

// games.strategy.net.Messengers#shutDown()
messengers_shut_down :: proc(self: ^Messengers) {
	// No-op: not exercised by the WW2v5 AI snapshot run.
}

