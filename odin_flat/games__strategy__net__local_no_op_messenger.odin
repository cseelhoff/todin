package game

// Java owner: games.strategy.net.LocalNoOpMessenger
// Phase A: type only.

Local_No_Op_Messenger :: struct {
	node: ^I_Node,
}

local_no_op_messenger_is_server :: proc(self: ^Local_No_Op_Messenger) -> bool {
	return true
}

local_no_op_messenger_get_local_node :: proc(self: ^Local_No_Op_Messenger) -> ^I_Node {
	return self.node
}

local_no_op_messenger_get_server_node :: proc(self: ^Local_No_Op_Messenger) -> ^I_Node {
	return self.node
}

local_no_op_messenger_add_connection_change_listener :: proc(self: ^Local_No_Op_Messenger, listener: ^I_Connection_Change_Listener) {
}

local_no_op_messenger_add_message_listener :: proc(self: ^Local_No_Op_Messenger, listener: ^I_Message_Listener) {
}

