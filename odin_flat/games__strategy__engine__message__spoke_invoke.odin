package game

// Java owners covered by this file:
//   - games.strategy.engine.message.SpokeInvoke

Spoke_Invoke :: struct {
	using invoke: Invoke,
	invoker:      ^I_Node,
}

// Mirrors `SpokeInvoke(UUID, boolean, RemoteMethodCall, INode)` which
// delegates to `Invoke(UUID, boolean, RemoteMethodCall)` and stores the
// invoker node.
spoke_invoke_new :: proc(
	method_call_id: Uuid,
	need_return_values: bool,
	call: ^Remote_Method_Call,
	invoker: ^I_Node,
) -> ^Spoke_Invoke {
	zero: Uuid
	if need_return_values && method_call_id == zero {
		panic("Cant have no id and need return values")
	}
	if !need_return_values && method_call_id != zero {
		panic("Cant have id and not need return values")
	}
	self := new(Spoke_Invoke)
	self.invoke.method_call_id = method_call_id
	self.invoke.need_return_values = need_return_values
	self.invoke.call = call
	self.invoker = invoker
	return self
}

spoke_invoke_get_invoker :: proc(self: ^Spoke_Invoke) -> ^I_Node {
	return self.invoker
}
