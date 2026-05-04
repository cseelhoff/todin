package game

import "core:fmt"

// Tagged union of message payloads dispatched by the hub's
// messageReceived. Mirrors Java's `instanceof` chain over Serializable.
Unified_Messenger_Hub_Message :: union {
	^Has_End_Point_Implementor,
	^No_Longer_Has_End_Point_Implementor,
	^Hub_Invoke,
	^Hub_Invocation_Results,
}

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

// Java: private void send(Serializable msg, INode to) {
//         if (messenger.getLocalNode().equals(to)) localUnified.messageReceived(msg, messenger.getLocalNode());
//         else messenger.send(msg, to);
//       }
// I_Messenger has no dispatch surface in the port (see
// unified_messenger_hub_new), so messenger.send and the local-node
// branch's localUnified.messageReceived both collapse to no-ops. The
// proc is retained so callers below (results / invoke / messageReceived)
// retain their structural shape.
unified_messenger_hub_send :: proc(self: ^Unified_Messenger_Hub, msg: any, to: ^I_Node) {
	_ = self
	_ = msg
	_ = to
}

// Java: public void messageReceived(Serializable msg, INode from) { ... instanceof chain ... }
unified_messenger_hub_message_received :: proc(
	self: ^Unified_Messenger_Hub,
	msg: Unified_Messenger_Hub_Message,
	from: ^I_Node,
) {
	switch m in msg {
	case ^Has_End_Point_Implementor:
		nodes, ok := self.end_points[m.end_point_name]
		if !ok {
			nodes = unified_messenger_hub_lambda_message_received_0(m.end_point_name)
		}
		for n in nodes {
			if n == from {
				panic(
					fmt.tprintf(
						"Already contained, new%p existing, %v name %s",
						from,
						nodes,
						m.end_point_name,
					),
				)
			}
		}
		append(&nodes, from)
		self.end_points[m.end_point_name] = nodes
	case ^No_Longer_Has_End_Point_Implementor:
		nodes, ok := self.end_points[m.end_point_name]
		if ok {
			removed := false
			for i := 0; i < len(nodes); i += 1 {
				if nodes[i] == from {
					ordered_remove(&nodes, i)
					removed = true
					break
				}
			}
			if !removed {
				panic("Not removed!")
			}
			if len(nodes) == 0 {
				delete_key(&self.end_points, m.end_point_name)
			} else {
				self.end_points[m.end_point_name] = nodes
			}
		}
	case ^Hub_Invoke:
		end_point_cols := make([dynamic]^I_Node)
		remote_name := remote_method_call_get_remote_name(m.call)
		if nodes, ok := self.end_points[remote_name]; ok {
			for n in nodes {
				append(&end_point_cols, n)
			}
		}
		// the node will already have routed messages to local invokers
		for i := 0; i < len(end_point_cols); i += 1 {
			if end_point_cols[i] == from {
				ordered_remove(&end_point_cols, i)
				break
			}
		}
		if len(end_point_cols) == 0 {
			if m.need_return_values {
				keys := make([dynamic]string, context.temp_allocator)
				for k, _ in self.end_points {
					append(&keys, k)
				}
				err := remote_not_found_exception_new(
					fmt.tprintf(
						"Not found:%s, endpoints available: %v",
						remote_name,
						keys[:],
					),
				)
				results := remote_method_call_results_new_from_throwable(err)
				unified_messenger_hub_send(
					self,
					spoke_invocation_results_new(results, m.method_call_id),
					from,
				)
			}
			// no end points, this is ok, we are a channel with no implementors
		} else {
			unified_messenger_hub_invoke(self, m, end_point_cols[:], from)
		}
	case ^Hub_Invocation_Results:
		unified_messenger_hub_results(self, m, from)
	}
}

// Java: private void results(HubInvocationResults results, INode from) { ... }
unified_messenger_hub_results :: proc(
	self: ^Unified_Messenger_Hub,
	results: ^Hub_Invocation_Results,
	from: ^I_Node,
) {
	method_id := results.method_call_id
	invocation_in_progress := self.invocations[method_id]
	invocation_in_progress_process(invocation_in_progress, results, from)
	delete_key(&self.invocations, method_id)
	if invocation_in_progress_should_send_results(invocation_in_progress) {
		unified_messenger_hub_send_results_to_caller(self, method_id, invocation_in_progress)
	}
}

// Java: private void sendResultsToCaller(UUID methodId, InvocationInProgress invocationInProgress) { ... }
unified_messenger_hub_send_results_to_caller :: proc(
	self: ^Unified_Messenger_Hub,
	method_id: Uuid,
	invocation_in_progress: ^Invocation_In_Progress,
) {
	result := invocation_in_progress_get_results(invocation_in_progress)
	caller := invocation_in_progress_get_caller(invocation_in_progress)
	spoke_results := spoke_invocation_results_new(result, method_id)
	unified_messenger_hub_send(self, spoke_results, caller)
}

// Java: private void invoke(HubInvoke hubInvoke, Collection<INode> remote, INode from) { ... }
unified_messenger_hub_invoke :: proc(
	self: ^Unified_Messenger_Hub,
	hub_invoke: ^Hub_Invoke,
	remote: []^I_Node,
	from: ^I_Node,
) {
	if hub_invoke.need_return_values {
		if len(remote) != 1 {
			panic(
				fmt.tprintf(
					"Too many nodes: %v for remote name %v",
					remote,
					hub_invoke.call,
				),
			)
		}
		invocation_in_progress := invocation_in_progress_new(remote[0], hub_invoke, from)
		self.invocations[hub_invoke.method_call_id] = invocation_in_progress
	}
	// invoke remotely
	invoke := spoke_invoke_new(
		hub_invoke.method_call_id,
		hub_invoke.need_return_values,
		hub_invoke.call,
		from,
	)
	for node in remote {
		unified_messenger_hub_send(self, invoke, node)
	}
}

