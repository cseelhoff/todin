package game

Aa_Defense_Combat_Value :: struct {
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

aa_defense_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_defense_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

aa_defense_combat_value_choose_best_roll :: proc(self: ^Aa_Defense_Combat_Value, unit: ^Unit) -> bool {
	return false
}

aa_defense_combat_value_builder :: proc() -> ^Aa_Defense_Combat_Value_Aa_Defense_Combat_Value_Builder {
	return aa_defense_combat_value_builder_new()
}

aa_defense_combat_value_new :: proc(
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Aa_Defense_Combat_Value {
	self := new(Aa_Defense_Combat_Value)
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_enemies = strength_support_from_enemies
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_enemies = roll_support_from_enemies
	self.friend_units = friend_units
	self.enemy_units = enemy_units
	return self
}

// Mirror of static AvailableSupports.EMPTY_RESULT — a fresh AvailableSupports
// constructed with empty supportRules / supportUnits maps. Java caches a single
// instance; we allocate a new one per call (it is never mutated in this code
// path because friendUnits/enemyUnits are empty, so getNextAvailableSupporter
// is never invoked on it).
aa_defense_combat_value_empty_available_supports :: proc() -> ^Available_Supports {
	return available_supports_new(
		make(map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment),
		make(map[^Unit_Support_Attachment]^Available_Supports_Support_Details),
	)
}

// CombatValue buildWithNoUnitSupports()
//   AaDefenseCombatValue.builder()
//     .rollSupportFromFriends(EMPTY_RESULT)
//     .rollSupportFromEnemies(EMPTY_RESULT)
//     .strengthSupportFromFriends(EMPTY_RESULT)
//     .strengthSupportFromEnemies(EMPTY_RESULT)
//     .friendUnits(List.of())
//     .enemyUnits(List.of())
//     .build();
aa_defense_combat_value_build_with_no_unit_supports :: proc(self: ^Aa_Defense_Combat_Value) -> ^Aa_Defense_Combat_Value {
	b := aa_defense_combat_value_builder()
	aa_defense_combat_value_builder_roll_support_from_friends(b, aa_defense_combat_value_empty_available_supports())
	aa_defense_combat_value_builder_roll_support_from_enemies(b, aa_defense_combat_value_empty_available_supports())
	aa_defense_combat_value_builder_strength_support_from_friends(b, aa_defense_combat_value_empty_available_supports())
	aa_defense_combat_value_builder_strength_support_from_enemies(b, aa_defense_combat_value_empty_available_supports())
	aa_defense_combat_value_builder_friend_units(b, make([dynamic]^Unit))
	aa_defense_combat_value_builder_enemy_units(b, make([dynamic]^Unit))
	return aa_defense_combat_value_builder_build(b)
}
