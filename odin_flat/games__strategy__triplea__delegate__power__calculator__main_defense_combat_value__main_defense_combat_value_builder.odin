package game

Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder :: struct {
	game_sequence:                 ^Game_Sequence,
	game_dice_sides:               i32,
	lhtr_heavy_bombers:            bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	territory_effects:             [dynamic]^Territory_Effect,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#<init>()
// (Lombok no-arg builder constructor).
main_defense_combat_value_main_defense_combat_value_builder_new :: proc(
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	return new(Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder)
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#gameSequence(GameSequence).
main_defense_combat_value_main_defense_combat_value_builder_game_sequence :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: ^Game_Sequence,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.game_sequence = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#gameDiceSides(Integer).
main_defense_combat_value_main_defense_combat_value_builder_game_dice_sides :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: i32,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.game_dice_sides = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#lhtrHeavyBombers(Boolean).
main_defense_combat_value_main_defense_combat_value_builder_lhtr_heavy_bombers :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: bool,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.lhtr_heavy_bombers = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#strengthSupportFromFriends(AvailableSupports).
main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_friends :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.strength_support_from_friends = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#strengthSupportFromEnemies(AvailableSupports).
main_defense_combat_value_main_defense_combat_value_builder_strength_support_from_enemies :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.strength_support_from_enemies = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#rollSupportFromFriends(AvailableSupports).
main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_friends :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.roll_support_from_friends = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#rollSupportFromEnemies(AvailableSupports).
main_defense_combat_value_main_defense_combat_value_builder_roll_support_from_enemies :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.roll_support_from_enemies = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#territoryEffects(Collection).
main_defense_combat_value_main_defense_combat_value_builder_territory_effects :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: [dynamic]^Territory_Effect,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.territory_effects = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#friendUnits(Collection).
main_defense_combat_value_main_defense_combat_value_builder_friend_units :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: [dynamic]^Unit,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.friend_units = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#enemyUnits(Collection).
main_defense_combat_value_main_defense_combat_value_builder_enemy_units :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
	value: [dynamic]^Unit,
) -> ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder {
	self.enemy_units = value
	return self
}

// Ported from MainDefenseCombatValue$MainDefenseCombatValueBuilder#build().
main_defense_combat_value_main_defense_combat_value_builder_build :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Combat_Value_Builder,
) -> ^Main_Defense_Combat_Value {
	friend_units := self.friend_units
	if friend_units == nil {
		friend_units = main_defense_combat_value_default_friend_units()
	}
	enemy_units := self.enemy_units
	if enemy_units == nil {
		enemy_units = main_defense_combat_value_default_enemy_units()
	}
	return main_defense_combat_value_new(
		self.game_sequence,
		self.game_dice_sides,
		self.lhtr_heavy_bombers,
		self.strength_support_from_friends,
		self.strength_support_from_enemies,
		self.roll_support_from_friends,
		self.roll_support_from_enemies,
		self.territory_effects,
		friend_units,
		enemy_units,
	)
}

