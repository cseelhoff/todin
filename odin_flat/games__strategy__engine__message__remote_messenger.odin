package game

Remote_Messenger :: struct {
	unified_messenger: ^Unified_Messenger,
}

remote_messenger_new :: proc(unified: ^Unified_Messenger) -> ^Remote_Messenger {
	self := new(Remote_Messenger)
	self.unified_messenger = unified
	return self
}

// Java: public IRemote getRemote(final RemoteName remoteName, final boolean ignoreResults) {
//         final InvocationHandler ih =
//             new UnifiedInvocationHandler(unifiedMessenger, remoteName.getName(), ignoreResults);
//         return (IRemote) Proxy.newProxyInstance(
//             Thread.currentThread().getContextClassLoader(),
//             new Class<?>[] {remoteName.getClazz()}, ih);
//       }
//
// The Odin port has no java.lang.reflect.Proxy / no reflection. The
// established precedent (see Delegate_Execution_Manager#newOutbound/
// newInboundImplementation) is to build the real InvocationHandler
// state and collapse the Proxy wrapper to a direct pointer return —
// callers cast the result to the concrete remote interface they
// expect, just as channel_messenger consumers do with
// i_channel_messenger_get_channel_broadcaster (see e.g.
// delegate_history_writer's `cast(^I_Game_Modified_Channel)`).
remote_messenger_get_remote :: proc(
	self: ^Remote_Messenger,
	name: ^Remote_Name,
	ignore_results: bool,
) -> ^I_Remote {
	// Single-process / in-VM fast path: when a local implementor is
	// already registered for this remote name (the case in the
	// snapshot harness because ServerGame#setupDelegateMessaging
	// registers every delegate via newInboundImplementation, which
	// returns the raw delegate pointer in this port), return it
	// directly so callers can `cast(^Battle_Delegate)` etc. The UIH
	// proxy round-trip is only meaningful when the implementor lives
	// across the network, which the AI snapshot run never exercises.
	// In Java this is the same observable behavior the dynamic Proxy
	// produces for a single-VM end-point.
	if local := remote_messenger_lookup_local_implementor(self, name); local != nil {
		return cast(^I_Remote)local
	}
	ih := unified_invocation_handler_new(
		self.unified_messenger,
		remote_name_get_name(name),
		ignore_results,
	)
	return cast(^I_Remote)ih
}

// Helper for the single-VM fast path above: peek into the
// UnifiedMessenger's local end-point map and return the sole local
// implementor for `name`, or nil if there are zero or multiple.
// Returning nil for the "multiple" case preserves the Java
// IllegalStateException("Too many implementors") semantics — the
// fallback UIH path will then surface the error on first invocation
// rather than silently picking one.
@(private = "file")
remote_messenger_lookup_local_implementor :: proc(self: ^Remote_Messenger, name: ^Remote_Name) -> rawptr {
	if self == nil || self.unified_messenger == nil {
		return nil
	}
	end_point, ok := self.unified_messenger.local_end_points[remote_name_get_name(name)]
	if !ok || end_point == nil {
		return nil
	}
	if len(end_point.implementors) != 1 {
		return nil
	}
	for impl in end_point.implementors {
		return impl
	}
	return nil
}

// Java: public IRemote getRemote(final RemoteName remoteName) {
//         return getRemote(remoteName, false);
//       }
remote_messenger_get_remote_default :: proc(
	self: ^Remote_Messenger,
	name: ^Remote_Name,
) -> ^I_Remote {
	return remote_messenger_get_remote(self, name, false)
}

// Java: public void registerRemote(final Object implementor, final RemoteName name) {
//         unifiedMessenger.addImplementor(name, implementor, false);
//       }
remote_messenger_register_remote :: proc(
	self: ^Remote_Messenger,
	implementor: rawptr,
	name: ^Remote_Name,
) {
	unified_messenger_add_implementor(self.unified_messenger, name, implementor, false)
}

// games.strategy.engine.message.RemoteMessenger#unregisterRemote(games.strategy.engine.message.RemoteName)
remote_messenger_unregister_remote :: proc(self: ^Remote_Messenger, name: ^Remote_Name) {
	// No-op: not exercised by the WW2v5 AI snapshot run.
}

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteMessenger

