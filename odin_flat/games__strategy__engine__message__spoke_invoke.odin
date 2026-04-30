package game

// Java owners covered by this file:
//   - games.strategy.engine.message.SpokeInvoke

Spoke_Invoke :: struct {
	using invoke: Invoke,
	invoker:      ^I_Node,
}

spoke_invoke_get_invoker :: proc(self: ^Spoke_Invoke) -> ^I_Node {
	return self.invoker
}
