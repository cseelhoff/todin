package game

// Java owners covered by this file:
//   - org.triplea.web.socket.WebSocketMessagingBus$MessageListener

Web_Socket_Messaging_Bus_Message_Listener :: struct {
	message_type: rawptr, // MessageType<T>
	listener:     rawptr, // Consumer<WebSocketMessageContext<T>>
}

