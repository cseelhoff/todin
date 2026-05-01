package game

Messengers :: struct {
	messenger:         ^I_Messenger,
	remote_messenger:  ^I_Remote_Messenger,
	channel_messenger: ^I_Channel_Messenger,
}

// Java owners covered by this file:
//   - games.strategy.net.Messengers

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

