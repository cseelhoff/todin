package game

Base_Persistent_Delegate :: struct {
	using abstract_delegate: Abstract_Delegate,
}

// games.strategy.triplea.delegate.BasePersistentDelegate#<init>()
// Implicit Java no-arg constructor; just zero-initializes the embedded
// AbstractDelegate state.
base_persistent_delegate_new :: proc() -> ^Base_Persistent_Delegate {
	self := new(Base_Persistent_Delegate)
	return self
}

