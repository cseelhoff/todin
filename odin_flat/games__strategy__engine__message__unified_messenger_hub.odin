package game

Unified_Messenger_Hub :: struct {
	local_unified:    ^Unified_Messenger,
	messenger:        ^I_Messenger,
	end_points:       map[string][dynamic]^I_Node,
	end_point_mutex:  rawptr,
	invocations:      map[Uuid]^Invocation_In_Progress,
}

unified_messenger_hub_lambda_message_received_0 :: proc(k: string) -> [dynamic]^I_Node {
	return make([dynamic]^I_Node)
}

unified_messenger_hub_new :: proc(messenger: ^I_Messenger, local_unified: ^Unified_Messenger) -> ^Unified_Messenger_Hub {
	self := new(Unified_Messenger_Hub)
	self.messenger = messenger
	self.local_unified = local_unified
	self.end_points = make(map[string][dynamic]^I_Node)
	self.invocations = make(map[Uuid]^Invocation_In_Progress)
	// Java: this.messenger.addMessageListener(this) and addConnectionChangeListener(this).
	// I_Messenger is an empty interface shim with no dispatch surface in the port,
	// so listener registration is a no-op here.
	return self
}

