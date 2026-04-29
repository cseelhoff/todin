package game

Indexed_History_Node :: struct {
	using parent:       History_Node,
	change_start_index: i32,
	change_stop_index:  i32,
}
