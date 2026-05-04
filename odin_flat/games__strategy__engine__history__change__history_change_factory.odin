package game

History_Change_Factory :: struct {}

// Java: public TransformDamagedUnitsHistoryChange transformDamagedUnits(
//           final Territory location,
//           final Collection<Unit> damagedUnits,
//           final boolean markNoMovementOnNewUnits) {
//         return new TransformDamagedUnitsHistoryChange(
//             location, damagedUnits, markNoMovementOnNewUnits);
//       }
history_change_factory_transform_damaged_units :: proc(
	location: ^Territory,
	damaged_units: [dynamic]^Unit,
	mark_no_movement_on_new_units: bool,
) -> ^Transform_Damaged_Units_History_Change {
	return transform_damaged_units_history_change_new(
		location,
		damaged_units,
		mark_no_movement_on_new_units,
	)
}

// Java: public DamageUnitsHistoryChange damageUnits(
//           final Territory location, final IntegerMap<Unit> damagedUnits) {
//         return new DamageUnitsHistoryChange(location, damagedUnits);
//       }
history_change_factory_damage_units :: proc(
	location: ^Territory,
	damaged_units: ^Integer_Map_Unit,
) -> ^Damage_Units_History_Change {
	return damage_units_history_change_new(location, damaged_units)
}

