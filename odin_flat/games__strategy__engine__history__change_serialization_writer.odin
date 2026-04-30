package game

Change_Serialization_Writer :: struct {
	change: ^Change,
}

change_serialization_writer_new :: proc(change: ^Change) -> ^Change_Serialization_Writer {
	result := new(Change_Serialization_Writer)
	result.change = change
	return result
}
