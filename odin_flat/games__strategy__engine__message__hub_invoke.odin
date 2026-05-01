package game

// Java owners covered by this file:
//   - games.strategy.engine.message.HubInvoke

Hub_Invoke :: struct {
	using invoke: Invoke,
}

// Mirrors `HubInvoke(UUID, boolean, RemoteMethodCall)` which delegates to
// `Invoke(UUID, boolean, RemoteMethodCall)`.
hub_invoke_new :: proc(
	method_call_id: Uuid,
	need_return_values: bool,
	call: ^Remote_Method_Call,
) -> ^Hub_Invoke {
	zero: Uuid
	if need_return_values && method_call_id == zero {
		panic("Cant have no id and need return values")
	}
	if !need_return_values && method_call_id != zero {
		panic("Cant have id and not need return values")
	}
	self := new(Hub_Invoke)
	self.invoke.method_call_id = method_call_id
	self.invoke.need_return_values = need_return_values
	self.invoke.call = call
	return self
}
