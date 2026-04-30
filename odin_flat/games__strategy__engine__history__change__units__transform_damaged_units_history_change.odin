package game

// Inner class Transform_Damaged_Units_History_Change_Grouped_Units is
// defined in transform_damaged_units_history_change__grouped_units.odin
// (Odin package scope is flat across odin_flat/).

Transform_Damaged_Units_History_Change :: struct {
	change:                        ^Composite_Change,
	location:                      ^Territory,
	transforming_units:            map[^Unit]^Unit,
	attribute_changes:             ^Composite_Change,
	mark_no_movement_on_new_units: bool,
}

// Java: public Collection<Unit> getOldUnits()
//   return Collections.unmodifiableCollection(transformingUnits.keySet());
// The Java field has no `oldUnits` storage — the getter is a live view
// over `transformingUnits.keySet()`. In Odin we surface a fresh
// snapshot as a dynamic array of pointers (matching the convention
// used by `resource_list_get_resources`); the caller owns the
// returned array.
transform_damaged_units_history_change_get_old_units :: proc(
	self: ^Transform_Damaged_Units_History_Change,
) -> [dynamic]^Unit {
	out := make([dynamic]^Unit, 0, len(self.transforming_units))
	for old_unit, _ in self.transforming_units {
		append(&out, old_unit)
	}
	return out
}

// Java: public Collection<Unit> getNewUnits()
//   return Collections.unmodifiableCollection(transformingUnits.values());
// As with `getOldUnits`, the Java class has no `newUnits` field;
// we materialize a fresh snapshot of the map values.
transform_damaged_units_history_change_get_new_units :: proc(
	self: ^Transform_Damaged_Units_History_Change,
) -> [dynamic]^Unit {
	out := make([dynamic]^Unit, 0, len(self.transforming_units))
	for _, new_unit in self.transforming_units {
		append(&out, new_unit)
	}
	return out
}

// Java synthetic lambda from `perform`:
//   groupedByOldAndNewUnitTypes.computeIfAbsent(oldUnit.getType(), k -> new HashMap<>())
// Non-capturing; returns a fresh empty inner map keyed by ^Unit_Type
// of grouped-units pointers. The `k` parameter (the absent key) is
// ignored, mirroring the Java lambda's body.
transform_damaged_units_history_change_lambda_perform_0 :: proc(
	k: ^Unit_Type,
) -> map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units {
	return make(map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units)
}

// Java synthetic lambda from `perform`:
//   .flatMap(tmp -> tmp.values().stream())
// Non-capturing; flattens the inner map's values into a fresh
// dynamic array of grouped-units pointers (Odin's stand-in for
// the Java stream the caller iterates over). Caller owns the array.
transform_damaged_units_history_change_lambda_perform_3 :: proc(
	tmp: map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units,
) -> [dynamic]^Transform_Damaged_Units_History_Change_Grouped_Units {
	out := make([dynamic]^Transform_Damaged_Units_History_Change_Grouped_Units, 0, len(tmp))
	for _, grouped in tmp {
		append(&out, grouped)
	}
	return out
}

