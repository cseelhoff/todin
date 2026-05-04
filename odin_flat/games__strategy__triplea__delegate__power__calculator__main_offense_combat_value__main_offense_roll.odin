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

