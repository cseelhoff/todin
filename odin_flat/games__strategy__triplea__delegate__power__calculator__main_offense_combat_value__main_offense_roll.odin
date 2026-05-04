package game

Main_Offense_Combat_Value_Main_Offense_Roll :: struct {
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

main_offense_combat_value_main_offense_roll_new :: proc(
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Roll {
	self := new(Main_Offense_Combat_Value_Main_Offense_Roll)
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}

// Java: MainOffenseRoll.getSupportGiven()
//   return SupportCalculator.getCombinedSupportGiven(supportFromFriends, supportFromEnemies);
main_offense_combat_value_main_offense_roll_get_support_given :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Roll,
) -> map[^Unit]^Integer_Map {
	return support_calculator_get_combined_support_given(
		self.support_from_friends,
		self.support_from_enemies,
	)
}

// Java: MainOffenseRoll.getRoll(Unit unit)
//   return RollValue.of(unit.getUnitAttachment().getAttackRolls(unit.getOwner()))
//       .add(supportFromFriends.giveSupportToUnit(unit))
//       .add(supportFromEnemies.giveSupportToUnit(unit));
main_offense_combat_value_main_offense_roll_get_roll :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Roll,
	unit: ^Unit,
) -> ^Roll_Value {
	rv := roll_value_of(
		unit_attachment_get_attack_rolls_with_player(
			unit_get_unit_attachment(unit),
			unit_get_owner(unit),
		),
	)
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_friends, unit))
	rv = roll_value_add(rv, available_supports_give_support_to_unit(self.support_from_enemies, unit))
	return rv
}

