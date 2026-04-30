package game

Web_Socket_Message_Context :: struct {
	messaging_bus:  ^Web_Socket_Messaging_Bus,
	sender_session: ^Web_Socket_Session,
	message:        ^Web_Socket_Message,
}

// One file per Java class. Replace this header when the
// class's structs and procs are fully ported.
// Java owners covered by this file:
//   - org.triplea.web.socket.WebSocketMessageContext

