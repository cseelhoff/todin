package game

import "core:strings"

Remove_Units_History_Change :: struct {
	change:                                 ^Composite_Change,
	location:                               ^Territory,
	killed_units:                           [dynamic]^Unit,
	unloaded_units:                         map[^Territory][dynamic]^Unit,
	transform_damaged_units_history_change: ^Transform_Damaged_Units_History_Change,
	message_template:                       string,
	old_units:                              [dynamic]^Unit,
	new_units:                              [dynamic]^Unit,
}

remove_units_history_change_get_new_units :: proc(self: ^Remove_Units_History_Change) -> [dynamic]^Unit {
	return self.new_units
}

remove_units_history_change_get_old_units :: proc(self: ^Remove_Units_History_Change) -> [dynamic]^Unit {
	return self.old_units
}

// Java: unit -> {
//   originalHits.add(unit, unit.getHits());
//   unit.setHits(unit.getUnitAttachment().getHitPoints());
// }
// Captures originalHits (passed explicitly as first arg).
remove_units_history_change_lambda_new_0 :: proc(original_hits: ^Integer_Map_Unit, unit: ^Unit) {
	if original_hits != nil {
		if original_hits.entries == nil {
			original_hits.entries = make(map[^Unit]i32)
		}
		prev, _ := original_hits.entries[unit]
		original_hits.entries[unit] = prev + unit_get_hits(unit)
	}
	unit_set_hits(unit, unit_attachment_get_hit_points(unit_get_unit_attachment(unit)))
}

// Java: unit -> unit.setHits(originalHits.getInt(unit))
// Captures originalHits (passed explicitly as first arg).
remove_units_history_change_lambda_new_1 :: proc(original_hits: ^Integer_Map_Unit, unit: ^Unit) {
	v: i32 = 0
	if x, ok := original_hits.entries[unit]; ok {
		v = x
	}
	unit_set_hits(unit, v)
}

// Java: k -> new ArrayList<>() inside unloadedUnits.computeIfAbsent(...).
// Non-capturing; returns a fresh empty dynamic array of ^Unit.
remove_units_history_change_lambda_new_2 :: proc(k: ^Territory) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: public RemoveUnitsHistoryChange(
//     final Territory location,
//     final Collection<Unit> killedUnits,
//     final String messageTemplate)
remove_units_history_change_new :: proc(
	location: ^Territory,
	units: [dynamic]^Unit,
	reason: string,
) -> ^Remove_Units_History_Change {
	self := new(Remove_Units_History_Change)
	self.change = composite_change_new()
	self.location = location
	self.unloaded_units = make(map[^Territory][dynamic]^Unit)
	self.message_template = reason
	self.old_units = make([dynamic]^Unit)
	self.new_units = make([dynamic]^Unit)

	// Temporarily give each unit maximum damage so that
	// TransformDamagedUnitsHistoryChange can recognize units that need
	// to be transformed when killed.
	original_hits := new(Integer_Map_Unit)
	original_hits.entries = make(map[^Unit]i32)
	for unit in units {
		remove_units_history_change_lambda_new_0(original_hits, unit)
	}

	self.transform_damaged_units_history_change =
		transform_damaged_units_history_change_new(location, units, false)

	for unit in units {
		remove_units_history_change_lambda_new_1(original_hits, unit)
	}

	all_unloaded_units := make([dynamic]^Unit)
	for u in units {
		append(&self.old_units, u)
		// ensure that any units that are being transported are also killed
		transporting := unit_get_transporting_in_territory(u, location)
		for t in transporting {
			append(&self.old_units, t)
		}
		// any unit that was unloaded during combat phase needs to be
		// removed but it needs to be removed from the territory it
		// unloaded to
		unloaded := unit_get_unloaded(u)
		for unloaded_unit in unloaded {
			append(&self.old_units, unloaded_unit)
			append(&all_unloaded_units, unloaded_unit)
			to := unit_get_unloaded_to(unloaded_unit)
			arr, ok := self.unloaded_units[to]
			if !ok {
				arr = remove_units_history_change_lambda_new_2(to)
			}
			append(&arr, unloaded_unit)
			self.unloaded_units[to] = arr
		}
	}

	new_units_from_transform := transform_damaged_units_history_change_get_new_units(
		self.transform_damaged_units_history_change,
	)
	for nu in new_units_from_transform {
		append(&self.new_units, nu)
	}

	transformed_units := transform_damaged_units_history_change_get_old_units(
		self.transform_damaged_units_history_change,
	)

	contains_unit :: proc(arr: [dynamic]^Unit, target: ^Unit) -> bool {
		for x in arr {
			if x == target {
				return true
			}
		}
		return false
	}

	self.killed_units = make([dynamic]^Unit)
	for u in self.old_units {
		if contains_unit(transformed_units, u) {
			continue
		}
		if contains_unit(all_unloaded_units, u) {
			continue
		}
		append(&self.killed_units, u)
	}

	return self
}

// Java: unloadedUnits.forEach((territory, units) -> {
//     allKilledUnits.addAll(units);
//     change.add(ChangeFactory.removeUnits(territory, units));
// });
// Captures allKilledUnits and the local CompositeChange `change` (passed
// explicitly as the first two args).
remove_units_history_change_lambda_perform_3 :: proc(
	all_killed_units: ^[dynamic]^Unit,
	change: ^Composite_Change,
	territory: ^Territory,
	units: [dynamic]^Unit,
) {
	for u in units {
		append(all_killed_units, u)
	}
	composite_change_add(change, change_factory_remove_units(cast(^Unit_Holder)territory, units))
}

// Java: public void perform(final IDelegateBridge bridge)
// Mirrors the Java body one-to-one: first delegate to the queued
// `TransformDamagedUnitsHistoryChange.perform`, then build a fresh
// `CompositeChange` containing a remove-units change for the primary
// `location/killedUnits` pair plus per-territory remove-units changes
// for any combat-phase unloads. If the composite ends up empty,
// bail out without touching `this.change` (matching Java). Otherwise
// fold the composite into `this.change`, hand the cumulative
// `this.change` to the bridge, then format the message template by
// substituting `${units}` and `${territory}` (StringSubstitutor with
// the default `${...}` syntax) and emit a child history event
// referencing every unit that was killed.
remove_units_history_change_perform :: proc(
	self: ^Remove_Units_History_Change,
	bridge: ^I_Delegate_Bridge,
) {
	transform_damaged_units_history_change_perform(
		self.transform_damaged_units_history_change,
		bridge,
	)

	all_killed_units := make([dynamic]^Unit)

	change := composite_change_new()
	if len(self.killed_units) != 0 {
		for u in self.killed_units {
			append(&all_killed_units, u)
		}
		composite_change_add(
			change,
			change_factory_remove_units(cast(^Unit_Holder)self.location, self.killed_units),
		)
	}
	if len(self.unloaded_units) != 0 {
		for territory, units in self.unloaded_units {
			remove_units_history_change_lambda_perform_3(
				&all_killed_units,
				change,
				territory,
				units,
			)
		}
	}
	if composite_change_is_empty(change) {
		return
	}
	composite_change_add(self.change, cast(^Change)change)
	i_delegate_bridge_add_change(bridge, cast(^Change)self.change)

	units_text := my_formatter_units_to_text(all_killed_units)
	territory_name := default_named_get_name(&self.location.named_attachable.default_named)
	text, _ := strings.replace_all(self.message_template, "${units}", units_text)
	text, _ = strings.replace_all(text, "${territory}", territory_name)

	writer := i_delegate_bridge_get_history_writer(bridge)
	i_delegate_history_writer_add_child_to_event(writer, text, cast(rawptr)&all_killed_units)
}

