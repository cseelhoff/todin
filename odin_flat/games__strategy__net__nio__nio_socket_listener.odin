package game

Nio_Socket_Listener :: struct {
	socket_unquarantined: proc(self: ^Nio_Socket_Listener, channel: ^Socket_Channel, conversation: ^Quarantine_Conversation),
	socket_error:         proc(self: ^Nio_Socket_Listener, channel: ^Socket_Channel, error: ^Exception),
	message_received:     proc(self: ^Nio_Socket_Listener, message: ^Message_Header, channel: ^Socket_Channel),
	get_local_node:       proc(self: ^Nio_Socket_Listener) -> ^I_Node,
}
// Java owners covered by this file:
//   - games.strategy.net.nio.NioSocketListener

