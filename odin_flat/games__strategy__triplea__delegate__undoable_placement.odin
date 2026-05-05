package game

import "core:fmt"

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

// Java: protected final PlacementDescription getDescriptionObject()
undoable_placement_get_description_object :: proc(self: ^Undoable_Placement) -> ^Abstract_Move_Description {
	pd := placement_description_new(self.units[:], self.place_territory)
	return cast(^Abstract_Move_Description)pd
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


// Java: protected final void undoSpecific(IDelegateBridge bridge)
//   Reaches the current AbstractPlaceDelegate via the game sequence
//   step, removes the placed units from `produced[producerTerritory]`,
//   then re-installs a fresh HashMap (mirrors Java's `new HashMap<>(produced)`).
undoable_placement_undo_specific :: proc(self: ^Undoable_Placement, bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	step := game_sequence_get_step(game_data_get_sequence(data))
	current_delegate := cast(^Abstract_Place_Delegate)game_step_get_delegate(step)
	produced := &current_delegate.produced
	units, ok := produced[self.producer_territory]
	if !ok {
		return
	}
	n := 0
	for u in units {
		keep := true
		for r in self.units {
			if u == r {
				keep = false
				break
			}
		}
		if keep {
			units[n] = u
			n += 1
		}
	}
	resize(&units, n)
	if n == 0 {
		delete_key(produced, self.producer_territory)
	} else {
		produced[self.producer_territory] = units
	}
}

// Java: private String getMoveLabel(String separator)
//   producerTerritory.equals(placeTerritory) ? placeTerritory.getName()
//     : producerTerritory.getName() + separator + placeTerritory.getName()
undoable_placement_get_move_label_with_separator :: proc(self: ^Undoable_Placement, separator: string) -> string {
	if self.producer_territory == self.place_territory {
		return territory_get_name(self.place_territory)
	}
	return fmt.tprintf(
		"%s%s%s",
		territory_get_name(self.producer_territory),
		separator,
		territory_get_name(self.place_territory),
	)
}

// Java: public final String getMoveLabel()
//   return getMoveLabel(" -> ")
undoable_placement_get_move_label :: proc(self: ^Undoable_Placement) -> string {
	return undoable_placement_get_move_label_with_separator(self, " -> ")
}

// Java: public final Territory getEnd()
//   return placeTerritory
undoable_placement_get_end :: proc(self: ^Undoable_Placement) -> ^Territory {
	return self.place_territory
}
