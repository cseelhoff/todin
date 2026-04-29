package game

// Third-party shim: org.java_websocket.server.WebSocketServer.
// Opaque marker — the AI snapshot harness wires up Standalone_Websocket_Server
// at construction time but never accepts a real connection.
Web_Socket_Server :: struct {}

web_socket_server_start :: proc(self: ^Web_Socket_Server) {}

web_socket_server_stop :: proc(self: ^Web_Socket_Server) {}
