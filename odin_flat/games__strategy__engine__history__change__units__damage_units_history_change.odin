package game

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

