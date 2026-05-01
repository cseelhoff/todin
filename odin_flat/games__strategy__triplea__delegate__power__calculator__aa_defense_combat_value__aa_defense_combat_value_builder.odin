package game

Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder :: struct {
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

aa_defense_combat_value_builder_new :: proc() -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	return new(Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder)
}

aa_defense_combat_value_builder_enemy_units :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: [dynamic]^Unit) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.enemy_units = value
	return self
}

aa_defense_combat_value_builder_friend_units :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: [dynamic]^Unit) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.friend_units = value
	return self
}

aa_defense_combat_value_builder_roll_support_from_enemies :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: ^Available_Supports) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.roll_support_from_enemies = value
	return self
}

aa_defense_combat_value_builder_roll_support_from_friends :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: ^Available_Supports) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.roll_support_from_friends = value
	return self
}

aa_defense_combat_value_builder_strength_support_from_enemies :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: ^Available_Supports) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.strength_support_from_enemies = value
	return self
}

aa_defense_combat_value_builder_strength_support_from_friends :: proc(self: ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder, value: ^Available_Supports) -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	self.strength_support_from_friends = value
	return self
}

