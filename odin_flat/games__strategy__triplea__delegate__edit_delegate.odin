package game

Edit_Delegate :: struct {
	using base_persistent_delegate: Base_Persistent_Delegate,
}

// games.strategy.triplea.delegate.EditDelegate#<init>()
// Implicit Java no-arg constructor; zero-initializes the embedded
// BasePersistentDelegate state.
edit_delegate_new :: proc() -> ^Edit_Delegate {
	self := new(Edit_Delegate)
	return self
}

// games.strategy.triplea.delegate.EditDelegate#getEditMode(GameProperties)
// Java: properties.get(Constants.EDIT_MODE) instanceof Boolean && (boolean) editMode.
// Odin: Game_Properties.get returns a Property_Value union; check the bool variant.
edit_delegate_get_edit_mode :: proc(properties: ^Game_Properties) -> bool {
	value := game_properties_get(properties, "EditMode")
	b, ok := value.(bool)
	return ok && b
}

// games.strategy.triplea.delegate.EditDelegate#getRemoteType()
// Java returns `Class<? extends IRemote>` (IEditDelegate.class); Odin mirrors
// IDelegate#getRemoteType and returns the corresponding `typeid`.
edit_delegate_get_remote_type :: proc(self: ^Edit_Delegate) -> typeid {
	return I_Edit_Delegate
}
