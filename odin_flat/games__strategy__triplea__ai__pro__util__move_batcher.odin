package game

Move_Batcher :: struct {
	move_sequences: [dynamic][dynamic]^Move_Description,
}

move_batcher_new :: proc() -> ^Move_Batcher {
	self := new(Move_Batcher)
	self.move_sequences = make([dynamic][dynamic]^Move_Description)
	return self
}

move_batcher_new_sequence :: proc(self: ^Move_Batcher) {
	append(&self.move_sequences, make([dynamic]^Move_Description))
}

move_batcher_is_transport_load :: proc(move: ^Move_Description) -> bool {
	return len(move_description_get_units_to_sea_transports(move)) > 0
}
