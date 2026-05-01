package game

Initialization_Extended_Delegate_State :: struct {
	super_state:        rawptr,
	need_to_initialize: bool,
}

initialization_extended_delegate_state_new :: proc() -> ^Initialization_Extended_Delegate_State {
	self := new(Initialization_Extended_Delegate_State)
	return self
}

