package game

Technology_Extended_Delegate_State :: struct {
	super_state:         rawptr,
	need_to_initialize:  bool,
	techs:               map[^Game_Player][dynamic]^Tech_Advance,
}
