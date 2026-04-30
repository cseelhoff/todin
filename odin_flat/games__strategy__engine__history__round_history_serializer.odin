package game

Round_History_Serializer :: struct {
	using serialization_writer: Serialization_Writer,
	round_no: i32,
}

round_history_serializer_new :: proc(round_no: i32) -> ^Round_History_Serializer {
	self := new(Round_History_Serializer)
	self.round_no = round_no
	return self
}

