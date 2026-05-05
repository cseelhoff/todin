package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.AaRoll

Aa_Roll :: struct {
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

aa_roll_new :: proc(roll_support_from_friends: ^Available_Supports, roll_support_from_enemies: ^Available_Supports) -> ^Aa_Roll {
	self := new(Aa_Roll)
	self.support_from_friends = roll_support_from_friends
	self.support_from_enemies = roll_support_from_enemies
	return self
}

aa_roll_get_roll :: proc(self: ^Aa_Roll, unit: ^Unit) -> ^Roll_Value {
	rv := roll_value_of(unit_attachment_get_max_aa_attacks(unit_get_unit_attachment(unit)))
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_friends, unit))
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_enemies, unit))
	return rv
}


// ============================================================
// Roll_Calculator adapter for Aa_Roll (used by AA defense/offense).
// ============================================================

@(private="file")
ar_get_roll_ :: proc(rc: ^Roll_Calculator, unit: ^Unit) -> ^Roll_Value {
        impl := cast(^Aa_Roll)rc.concrete
        return aa_roll_get_roll(impl, unit)
}

@(private="file")
ar_get_support_given_ :: proc(rc: ^Roll_Calculator) -> map[^Unit]^Integer_Map {
        // AaRoll#getSupportGiven not yet ported — empty map placeholder.
        return make(map[^Unit]^Integer_Map)
}

aa_roll_to_roll_calculator :: proc(self: ^Aa_Roll) -> ^Roll_Calculator {
        rc := new(Roll_Calculator)
        rc.concrete          = self
        rc.get_roll          = ar_get_roll_
        rc.get_support_given = ar_get_support_given_
        return rc
}
