package game

// Java owners covered by this file:
//   - org.triplea.web.socket.WebSocketSessionAdapter$2
//
// Anonymous inner class #2 of WebSocketSessionAdapter, created in
// fromWebSocket(WebSocket); implements WebSocketSession.
// Captures the enclosing 'webSocket' parameter and has its own 'id' field
// (UUID.randomUUID().toString()).

Web_Socket_Session_Adapter_2 :: struct {
	web_socket: rawptr, // captured WebSocket parameter
	id:         string, // UUID.randomUUID().toString()
}
