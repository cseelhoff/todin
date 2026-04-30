package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.mc.PlayerDisconnectAction

Player_Disconnect_Action :: struct {
	messenger:         ^I_Server_Messenger,
	shutdown_callback: proc(),
}

make_Player_Disconnect_Action :: proc(messenger: ^I_Server_Messenger, on_disconnect: proc()) -> Player_Disconnect_Action {
	return Player_Disconnect_Action{
		messenger         = messenger,
		shutdown_callback = on_disconnect,
	}
}

