package game

Unit_Damage_Received_Change :: struct {
	using change: Change,
	new_total_damage:      map[string]i32,
	old_total_damage:      map[string]i32,
	territories_to_notify: [dynamic]string,
}

// Java: UnitDamageReceivedChange#invert()
// Mirrors `new UnitDamageReceivedChange(oldTotalDamage, newTotalDamage,
// territoriesToNotify)` via the private all-args constructor: swap the
// new/old damage maps so applying the inverted change restores the
// previous totals, while preserving the same territories-to-notify list.
unit_damage_received_change_invert :: proc(self: ^Unit_Damage_Received_Change) -> ^Change {
	result := new(Unit_Damage_Received_Change)
	result.kind = .Unit_Damage_Received_Change
	result.new_total_damage = self.old_total_damage
	result.old_total_damage = self.new_total_damage
	result.territories_to_notify = self.territories_to_notify
	return &result.change
}
