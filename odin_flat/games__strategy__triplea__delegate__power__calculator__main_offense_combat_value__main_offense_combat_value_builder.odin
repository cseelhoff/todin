package game

// Lombok @Builder for MainOffenseCombatValue. Mirrors the fields of
// games.strategy.triplea.delegate.power.calculator.MainOffenseCombatValue.
Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder :: struct {
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

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#<init>()
// (Lombok no-arg builder constructor).
main_offense_combat_value_main_offense_combat_value_builder_new :: proc(
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	return new(Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder)
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#gameSequence(GameSequence).
main_offense_combat_value_main_offense_combat_value_builder_game_sequence :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: ^Game_Sequence,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.game_sequence = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#gameDiceSides(Integer).
main_offense_combat_value_main_offense_combat_value_builder_game_dice_sides :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: i32,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.game_dice_sides = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#lhtrHeavyBombers(Boolean).
main_offense_combat_value_main_offense_combat_value_builder_lhtr_heavy_bombers :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: bool,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.lhtr_heavy_bombers = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#strengthSupportFromFriends(AvailableSupports).
main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_friends :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.strength_support_from_friends = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#strengthSupportFromEnemies(AvailableSupports).
main_offense_combat_value_main_offense_combat_value_builder_strength_support_from_enemies :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.strength_support_from_enemies = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#rollSupportFromFriends(AvailableSupports).
main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_friends :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.roll_support_from_friends = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#rollSupportFromEnemies(AvailableSupports).
main_offense_combat_value_main_offense_combat_value_builder_roll_support_from_enemies :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.roll_support_from_enemies = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#territoryEffects(Collection).
main_offense_combat_value_main_offense_combat_value_builder_territory_effects :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: [dynamic]^Territory_Effect,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.territory_effects = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#friendUnits(Collection).
main_offense_combat_value_main_offense_combat_value_builder_friend_units :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: [dynamic]^Unit,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.friend_units = value
	return self
}

// Ported from MainOffenseCombatValue$MainOffenseCombatValueBuilder#enemyUnits(Collection).
main_offense_combat_value_main_offense_combat_value_builder_enemy_units :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder,
	value: [dynamic]^Unit,
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	self.enemy_units = value
	return self
}

