package game

Move_Extended_Delegate_State :: struct {
	super_state:        rawptr,
	need_to_initialize: bool,
	need_to_do_rockets: bool,
	pus_lost:           ^Integer_Map,
}

