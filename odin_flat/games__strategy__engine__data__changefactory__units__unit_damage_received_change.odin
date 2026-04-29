package game

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.units.UnitDamageReceivedChange

Unit_Damage_Received_Change :: struct {
	using parent: Change,
	new_total_damage: map[string]i32,
	old_total_damage: map[string]i32,
	territories_to_notify: [dynamic]string,
}

