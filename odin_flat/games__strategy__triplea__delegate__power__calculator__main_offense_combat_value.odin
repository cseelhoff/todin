package game

// Calculates offense strength and roll for non-AA dice.
// Takes into account marine, bombarding, territory effects, friendly support, and enemy support.
Main_Offense_Combat_Value :: struct {
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

// Java: @Builder.Default Collection<Unit> friendUnits = List.of();
// Lombok-synthesized $default$friendUnits returns the empty list literal.
main_offense_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: @Builder.Default Collection<Unit> enemyUnits = List.of();
main_offense_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java constructor (Lombok @Value @Builder all-args): assigns each
// @Nonnull field from the corresponding parameter.
main_offense_combat_value_new :: proc(
	game_sequence: ^Game_Sequence,
	game_dice_sides: i32,
	lhtr_heavy_bombers: bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	territory_effects: [dynamic]^Territory_Effect,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Main_Offense_Combat_Value {
	self := new(Main_Offense_Combat_Value)
	self.game_sequence = game_sequence
	self.game_dice_sides = game_dice_sides
	self.lhtr_heavy_bombers = lhtr_heavy_bombers
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_enemies = strength_support_from_enemies
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_enemies = roll_support_from_enemies
	self.territory_effects = territory_effects
	self.friend_units = friend_units
	self.enemy_units = enemy_units
	return self
}

// Java: public BattleState.Side getBattleSide() { return BattleState.Side.OFFENSE; }
main_offense_combat_value_get_battle_side :: proc(self: ^Main_Offense_Combat_Value) -> Battle_State_Side {
	return .OFFENSE
}

// Java: public int getDiceSides(final Unit unit) { return gameDiceSides; }
main_offense_combat_value_get_dice_sides :: proc(self: ^Main_Offense_Combat_Value, unit: ^Unit) -> i32 {
	return self.game_dice_sides
}

// Java: Lombok @Builder static MainOffenseCombatValueBuilder builder() { ... }
main_offense_combat_value_builder :: proc(
) -> ^Main_Offense_Combat_Value_Main_Offense_Combat_Value_Builder {
	return main_offense_combat_value_main_offense_combat_value_builder_new()
}
