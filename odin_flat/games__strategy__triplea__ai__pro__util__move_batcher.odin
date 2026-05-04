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

move_batcher_can_merge_moves :: proc(a: ^Move_Description, b: ^Move_Description) -> bool {
	return move_batcher_is_transport_load(a) == move_batcher_is_transport_load(b) &&
		route_equals(move_description_get_route(a), move_description_get_route(b))
}

// Merges the two moves. Caller must ensure canMergeMoves() is true before calling.
move_batcher_merge_moves :: proc(
	move1: ^Move_Description,
	move2: ^Move_Description,
) -> ^Move_Description {
	if !move_batcher_can_merge_moves(move1, move2) {
		panic("can't merge moves")
	}
	units := make([dynamic]^Unit)
	for u in move1.units {
		append(&units, u)
	}
	for u in move2.units {
		append(&units, u)
	}
	units_to_sea_transports := make(map[^Unit]^Unit)
	for k, v in move_description_get_units_to_sea_transports(move1) {
		units_to_sea_transports[k] = v
	}
	for k, v in move_description_get_units_to_sea_transports(move2) {
		units_to_sea_transports[k] = v
	}
	return move_description_new_with_sea_transports(
		units[:],
		move_description_get_route(move1),
		units_to_sea_transports,
	)
}

move_batcher_add_move :: proc(self: ^Move_Batcher, new_move: ^Move_Description) {
	sequence := &self.move_sequences[len(self.move_sequences) - 1]
	if len(sequence^) > 0 {
		last_index := len(sequence^) - 1
		last_move := sequence^[last_index]
		if move_batcher_can_merge_moves(last_move, new_move) {
			sequence^[last_index] = move_batcher_merge_moves(last_move, new_move)
			return
		}
	}
	append(sequence, new_move)
}

move_batcher_merge_sequences :: proc(
	sequence: ^[dynamic]^Move_Description,
	sequences: [][dynamic]^Move_Description,
) {
	for &other_sequence in sequences {
		merge := len(other_sequence) == len(sequence^)
		i := 0
		for ; merge && i < len(sequence^); i += 1 {
			merge = move_batcher_can_merge_moves(sequence^[i], other_sequence[i])
		}
		if !merge {
			continue
		}
		for j := 0; j < len(sequence^); j += 1 {
			sequence^[j] = move_batcher_merge_moves(sequence^[j], other_sequence[j])
		}
		clear(&other_sequence)
	}
}
