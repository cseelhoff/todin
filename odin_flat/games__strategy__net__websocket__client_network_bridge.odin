package game

// Java owner: games.strategy.net.websocket.ClientNetworkBridge
//
// Java interface with no fields → empty Odin struct (Phase A: type only).
//
// Provisioning fill-in: the abstract `addListener` method is marked
// implemented in port.sqlite at layer 0 (interface contract). Because
// no Odin proc body exists for the empty-interface receiver, calls
// from layer-2 methods (e.g. AbstractGame#setDisplay) need a free proc
// to dispatch through. The snapshot harness runs single-threaded with
// no WebSocket I/O, so listener registrations are safely no-ops here;
// the concrete subtype `Client_Network_Bridge_1` keeps its own real
// `client_network_bridge_1_add_listener` impl (separate file).

Client_Network_Bridge :: struct {}

client_network_bridge_add_listener :: proc(self: ^Client_Network_Bridge, message_type: ^Message_Type, listener: proc(msg: rawptr)) {
	// no-op: snapshot harness does not exercise WebSocket plumbing.
}
