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

// Java: UndoablePlacement(CompositeChange, Territory producerTerritory, Territory placeTerritory, Collection<Unit>)
undoable_placement_new :: proc(
	change: ^Composite_Change,
	producer_territory: ^Territory,
	place_territory: ^Territory,
	units: [dynamic]^Unit,
) -> ^Undoable_Placement {
	self := new(Undoable_Placement)
	// super(change, units) — adopt fields produced by abstract_undoable_move_new
	base := abstract_undoable_move_new(change, units)
	self.abstract_undoable_move = base^
	free(base)
	self.place_territory = place_territory
	self.producer_territory = producer_territory
	// Install vtable dispatch adapters (override hooks).
	self.undo_specific = proc(am: ^Abstract_Undoable_Move, bridge: ^I_Delegate_Bridge) {
		undoable_placement_undo_specific(cast(^Undoable_Placement)am, bridge)
	}
	self.get_description_object = proc(am: ^Abstract_Undoable_Move) -> ^Abstract_Move_Description {
		return undoable_placement_get_description_object(cast(^Undoable_Placement)am)
	}
	self.get_move_label = proc(am: ^Abstract_Undoable_Move) -> string {
		return undoable_placement_get_move_label(cast(^Undoable_Placement)am)
	}
	self.get_end = proc(am: ^Abstract_Undoable_Move) -> ^Territory {
		return undoable_placement_get_end(cast(^Undoable_Placement)am)
	}
	return self
}

