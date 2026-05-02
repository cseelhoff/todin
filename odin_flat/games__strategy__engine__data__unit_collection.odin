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

// Java: public boolean add(final Unit unit)
//   units.add(unit); holder.notifyChanged(); return true;
unit_collection_add :: proc(self: ^Unit_Collection, unit: ^Unit) -> bool {
	append(&self.units, unit)
	named_unit_holder_notify_changed(self.holder)
	return true
}

// Java: @Getter NamedUnitHolder holder. The user-requested signature returns
// ^Unit_Holder; expose the embedded Unit_Holder sub-struct of the held
// Named_Unit_Holder.
unit_collection_get_holder :: proc(self: ^Unit_Collection) -> ^Unit_Holder {
	if self.holder == nil {
		return nil
	}
	return &self.holder.unit_holder
}

// Java: public int getUnitCount() { return units.size(); }
unit_collection_get_unit_count :: proc(self: ^Unit_Collection) -> i32 {
	return i32(len(self.units))
}

// Java: int getUnitCount(final UnitType type)
//   return (int) units.stream().filter(u -> u.getType().equals(type)).count();
unit_collection_get_unit_count_of_type :: proc(self: ^Unit_Collection, type: ^Unit_Type) -> i32 {
	count: i32 = 0
	for u in self.units {
		if unit_type_equals(u.type, type) {
			count += 1
		}
	}
	return count
}

// Java: public UnitCollection(final NamedUnitHolder holder, final GameData data)
//   super(data); this.holder = holder;
unit_collection_new :: proc(holder: ^Named_Unit_Holder, data: ^Game_Data) -> ^Unit_Collection {
	self := new(Unit_Collection)
	self.game_data_component = make_Game_Data_Component(data)
	self.holder = holder
	return self
}

// Java: public int countMatches(final Predicate<Unit> predicate)
//   return CollectionUtils.countMatches(units, predicate);
unit_collection_count_matches :: proc(self: ^Unit_Collection, pred: proc(^Unit) -> bool) -> i32 {
	count: i32 = 0
	for u in self.units {
		if pred(u) {
			count += 1
		}
	}
	return count
}

// Java synthetic: lambda$getUnitCount$0(UnitType, Unit) -> boolean
//   from getUnitCount(UnitType): u -> u.getType().equals(type)
unit_collection_lambda_get_unit_count_0 :: proc(type: ^Unit_Type, u: ^Unit) -> bool {
	return unit_type_equals(u.type, type)
}

// Java synthetic: lambda$getUnitsByType$3(IntegerMap<UnitType>, UnitType)
//   from getUnitsByType(): type -> { count = getUnitCount(type); if (count > 0) units.put(type, count); }
// `this` capture is implicit in Java instance synthetics; we pass it explicitly
// because the lambda body calls the instance method getUnitCount.
unit_collection_lambda_get_units_by_type_3 :: proc(self: ^Unit_Collection, units: ^Integer_Map_Unit_Type, type: ^Unit_Type) {
	count := unit_collection_get_unit_count_of_type(self, type)
	if count > 0 {
		units.entries[type] = count
	}
}

// Java synthetic: lambda$getUnitsByType$4(IntegerMap<UnitType>, Unit)
//   from getUnitsByType(GamePlayer): unit -> count.add(unit.getType(), 1)
unit_collection_lambda_get_units_by_type_4 :: proc(count: ^Integer_Map_Unit_Type, unit: ^Unit) {
	t := unit.type
	if existing, ok := count.entries[t]; ok {
		count.entries[t] = existing + 1
	} else {
		count.entries[t] = 1
	}
}

// Java synthetic: lambda$getPlayerUnitCounts$5(IntegerMap<GamePlayer>, Unit)
//   from getPlayerUnitCounts(): unit -> count.add(unit.getOwner(), 1)
// The Odin getPlayerUnitCounts returns a plain map[^Game_Player]i32; the
// captured "IntegerMap" mirrors that as a pointer to the same map type.
unit_collection_lambda_get_player_unit_counts_5 :: proc(count: ^map[^Game_Player]i32, unit: ^Unit) {
	owner := unit.owner
	if existing, ok := count[owner]; ok {
		count[owner] = existing + 1
	} else {
		count[owner] = 1
	}
}

// Java: public List<Unit> getMatches(final Predicate<Unit> predicate)
//   return CollectionUtils.getMatches(units, predicate);
unit_collection_get_matches :: proc(self: ^Unit_Collection, pred: proc(^Unit) -> bool) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.units {
		if pred(u) {
			append(&result, u)
		}
	}
	return result
}

// Java synthetic: lambda$getUnitCount$1(UnitType, GamePlayer, Unit) -> boolean
//   from getUnitCount(UnitType, GamePlayer): u -> u.getType().equals(type) && u.isOwnedBy(owner)
unit_collection_lambda_get_unit_count_1 :: proc(unit_type: ^Unit_Type, owner: ^Game_Player, u: ^Unit) -> bool {
	return unit_type_equals(u.type, unit_type) && unit_is_owned_by(u, owner)
}

// Java synthetic: lambda$getUnitCount$2(GamePlayer, Unit) -> boolean
//   from getUnitCount(GamePlayer): u -> u.isOwnedBy(owner)
unit_collection_lambda_get_unit_count_2 :: proc(owner: ^Game_Player, u: ^Unit) -> bool {
	return unit_is_owned_by(u, owner)
}
