package game

// Java owners covered by this file:
//   - games.strategy.engine.message.SpokeInvoke

Spoke_Invoke :: struct {
	using invoke: Invoke,
	invoker:      ^I_Node,
}
