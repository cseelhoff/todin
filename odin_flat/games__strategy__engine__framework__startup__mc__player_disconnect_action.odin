package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.startup.mc.PlayerDisconnectAction

Player_Disconnect_Action :: struct {
	messenger:         ^I_Server_Messenger,
	shutdown_callback: proc(),
}

