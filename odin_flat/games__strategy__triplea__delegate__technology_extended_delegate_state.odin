package game

Technology_Extended_Delegate_State :: struct {
	super_state:         rawptr,
	need_to_initialize:  bool,
	techs:               map[^Game_Player][dynamic]^Tech_Advance,
}

technology_extended_delegate_state_new :: proc() -> ^Technology_Extended_Delegate_State {
	self := new(Technology_Extended_Delegate_State)
	self.super_state = nil
	self.need_to_initialize = false
	self.techs = make(map[^Game_Player][dynamic]^Tech_Advance)
	return self
}
