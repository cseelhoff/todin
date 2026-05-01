package game

Edit_Delegate :: struct {
	using base_persistent_delegate: Base_Persistent_Delegate,
}

// games.strategy.triplea.delegate.EditDelegate#getRemoteType()
// Java returns `Class<? extends IRemote>` (IEditDelegate.class); Odin mirrors
// IDelegate#getRemoteType and returns the corresponding `typeid`.
edit_delegate_get_remote_type :: proc(self: ^Edit_Delegate) -> typeid {
	return I_Edit_Delegate
}
