package game

// Java owners covered by this file:
//   - games.strategy.net.IMessenger

I_Messenger :: struct {}

// games.strategy.net.IMessenger#getServerNode()
i_messenger_get_server_node :: proc(self: ^I_Messenger) -> ^I_Node {
	// No-op: not exercised by the WW2v5 AI snapshot run.
	return nil
}

// games.strategy.net.IMessenger#getLocalNode()
// No-op: not exercised by the WW2v5 AI snapshot run.
i_messenger_get_local_node :: proc(self: ^I_Messenger) -> ^I_Node {
	return nil
}

