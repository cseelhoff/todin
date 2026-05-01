package game

Aa_Offense_Combat_Value :: struct {
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

aa_offense_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_offense_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_offense_combat_value_builder :: proc() -> ^Aa_Offense_Combat_Value_Aa_Offense_Combat_Value_Builder {
	return aa_offense_combat_value_aa_offense_combat_value_builder_new()
}

aa_offense_combat_value_new :: proc(
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Aa_Offense_Combat_Value {
	self := new(Aa_Offense_Combat_Value)
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_enemies = strength_support_from_enemies
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_enemies = roll_support_from_enemies
	self.friend_units = friend_units
	self.enemy_units = enemy_units
	return self
}

