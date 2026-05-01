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

