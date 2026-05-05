package game

// Ported from games.strategy.engine.message.IChannelMessenger
I_Channel_Messenger :: struct {}

// Dispatch helpers. The stored pointer always points to a Channel_Messenger
// (the only concrete implementation). Cast and forward.
i_channel_messenger_get_channel_broadcaster :: proc(self: ^I_Channel_Messenger, name: ^Remote_Name) -> ^I_Channel_Subscriber {
	return channel_messenger_get_channel_broadcaster(cast(^Channel_Messenger)self, name)
}

i_channel_messenger_register_channel_subscriber :: proc(self: ^I_Channel_Messenger, subscriber: rawptr, name: ^Remote_Name) {
	channel_messenger_register_channel_subscriber(cast(^Channel_Messenger)self, subscriber, name)
}

i_channel_messenger_unregister_channel_subscriber :: proc(self: ^I_Channel_Messenger, subscriber: rawptr, name: ^Remote_Name) {
	channel_messenger_unregister_channel_subscriber(cast(^Channel_Messenger)self, subscriber, name)
}
