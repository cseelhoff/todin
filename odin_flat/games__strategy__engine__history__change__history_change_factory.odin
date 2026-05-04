package game

import "core:fmt"

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

// Java: public RemoveUnitsHistoryChange removeUnitsFromTerritory(
//           final Territory location, final Collection<Unit> killedUnits) {
//         return new RemoveUnitsHistoryChange(
//             location, killedUnits, "${units} lost in ${territory}");
//       }
history_change_factory_remove_units_from_territory :: proc(
	location: ^Territory,
	killed_units: [dynamic]^Unit,
) -> ^Remove_Units_History_Change {
	return remove_units_history_change_new(location, killed_units, "${units} lost in ${territory}")
}

// Java: public RemoveUnitsHistoryChange removeUnitsWithAa(
//           final Territory location,
//           final Collection<Unit> killedUnits,
//           final String aaType) {
//         return new RemoveUnitsHistoryChange(
//             location, killedUnits,
//             "${units} killed by " + aaType + " in ${territory}");
//       }
history_change_factory_remove_units_with_aa :: proc(
	location: ^Territory,
	killed_units: [dynamic]^Unit,
	aa_type: string,
) -> ^Remove_Units_History_Change {
	reason := fmt.aprintf("${units} killed by %s in ${territory}", aa_type)
	return remove_units_history_change_new(location, killed_units, reason)
}

