package game

Move_Extended_Delegate_State :: struct {
	super_state:        rawptr,
	need_to_initialize: bool,
	need_to_do_rockets: bool,
	pus_lost:           ^Integer_Map,
}

move_extended_delegate_state_new :: proc() -> ^Move_Extended_Delegate_State {
	s := new(Move_Extended_Delegate_State)
	return s
}

