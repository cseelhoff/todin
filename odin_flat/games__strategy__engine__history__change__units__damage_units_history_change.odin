package game

import "core:fmt"

Damage_Units_History_Change :: struct {
	change:          ^Composite_Change,
	location:        ^Territory,
	damage_to_units: ^Integer_Map_Unit,
}

// Lambda from DamageUnitsHistoryChange constructor:
//   damageToUnits.keySet().forEach(unit -> damageToUnits.add(unit, unit.getHits()));
// Captures the IntegerMap<Unit> via rawptr ctx (Integer_Map_Unit).
damage_units_history_change_lambda_new_0 :: proc(ctx: rawptr, unit: ^Unit) {
	damage_to_units := cast(^Integer_Map_Unit)ctx
	hits := unit_get_hits(unit)
	if existing, ok := damage_to_units.entries[unit]; ok {
		damage_to_units.entries[unit] = existing + hits
	} else {
		damage_to_units.entries[unit] = hits
	}
}

// Java: public DamageUnitsHistoryChange(final Territory location,
//                                       final IntegerMap<Unit> damagedUnits)
//   this.location = location;
//   this.damageToUnits = new IntegerMap<>(damagedUnits);
//   damageToUnits.keySet().forEach(unit -> damageToUnits.add(unit, unit.getHits()));
// `change` is field-initialized to `new CompositeChange()` (Lombok
// preserves the inline initializer in the generated constructor).
damage_units_history_change_new :: proc(
	location: ^Territory,
	damaged_units: ^Integer_Map_Unit,
) -> ^Damage_Units_History_Change {
	self := new(Damage_Units_History_Change)
	self.change = composite_change_new()
	self.location = location
	// new IntegerMap<>(damagedUnits) — copy-construct from source map.
	self.damage_to_units = new(Integer_Map_Unit)
	self.damage_to_units.entries = make(map[^Unit]i32)
	for unit, count in damaged_units.entries {
		self.damage_to_units.entries[unit] = count
	}
	// Snapshot keys before invoking the lambda — the lambda only updates
	// existing values (never inserts/removes keys), but matching the
	// Java keySet().forEach semantics is clearest with an explicit snapshot.
	keys := make([dynamic]^Unit, 0, len(self.damage_to_units.entries))
	defer delete(keys)
	for unit, _ in self.damage_to_units.entries {
		append(&keys, unit)
	}
	for unit in keys {
		damage_units_history_change_lambda_new_0(self.damage_to_units, unit)
	}
	return self
}

// Java: @Override public void perform(final IDelegateBridge bridge)
//   final Change damageUnitsChange =
//       ChangeFactory.unitsHit(damageToUnits, List.of(location));
//   this.change.add(damageUnitsChange);
//   bridge.addChange(this.change);
//   bridge.getHistoryWriter()
//         .addChildToEvent(
//             "Units damaged: " + MyFormatter.unitsToText(damageToUnits.keySet()),
//             new ArrayList<>(damageToUnits.keySet()));
damage_units_history_change_perform :: proc(
	self: ^Damage_Units_History_Change,
	bridge: ^I_Delegate_Bridge,
) {
	territories := make([dynamic]^Territory, 0, 1)
	append(&territories, self.location)
	damage_units_change := change_factory_units_hit(self.damage_to_units, territories)

	composite_change_add(self.change, damage_units_change)
	i_delegate_bridge_add_change(bridge, cast(^Change)self.change)

	units := make([dynamic]^Unit, 0, len(self.damage_to_units.entries))
	for unit, _ in self.damage_to_units.entries {
		append(&units, unit)
	}
	transcript := fmt.aprintf("Units damaged: %s", my_formatter_units_to_text(units))
	writer := i_delegate_bridge_get_history_writer(bridge)
	i_delegate_history_writer_add_child_to_event(writer, transcript, cast(rawptr)&units)
}

