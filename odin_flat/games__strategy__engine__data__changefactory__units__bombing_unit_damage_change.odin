package game

Bombing_Unit_Damage_Change :: struct {
	using parent: Change,
	new_damage: ^Integer_Map,
	old_damage: ^Integer_Map,
	territories_to_notify: [dynamic]string,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.units.BombingUnitDamageChange

