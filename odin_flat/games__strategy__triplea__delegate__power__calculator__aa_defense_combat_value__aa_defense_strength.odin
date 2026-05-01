package game

Aa_Defense_Combat_Value_Aa_Defense_Strength :: struct {
	calculator:           ^Aa_Defense_Combat_Value,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

aa_defense_strength_new :: proc(
	this0: ^Aa_Defense_Combat_Value,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Aa_Defense_Combat_Value_Aa_Defense_Strength {
	self := new(Aa_Defense_Combat_Value_Aa_Defense_Strength)
	self.calculator = this0
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}
