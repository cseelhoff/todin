package game

// Java owners covered by this file:
//   - org.triplea.web.socket.WebSocketMessagingBus
//   - org.triplea.web.socket.WebSocketMessagingBus$MessageListener

// WebSocketMessageContext is not in the AI-test reachable set, so it is
// not declared in odin_flat/. The listener's context argument is kept as
// rawptr to preserve the field shape without forcing an out-of-scope port.
Web_Socket_Messaging_Bus_Message_Listener :: struct {
	message_type: ^Message_Type,
	listener:     proc(ctx: rawptr),
}

Web_Socket_Messaging_Bus :: struct {
	message_broadcaster:      ^Message_Broadcaster,
	message_sender:           ^Message_Sender,
	session_set:              ^Session_Set,
	session_closed_listeners: [dynamic]proc(bus: ^Web_Socket_Messaging_Bus, session: ^Web_Socket_Session),
	message_listeners:        [dynamic]^Web_Socket_Messaging_Bus_Message_Listener,
	any_message_listeners:    [dynamic]proc(envelope: ^Message_Envelope),
}
