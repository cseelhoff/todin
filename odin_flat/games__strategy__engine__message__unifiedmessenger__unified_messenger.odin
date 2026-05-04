package game

import "core:fmt"

// Tagged union of message payloads dispatched by Unified_Messenger's
// messageReceived. Mirrors Java's `instanceof` chain over Serializable
// in the spoke-side `messageReceived(Serializable, INode)`.
Unified_Messenger_Message :: union {
	^Spoke_Invoke,
	^Spoke_Invocation_Results,
}

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

// Java: lambda$processMessage$0 — the AsyncRunner.runAsync runnable
//   () -> {
//     List<RemoteMethodCallResults> results =
//         local.invokeLocal(invoke.call, methodRunNumber, invoke.getInvoker());
//     if (invoke.needReturnValues) {
//       RemoteMethodCallResults result = (results.size() == 1)
//           ? results.get(0)
//           : new RemoteMethodCallResults(new IllegalStateException(
//               "Invalid result count '" + results.size() + "' for end point '" + local + "'"));
//       send(new HubInvocationResults(result, invoke.methodCallId), from);
//     }
//   }
// Captured environment: this (self), local (end_point), invoke, methodRunNumber, from.
// Snapshot harness is single-threaded; the body runs inline (see
// unified_messenger_process_message above) but the lambda is also exposed
// as a stand-alone proc to mirror the Java method table.
unified_messenger_lambda_process_message_0 :: proc(
	self: ^Unified_Messenger,
	end_point: ^End_Point,
	spoke_invoke: ^Spoke_Invoke,
	method_run_number: i64,
	from: ^I_Node,
) {
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
		hub_results := hub_invocation_results_new(result, spoke_invoke.method_call_id)
		unified_messenger_send(self, hub_results, from)
	}
}

// Java: lambda$processMessage$1 — the .exceptionally(throwable -> { ... }) handler
//   throwable -> {
//     log.error("Exception during execution of client request", throwable);
//     if (invoke.needReturnValues) {
//       try {
//         send(new HubInvocationResults(
//                 new RemoteMethodCallResults(throwable), invoke.methodCallId), from);
//       } catch (RuntimeException e) {
//         log.error("Exception while sending exception to client", throwable);
//       }
//     }
//   }
// Captured environment: this (self), invoke, from. Returns Java's Void.
// Snapshot harness has no async exception path (lambda 0 runs inline), so
// this proc is unreachable in practice; body retained for fidelity to the
// Java method table.
unified_messenger_lambda_process_message_1 :: proc(
	self: ^Unified_Messenger,
	spoke_invoke: ^Spoke_Invoke,
	from: ^I_Node,
	throwable: rawptr,
) {
	if spoke_invoke.need_return_values {
		rmc_results := remote_method_call_results_new_from_throwable(throwable)
		hub_results := hub_invocation_results_new(rmc_results, spoke_invoke.method_call_id)
		unified_messenger_send(self, hub_results, from)
	}
}

// Java: private EndPoint getLocalEndPointOrCreate(RemoteName endPointDescriptor, boolean singleThreaded) {
//         synchronized (endPointMutex) {
//           if (localEndPoints.containsKey(endPointDescriptor.getName())) {
//             return localEndPoints.get(endPointDescriptor.getName());
//           }
//           endPoint = new EndPoint(endPointDescriptor.getName(),
//                                   endPointDescriptor.getClazz(), singleThreaded);
//           localEndPoints.put(endPointDescriptor.getName(), endPoint);
//         }
//         send(new HasEndPointImplementor(endPointDescriptor.getName()), messenger.getServerNode());
//         return endPoint;
//       }
// Snapshot harness is single-threaded; the synchronized block is dropped.
// Remote_Name stores its class as a string (no live `Class` object), so we
// synthesize a Class shim from the recorded class name to feed end_point_new.
// messenger.getServerNode() collapses to nil (I_Messenger has no dispatch
// surface — see unified_messenger_get_local_node above), and the resulting
// `send` is itself a no-op.
unified_messenger_get_local_end_point_or_create :: proc(
	self: ^Unified_Messenger,
	end_point_descriptor: ^Remote_Name,
	single_threaded: bool,
) -> ^End_Point {
	name := remote_name_get_name(end_point_descriptor)
	if existing, ok := self.local_end_points[name]; ok {
		return existing
	}
	class_name := remote_name_get_clazz(end_point_descriptor)
	clazz := class_new(class_name, class_name)
	end_point := end_point_new(name, clazz, single_threaded)
	self.local_end_points[name] = end_point
	msg := has_end_point_implementor_new(name)
	unified_messenger_send(self, msg, nil)
	return end_point
}

// Java: public void invoke(String endPointName, RemoteMethodCall call) {
//         Invoke invoke = new HubInvoke(null, false, call);
//         send(invoke, messenger.getServerNode());
//         EndPoint endPoint;
//         synchronized (endPointMutex) {
//           endPoint = localEndPoints.get(endPointName);
//         }
//         if (endPoint != null) {
//           long number = endPoint.takeANumber();
//           List<RemoteMethodCallResults> results =
//               endPoint.invokeLocal(call, number, getLocalNode());
//           for (RemoteMethodCallResults r : results) {
//             if (r.getException() != null) {
//               log.warn("Remote method call exception: " + r.getException().getMessage(),
//                        r.getException());
//             }
//           }
//         }
//       }
// Fire-and-forget remote invocation plus a synchronous local dispatch.
// messenger.getServerNode() collapses to nil and `send` is a no-op (see
// proc-level comments above). The synchronized block is dropped (single-
// threaded harness). Local results are inspected exactly as in Java —
// non-nil exceptions would be logged, but in the snapshot port we mirror
// Java's "warn-only" path by simply discarding the slot since there is no
// log surface bound here.
unified_messenger_invoke :: proc(
	self: ^Unified_Messenger,
	end_point_name: string,
	call: ^Remote_Method_Call,
) {
	zero: Uuid
	invoke := hub_invoke_new(zero, false, call)
	unified_messenger_send(self, invoke, nil)
	end_point, ok := self.local_end_points[end_point_name]
	if !ok {
		return
	}
	number := end_point_take_a_number(end_point)
	results := end_point_invoke_local(
		end_point,
		call,
		number,
		unified_messenger_get_local_node(self),
	)
	for r in results {
		if r != nil && r.exception != nil {
			// Java: log.warn(...); no-op in port (no bound logger).
		}
	}
}

// Java: private RemoteMethodCallResults invokeAndWaitRemote(RemoteMethodCall remoteCall) {
//         UUID methodCallId = UUID.randomUUID();
//         CountDownLatch latch = new CountDownLatch(1);
//         synchronized (pendingLock) { pendingInvocations.put(methodCallId, latch); }
//         Invoke invoke = new HubInvoke(methodCallId, true, remoteCall);
//         send(invoke, messenger.getServerNode());
//         Interruptibles.await(latch);
//         synchronized (pendingLock) {
//           RemoteMethodCallResults methodCallResults = results.remove(methodCallId);
//           if (methodCallResults == null) { throw new IllegalStateException(...); }
//           return methodCallResults;
//         }
//       }
// Snapshot harness is single-threaded; the synchronized blocks collapse.
// `send` is a no-op (see above) so no remote node ever populates `results`,
// and the latch await returns immediately (latch_await is a no-op shim).
// Java would then throw IllegalStateException — we mirror that with panic.
unified_messenger_invoke_and_wait_remote :: proc(
	self: ^Unified_Messenger,
	remote_call: ^Remote_Method_Call,
) -> ^Remote_Method_Call_Results {
	method_call_id := uuid_random_uuid()
	latch := count_down_latch_new(1)
	self.pending_invocations[method_call_id] = latch
	invoke := hub_invoke_new(method_call_id, true, remote_call)
	unified_messenger_send(self, invoke, nil)
	interruptibles_await_latch(latch)
	method_call_results, ok := self.results[method_call_id]
	if ok {
		delete_key(&self.results, method_call_id)
	}
	if !ok {
		panic(fmt.tprintf(
			"No results from remote call. Method returned:%s for remote name:%s with id:%v",
			remote_method_call_get_method_name(remote_call),
			remote_method_call_get_remote_name(remote_call),
			method_call_id,
		))
	}
	return method_call_results
}


// Java: private void send(Serializable msg, INode to) {
//         if (messenger.getLocalNode().equals(to)) hub.messageReceived(msg, getLocalNode());
//         else messenger.send(msg, to);
//       }
// I_Messenger has no dispatch surface in the port (see
// unified_messenger_hub_new), so messenger.getLocalNode() is nil and
// messenger.send is a no-op; the hub-local branch likewise collapses
// (matching the convention in unified_messenger_hub_send). Body
// retained so callers below preserve their structural shape.
unified_messenger_send :: proc(
	self: ^Unified_Messenger,
	msg: Unified_Messenger_Hub_Message,
	to: ^I_Node,
) {
	_ = self
	_ = msg
	_ = to
}

// Java: public void messageReceived(Serializable msg, INode from) {
//         if (msg instanceof SpokeInvoke invoke) {
//           assertIsServer(from);
//           EndPoint local;
//           synchronized (endPointMutex) {
//             local = localEndPoints.get(invoke.call.getRemoteName());
//           }
//           if (local == null) {
//             if (invoke.needReturnValues) {
//               send(new HubInvocationResults(
//                       new RemoteMethodCallResults(
//                           new RemoteNotFoundException("No implementors for ...")),
//                       invoke.methodCallId), from);
//             }
//             return;
//           }
//           processMessage(local, invoke, from);
//         } else if (msg instanceof SpokeInvocationResults sir) {
//           assertIsServer(from);
//           UUID methodId = sir.methodCallId;
//           synchronized (pendingLock) {
//             results.put(methodId, sir.results);
//             CountDownLatch latch = pendingInvocations.remove(methodId);
//             checkNotNull(latch, ...);
//             latch.countDown();
//           }
//         }
//       }
// Snapshot harness is single-threaded; we drop the synchronized
// blocks. Spoke_Invoke and Spoke_Invocation_Results are the only two
// payloads the spoke side observes (mirroring Java's instanceof chain),
// modeled here as a tagged union.
unified_messenger_message_received :: proc(
	self: ^Unified_Messenger,
	msg: Unified_Messenger_Message,
	from: ^I_Node,
) {
	switch m in msg {
	case ^Spoke_Invoke:
		unified_messenger_assert_is_server(self, from)
		remote_name := remote_method_call_get_remote_name(m.call)
		local, ok := self.local_end_points[remote_name]
		if !ok {
			local = nil
		}
		if local == nil {
			if m.need_return_values {
				err_msg := fmt.tprintf(
					"No implementors for %p, inode: %p, msg: %p",
					m.call,
					from,
					m,
				)
				rmc_results := remote_method_call_results_new_from_throwable(
					rawptr(remote_not_found_exception_new(err_msg)),
				)
				hub_results := hub_invocation_results_new(rmc_results, m.method_call_id)
				unified_messenger_send(self, hub_results, from)
			}
			return
		}
		unified_messenger_process_message(self, local, m, from)
	case ^Spoke_Invocation_Results:
		unified_messenger_assert_is_server(self, from)
		method_id := m.method_call_id
		self.results[method_id] = m.results
		latch, ok := self.pending_invocations[method_id]
		if !ok {
			panic(
				fmt.tprintf(
					"method id: %v, was not present in pending invocations: %v",
					method_id,
					self.pending_invocations,
				),
			)
		}
		delete_key(&self.pending_invocations, method_id)
		count_down_latch_count_down(latch)
	}
}

// Java: public void addImplementor(RemoteName endPointDescriptor, Object implementor,
//                                  boolean singleThreaded) {
//         if (!endPointDescriptor.getClazz().isAssignableFrom(implementor.getClass())) {
//           throw new IllegalArgumentException(
//               implementor + " does not implement " + endPointDescriptor.getClazz());
//         }
//         EndPoint endPoint = getLocalEndPointOrCreate(endPointDescriptor, singleThreaded);
//         endPoint.addImplementor(implementor);
//       }
// The isAssignableFrom check has no surface in the port: implementor is
// `rawptr` (Java's Object) with no runtime class info, mirroring the
// "no reflection" rule. We trust the caller (same convention used
// elsewhere in this file) and proceed to create/look up the end point
// and register the implementor.
unified_messenger_add_implementor :: proc(
	self: ^Unified_Messenger,
	end_point_descriptor: ^Remote_Name,
	implementor: rawptr,
	single_threaded: bool,
) {
	end_point := unified_messenger_get_local_end_point_or_create(
		self,
		end_point_descriptor,
		single_threaded,
	)
	end_point_add_implementor(end_point, implementor)
}

// Java: public RemoteMethodCallResults invokeAndWait(String endPointName,
//             RemoteMethodCall remoteCall) throws RemoteNotFoundException {
//         EndPoint local;
//         synchronized (endPointMutex) { local = localEndPoints.get(endPointName); }
//         if (local == null) return invokeAndWaitRemote(remoteCall);
//         long number = local.takeANumber();
//         List<RemoteMethodCallResults> results =
//             local.invokeLocal(remoteCall, number, getLocalNode());
//         if (results.isEmpty()) {
//           throw new RemoteNotFoundException(
//               "Not found:" + endPointName
//                   + ", method name: " + remoteCall.getMethodName()
//                   + ", remote name: " + remoteCall.getRemoteName());
//         }
//         if (results.size() > 1) {
//           throw new IllegalStateException("Too many implementors, got back: " + results);
//         }
//         return results.get(0);
//       }
// Synchronized block dropped (single-threaded snapshot harness, same
// convention as invoke_and_wait_remote / invoke above). Java's checked
// RemoteNotFoundException and IllegalStateException are surfaced via
// panic, matching invoke_and_wait_remote's existing convention in this
// file.
unified_messenger_invoke_and_wait :: proc(
	self: ^Unified_Messenger,
	end_point_name: string,
	remote_call: ^Remote_Method_Call,
) -> ^Remote_Method_Call_Results {
	local, ok := self.local_end_points[end_point_name]
	if !ok {
		return unified_messenger_invoke_and_wait_remote(self, remote_call)
	}
	number := end_point_take_a_number(local)
	results := end_point_invoke_local(
		local,
		remote_call,
		number,
		unified_messenger_get_local_node(self),
	)
	if len(results) == 0 {
		panic(fmt.tprintf(
			"Not found:%s, method name: %s, remote name: %s",
			end_point_name,
			remote_method_call_get_method_name(remote_call),
			remote_method_call_get_remote_name(remote_call),
		))
	}
	if len(results) > 1 {
		panic(fmt.tprintf("Too many implementors, got back: %v", results))
	}
	return results[0]
}
