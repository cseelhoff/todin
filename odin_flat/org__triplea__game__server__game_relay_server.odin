package game

// Java owners covered by this file:
//   - org.triplea.game.server.GameRelayServer

Game_Relay_Server :: struct {
	standalone_websocket_server: ^Standalone_Websocket_Server,
	port:                        int,
}
