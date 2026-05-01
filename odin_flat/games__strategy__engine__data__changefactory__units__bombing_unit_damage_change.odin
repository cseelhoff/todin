package game

Bombing_Unit_Damage_Change :: struct {
	using change: Change,
	new_damage: ^Integer_Map,
	old_damage: ^Integer_Map,
	territories_to_notify: [dynamic]string,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.units.BombingUnitDamageChange

// Java: BombingUnitDamageChange#lambda$new$0(Map.Entry)
//   entry -> {
//     this.newDamage.put(entry.getKey().getId().toString(), entry.getValue());
//     this.oldDamage.put(entry.getKey().getId().toString(), entry.getKey().getUnitDamage());
//   }
// Captured: `this`. The Java key is `unit.getId().toString()`; the Odin
// Integer_Map keys are rawptr, so we use the ^Unit pointer itself as the
// stable key — preserving identity-based lookup without round-tripping
// through UUID strings (Odin has no java.util.UUID parser, and the
// pointer is unique per unit for the lifetime of the change).
bombing_unit_damage_change_lambda_new_0 :: proc(self: ^Bombing_Unit_Damage_Change, key: ^Unit, value: i32) {
	integer_map_put(self.new_damage, rawptr(key), value)
	integer_map_put(self.old_damage, rawptr(key), unit_get_unit_damage(key))
}

// Java: BombingUnitDamageChange#lambda$perform$1(GameState, String)
//   territory -> data.getMap().getTerritoryOrNull(territory).notifyChanged()
// Captured: `data` (the GameState passed to perform).
bombing_unit_damage_change_lambda_perform_1 :: proc(data: ^Game_State, territory: string) {
	territory_notify_changed(game_map_get_territory_or_null(game_state_get_map(data), territory))
}

// Java: BombingUnitDamageChange#<init>(IntegerMap<Unit>, Collection<Territory>)
//   this.newDamage = new IntegerMap<>();
//   this.oldDamage = new IntegerMap<>();
//   damage.entrySet().forEach(entry -> { ... lambda$new$0 ... });
//   this.territoriesToNotify =
//       territoriesToNotify.stream().map(Territory::getName).collect(toList());
bombing_unit_damage_change_new :: proc(damage: ^Integer_Map_Unit, territories_to_notify: [dynamic]^Territory) -> ^Bombing_Unit_Damage_Change {
	self := new(Bombing_Unit_Damage_Change)
	self.kind = .Bombing_Unit_Damage_Change
	self.new_damage = integer_map_new()
	self.old_damage = integer_map_new()
	for unit, value in damage.entries {
		bombing_unit_damage_change_lambda_new_0(self, unit, value)
	}
	self.territories_to_notify = make([dynamic]string, 0, len(territories_to_notify))
	for territory in territories_to_notify {
		append(&self.territories_to_notify, territory.named.base.name)
	}
	return self
}

// Java: BombingUnitDamageChange#perform(GameState data)
//   newDamage.keySet().forEach(unitId ->
//     data.getUnits().get(UUID.fromString(unitId)).setUnitDamage(newDamage.getInt(unitId)));
//   this.territoriesToNotify.forEach(
//     territory -> data.getMap().getTerritoryOrNull(territory).notifyChanged());
//
// In the Odin port, newDamage's rawptr keys are ^Unit pointers (see
// lambda$new$0), so the unit lookup `data.getUnits().get(UUID.fromString(unitId))`
// collapses to a direct cast — equivalent because the same ^Unit identity
// was registered on the Units_List by the time damage was computed.
bombing_unit_damage_change_perform :: proc(self: ^Bombing_Unit_Damage_Change, state: ^Game_State) {
	keys := integer_map_key_set(self.new_damage)
	defer delete(keys)
	for k in keys {
		unit := cast(^Unit)k
		unit_set_unit_damage(unit, integer_map_get_int(self.new_damage, k))
	}
	for territory in self.territories_to_notify {
		bombing_unit_damage_change_lambda_perform_1(state, territory)
	}
}

