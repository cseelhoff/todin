package game

Place_Extended_Delegate_State :: struct {
	super_state: rawptr,
	produced:    map[^Territory][dynamic]^Unit,
	placements:  [dynamic]^Undoable_Placement,
}

place_extended_delegate_state_new :: proc() -> ^Place_Extended_Delegate_State {
	return new(Place_Extended_Delegate_State)
}
