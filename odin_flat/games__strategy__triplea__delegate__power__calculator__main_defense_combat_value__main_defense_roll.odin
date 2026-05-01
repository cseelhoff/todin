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

