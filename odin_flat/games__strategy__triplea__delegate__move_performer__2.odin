package game

// Anonymous IExecutable #2 (fireAa) inside MovePerformer.execute(...).
// Captures effectively-final locals `route`, `units` from the enclosing
// method, plus the outer MovePerformer instance (for fields
// `airTransportDependents` and `arrivingUnits`).
Move_Performer_2 :: struct {
	using i_executable: I_Executable,
	outer:              ^Move_Performer,
	route:              ^Route,
	units:              [dynamic]^Unit,
}

move_performer_2_new :: proc(this0: ^Move_Performer, route: ^Route, collection: [dynamic]^Unit) -> ^Move_Performer_2 {
	self := new(Move_Performer_2)
	self.outer = this0
	self.route = route
	self.units = collection
	self.i_executable.execute = move_performer_2_execute
	return self
}

move_performer_2_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	self := cast(^Move_Performer_2)self_base
	outer := self.outer
	aa_casualties := move_performer_fire_aa(outer, self.route, self.units)
	aa_casualties_with_dependents := make(map[^Unit]struct{})
	defer delete(aa_casualties_with_dependents)
	if aa_casualties != nil {
		for u in aa_casualties {
			aa_casualties_with_dependents[u] = {}
		}
		dependencies := transport_tracker_transporting_with_all_possible_units(self.units)
		for u in aa_casualties {
			deps, has := dependencies[u]
			if has {
				for d in deps {
					aa_casualties_with_dependents[d] = {}
				}
			}
			// new dependents too (ie: paratroopers)
			air_deps, has_air := outer.air_transport_dependents[u]
			if has_air {
				for d in air_deps {
					aa_casualties_with_dependents[d] = {}
				}
			}
		}
	}
	// arrivingUnits = CollectionUtils.difference(units, aaCasualtiesWithDependents)
	outer.arriving_units = make([dynamic]^Unit)
	for u in self.units {
		if _, removed := aa_casualties_with_dependents[u]; !removed {
			append(&outer.arriving_units, u)
		}
	}
}

