package game

Place_Extended_Delegate_State :: struct {
	super_state: rawptr,
	produced:    map[^Territory][dynamic]^Unit,
	placements:  [dynamic]^Undoable_Placement,
}
