package game

// Java owner: games.strategy.net.websocket.ClientNetworkBridge
//
// Java interface modeled as an Odin struct of function pointers
// (vtable-style). Phase A: type only.

Client_Network_Bridge :: struct {
	send_message: proc(self: ^Client_Network_Bridge, message: ^Web_Socket_Message),
	add_listener: proc(self: ^Client_Network_Bridge, message_type: ^Message_Type, message_consumer: rawptr),
	disconnect:   proc(self: ^Client_Network_Bridge),
}
