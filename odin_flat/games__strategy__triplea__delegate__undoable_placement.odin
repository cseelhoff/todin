package game

Undoable_Placement :: struct {
	using abstract_undoable_move: Abstract_Undoable_Move,
	place_territory:    ^Territory,
	producer_territory: ^Territory,
}

undoable_placement_get_place_territory :: proc(self: ^Undoable_Placement) -> ^Territory {
	return self.place_territory
}

undoable_placement_get_producer_territory :: proc(self: ^Undoable_Placement) -> ^Territory {
	return self.producer_territory
}

undoable_placement_set_producer_territory :: proc(self: ^Undoable_Placement, producer_territory: ^Territory) {
	self.producer_territory = producer_territory
}

