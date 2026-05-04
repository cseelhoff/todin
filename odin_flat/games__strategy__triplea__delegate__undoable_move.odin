package game

import "core:fmt"

// Java: UndoableMove(Collection<Unit> units, Route route)
//   super(new CompositeChange(), units); this.route = route;
undoable_move_new :: proc(units: [dynamic]^Unit, route: ^Route) -> ^Undoable_Move {
	self := new(Undoable_Move)
	base := abstract_undoable_move_new(composite_change_new(), units)
	self.abstract_undoable_move = base^
	free(base)
	self.route = route
	// dispatch fields (undo_specific, get_move_label, get_end) are populated
	// when those overrides are ported.
	self.get_description_object = proc(am: ^Abstract_Undoable_Move) -> ^Abstract_Move_Description {
		return undoable_move_get_description_object(cast(^Undoable_Move)am)
	}
	return self
}

// Java: protected final MoveDescription getDescriptionObject()
//   return new MoveDescription(units, route);
undoable_move_get_description_object :: proc(self: ^Undoable_Move) -> ^Abstract_Move_Description {
	md := move_description_new_units_route(self.units[:], self.route)
	return cast(^Abstract_Move_Description)md
}

// Java: void initializeDependencies(List<UndoableMove> undoableMoves)
undoable_move_initialize_dependencies :: proc(self: ^Undoable_Move, undoable_moves: [dynamic]^Undoable_Move) {
	for other in undoable_moves {
		assert(other != nil, "other should not be null")

		depends := false

		// CollectionUtils.intersection(other.getUnits(), this.getUnits()) non-empty
		for u in other.units {
			for v in self.units {
				if u == v { depends = true; break }
			}
			if depends { break }
		}

		// CollectionUtils.intersection(other.units, this.loaded) non-empty
		if !depends {
			for u in other.units {
				if u in self.loaded { depends = true; break }
			}
		}

		// CollectionUtils.intersection(other.conquered, route.getAllTerritories()) non-empty
		if !depends {
			all := route_get_all_territories(self.route)
			for t in all {
				if t in other.conquered { depends = true; break }
			}
			delete(all)
		}

		// CollectionUtils.intersection(other.units, this.unloaded) non-empty
		if !depends {
			for u in other.units {
				if u in self.unloaded { depends = true; break }
			}
		}

		// CollectionUtils.intersection(other.unloaded, this.unloaded) non-empty
		if !depends {
			for u_ptr in other.unloaded {
				if u_ptr in self.unloaded { depends = true; break }
			}
		}

		if depends {
			self.dependencies[other] = {}
			other.dependents[self] = {}
		}
	}
}

Undoable_Move :: struct {
	using abstract_undoable_move: Abstract_Undoable_Move,
	reason_cant_undo: string,
	description: string,
	dependencies: map[^Undoable_Move]struct{},
	dependents: map[^Undoable_Move]struct{},
	conquered: map[^Territory]struct{},
	loaded: map[^Unit]struct{},
	unloaded: map[^Unit]struct{},
	route: ^Route,
}

undoable_move_add_to_conquered :: proc(self: ^Undoable_Move, t: ^Territory) {
	self.conquered[t] = {}
}

undoable_move_get_route :: proc(self: ^Undoable_Move) -> ^Route {
	return self.route
}

undoable_move_load :: proc(self: ^Undoable_Move, transport: ^Unit) {
	self.loaded[transport] = {}
}

undoable_move_set_description :: proc(self: ^Undoable_Move, description: string) {
	self.description = description
}

undoable_move_to_string :: proc(self: ^Undoable_Move) -> string {
	return fmt.aprintf("UndoableMove index;%d description: %s", self.index, self.description)
}

undoable_move_unload :: proc(self: ^Undoable_Move, transport: ^Unit) {
	self.unloaded[transport] = {}
}

undoable_move_was_transport_unloaded :: proc(self: ^Undoable_Move, transport: ^Unit) -> bool {
	return transport in self.unloaded
}

