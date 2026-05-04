package game

Main_Defense_Combat_Value_Main_Defense_Roll :: struct {
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

main_defense_combat_value_main_defense_roll_new :: proc(
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Roll {
	self := new(Main_Defense_Combat_Value_Main_Defense_Roll)
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}

// Java: MainDefenseRoll.getSupportGiven()
//   return SupportCalculator.getCombinedSupportGiven(supportFromFriends, supportFromEnemies);
main_defense_combat_value_main_defense_roll_get_support_given :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Roll,
) -> map[^Unit]^Integer_Map {
	return support_calculator_get_combined_support_given(
		self.support_from_friends,
		self.support_from_enemies,
	)
}

// Java: MainDefenseRoll.getRoll(Unit unit)
//   return RollValue.of(unit.getUnitAttachment().getDefenseRolls(unit.getOwner()))
//       .add(supportFromFriends.giveSupportToUnit(unit))
//       .add(supportFromEnemies.giveSupportToUnit(unit));
main_defense_combat_value_main_defense_roll_get_roll :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Roll,
	unit: ^Unit,
) -> ^Roll_Value {
	rv := roll_value_of(
		unit_attachment_get_defense_rolls_with_player(
			unit_get_unit_attachment(unit),
			unit_get_owner(unit),
		),
	)
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_friends, unit))
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_enemies, unit))
	return rv
}

