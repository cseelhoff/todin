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

round_history_serializer_write :: proc(self: ^Round_History_Serializer, writer: ^History_Writer) {
	history_writer_start_next_round(writer, self.round_no)
}

