package game

// Java owner: games.strategy.net.websocket.ClientNetworkBridge$1
//
// First anonymous inner class of ClientNetworkBridge — the NO_OP_SENDER
// implementation. No captured fields; only method overrides (Phase B).

Client_Network_Bridge_1 :: struct {
	using client_network_bridge: Client_Network_Bridge,
}

// addListener(MessageType<T>, Consumer<T>) — NO_OP_SENDER override; intentionally empty.
client_network_bridge_1_add_listener :: proc(
	self: ^Client_Network_Bridge_1,
	message_type: ^Message_Type,
	message_consumer: proc(rawptr, rawptr),
	message_consumer_ctx: rawptr,
) {
}

client_network_bridge_1_new :: proc() -> ^Client_Network_Bridge_1 {
	return new(Client_Network_Bridge_1)
}

