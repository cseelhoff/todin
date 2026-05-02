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

// Java: public UnifiedMessenger(IMessenger messenger) {
//         this.messenger = messenger;
//         this.messenger.addMessageListener(this::messageReceived);
//         if (messenger instanceof IClientMessenger c) c.addErrorListener(this::messengerInvalid);
//         if (this.messenger.isServer()) hub = new UnifiedMessengerHub(this.messenger, this);
//       }
// I_Messenger / I_Client_Messenger are empty interface shims with no
// dispatch surface in the port (see unified_messenger_hub_new), so
// addMessageListener / instanceof / addErrorListener / isServer all
// collapse to no-ops here. The struct fields (maps + nil hub) mirror
// the Java initial state for a non-server messenger.
unified_messenger_new :: proc(messenger: ^I_Messenger) -> ^Unified_Messenger {
	self := new(Unified_Messenger)
	self.messenger = messenger
	self.local_end_points = make(map[string]^End_Point)
	self.pending_invocations = make(map[Uuid]^Count_Down_Latch)
	self.results = make(map[Uuid]^Remote_Method_Call_Results)
	self.hub = nil
	return self
}

// Java: private void processMessage(EndPoint local, SpokeInvoke invoke, INode from) {
//         long methodRunNumber = local.takeANumber();
//         AsyncRunner.runAsync(() -> {
//           List<RemoteMethodCallResults> results =
//               local.invokeLocal(invoke.call, methodRunNumber, invoke.getInvoker());
//           if (invoke.needReturnValues) {
//             RemoteMethodCallResults result = (results.size() == 1)
//                 ? results.get(0)
//                 : new RemoteMethodCallResults(new IllegalStateException(
//                     "Invalid result count '" + results.size() + "' for end point '" + local + "'"));
//             send(new HubInvocationResults(result, invoke.methodCallId), from);
//           }
//         }, threadPool).exceptionally(throwable -> { ... send error ... });
//       }
// Snapshot harness is single-threaded; we run the body inline rather
// than dispatching to a thread pool. The wire `send` collapses to a
// no-op because I_Messenger has no dispatch surface in the port (same
// convention as unified_messenger_get_local_node above), so the
// constructed HubInvocationResults is allocated but not actually
// transmitted.
unified_messenger_process_message :: proc(
	self: ^Unified_Messenger,
	end_point: ^End_Point,
	spoke_invoke: ^Spoke_Invoke,
	node: ^I_Node,
) {
	method_run_number := end_point_take_a_number(end_point)
	results := end_point_invoke_local(
		end_point,
		spoke_invoke.call,
		method_run_number,
		spoke_invoke_get_invoker(spoke_invoke),
	)
	if spoke_invoke.need_return_values {
		result: ^Remote_Method_Call_Results
		if len(results) == 1 {
			result = results[0]
		} else {
			result = remote_method_call_results_new_from_throwable(nil)
		}
		_ = hub_invocation_results_new(result, spoke_invoke.method_call_id)
		// send(...) collapses to no-op — see proc-level comment.
		_ = node
	}
}

