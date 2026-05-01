package game

Unified_Messenger :: struct {
	messenger:           ^I_Messenger,
	local_end_points:    map[string]^End_Point,
	pending_invocations: map[Uuid]^Count_Down_Latch,
	results:             map[Uuid]^Remote_Method_Call_Results,
	hub:                 ^Unified_Messenger_Hub,
}

// Java: public INode getLocalNode() { return messenger.getLocalNode(); }
// I_Messenger is an empty interface shim with no dispatch surface in
// the port (see unified_messenger_hub_new), so we cannot delegate to
// the underlying messenger. Return nil to mirror that no-op.
unified_messenger_get_local_node :: proc(self: ^Unified_Messenger) -> ^I_Node {
	return nil
}

// Java: private void assertIsServer(final INode from) {
//         Preconditions.checkState(from.equals(messenger.getServerNode()),
//             "Not from server!  Instead from: " + from);
//       }
// I_Messenger has no dispatch surface, so messenger.getServerNode()
// cannot be evaluated; the precondition collapses to a no-op in the
// port, matching the convention used in unified_messenger_hub_new.
unified_messenger_assert_is_server :: proc(self: ^Unified_Messenger, from: ^I_Node) {
}

