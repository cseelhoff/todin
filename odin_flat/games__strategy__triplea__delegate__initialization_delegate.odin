package game

// Java owner: games.strategy.triplea.delegate.InitializationDelegate

Initialization_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
}

// games.strategy.triplea.delegate.InitializationDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
initialization_delegate_get_remote_type :: proc(self: ^Initialization_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.InitializationDelegate#loadState(java.io.Serializable)
// Restores delegate state from an InitializationExtendedDelegateState.
// Mirrors the Java cast-and-assign, then forwards `superState` to the
// parent delegate's loadState (BaseTripleADelegate has no override, so
// this resolves to AbstractDelegate's via Base_Triple_A_Delegate.load_state).
initialization_delegate_load_state :: proc(
	self: ^Initialization_Delegate,
	state: ^Initialization_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
}

