package game

Tech_Activation_Extended_Delegate_State :: struct {
	super_state:        rawptr,
	need_to_initialize: bool,
}

tech_activation_extended_delegate_state_new :: proc() -> ^Tech_Activation_Extended_Delegate_State {
	self := new(Tech_Activation_Extended_Delegate_State)
	self.super_state = nil
	self.need_to_initialize = false
	return self
}
