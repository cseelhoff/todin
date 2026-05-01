package game

Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder :: struct {
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

aa_offense_combat_value_aa_offense_combat_value_builder_new :: proc() -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self := new(Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder)
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_enemy_units :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, enemy_units: [dynamic]^Unit) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.enemy_units = enemy_units
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_friend_units :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, friend_units: [dynamic]^Unit) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.friend_units = friend_units
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_roll_support_from_enemies :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, roll_support_from_enemies: ^Available_Supports) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.roll_support_from_enemies = roll_support_from_enemies
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_roll_support_from_friends :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, roll_support_from_friends: ^Available_Supports) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.roll_support_from_friends = roll_support_from_friends
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_strength_support_from_enemies :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, strength_support_from_enemies: ^Available_Supports) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.strength_support_from_enemies = strength_support_from_enemies
	return self
}

aa_offense_combat_value_aa_offense_combat_value_builder_strength_support_from_friends :: proc(self: ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder, strength_support_from_friends: ^Available_Supports) -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	self.strength_support_from_friends = strength_support_from_friends
	return self
}

