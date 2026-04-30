package game

Unit_Collection :: struct {
	using game_data_component: Game_Data_Component,
	units:        [dynamic]^Unit,
	holder:       ^Named_Unit_Holder,
}

unit_collection_get_units :: proc(self: ^Unit_Collection) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.units {
		append(&result, u)
	}
	return result
}

unit_collection_contains :: proc(self: ^Unit_Collection, o: ^Unit) -> bool {
	for u in self.units {
		if u == o {
			return true
		}
	}
	return false
}

unit_collection_any_match :: proc(self: ^Unit_Collection, pred: proc(^Unit) -> bool) -> bool {
	for u in self.units {
		if pred(u) {
			return true
		}
	}
	return false
}

unit_collection_all_match :: proc(self: ^Unit_Collection, pred: proc(^Unit) -> bool) -> bool {
	for unit in self.units {
		if !pred(unit) {
			return false
		}
	}
	return true
}

unit_collection_is_empty :: proc(self: ^Unit_Collection) -> bool {
	return len(self.units) == 0
}

unit_collection_iterator :: proc(self: ^Unit_Collection) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, len(self.units))
	for unit in self.units {
		append(&result, unit)
	}
	return result
}

unit_collection_size :: proc(self: ^Unit_Collection) -> i32 {
	return i32(len(self.units))
}

unit_collection_contains_all :: proc(self: ^Unit_Collection, other: [dynamic]^Unit) -> bool {
	if len(self.units) > 500 && len(other) > 500 {
		set := make(map[^Unit]bool, len(self.units))
		defer delete(set)
		for u in self.units {
			set[u] = true
		}
		for o in other {
			if !(o in set) {
				return false
			}
		}
		return true
	}
	for o in other {
		found := false
		for u in self.units {
			if u == o {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

// Java: public boolean addAll(final Collection<? extends Unit> units)
//   final boolean result = this.units.addAll(units);
//   holder.notifyChanged();
//   return result;
//
// ArrayList.addAll returns true iff the receiver was modified, which for an
// always-appending implementation is equivalent to "the input was non-empty".
// Named_Unit_Holder is an interface; GamePlayer's notifyChanged is empty and
// Territory's dispatches to territory listeners (also no-op in odin_flat —
// see game_data_notify_territory_units_changed). Mirror Java's call by
// reading self.holder; there is no callable dispatch on the bare struct.
unit_collection_add_all :: proc(self: ^Unit_Collection, units: [dynamic]^Unit) -> bool {
	result := len(units) > 0
	for u in units {
		append(&self.units, u)
	}
	_ = self.holder
	return result
}

unit_collection_get_player_unit_counts :: proc(self: ^Unit_Collection) -> map[^Game_Player]i32 {
	count: map[^Game_Player]i32
	for unit in self.units {
		owner := unit.owner
		if existing, ok := count[owner]; ok {
			count[owner] = existing + 1
		} else {
			count[owner] = 1
		}
	}
	return count
}

unit_collection_get_players_with_units :: proc(self: ^Unit_Collection) -> map[^Game_Player]struct{} {
	result := make(map[^Game_Player]struct{})
	for unit in self.units {
		result[unit.owner] = {}
	}
	return result
}

unit_collection_remove_all :: proc(self: ^Unit_Collection, units: [dynamic]^Unit) -> bool {
	to_remove := make(map[^Unit]bool, len(units))
	defer delete(to_remove)
	for u in units {
		to_remove[u] = true
	}
	result := false
	i := 0
	for i < len(self.units) {
		if self.units[i] in to_remove {
			ordered_remove(&self.units, i)
			result = true
		} else {
			i += 1
		}
	}
	named_unit_holder_notify_changed(self.holder)
	return result
}
