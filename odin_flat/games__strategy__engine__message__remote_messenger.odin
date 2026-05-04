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
	ih := unified_invocation_handler_new(
		self.unified_messenger,
		remote_name_get_name(name),
		ignore_results,
	)
	return cast(^I_Remote)ih
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

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteMessenger

