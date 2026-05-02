package game

Bombardment_Combat_Value_Bombardment_Combat_Value_Builder :: struct {
	game_dice_sides:                   int,
	game_dice_sides_set:               bool,
	lhtr_heavy_bombers:                bool,
	lhtr_heavy_bombers_set:            bool,
	strength_support_from_friends:     ^Available_Supports,
	strength_support_from_friends_set: bool,
	strength_support_from_enemies:     ^Available_Supports,
	strength_support_from_enemies_set: bool,
	roll_support_from_friends:         ^Available_Supports,
	roll_support_from_friends_set:     bool,
	roll_support_from_enemies:         ^Available_Supports,
	roll_support_from_enemies_set:     bool,
	territory_effects:                 [dynamic]^Territory_Effect,
	territory_effects_set:             bool,
	friend_units:                      [dynamic]^Unit,
	friend_units_set:                  bool,
	enemy_units:                       [dynamic]^Unit,
	enemy_units_set:                   bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.BombardmentCombatValue$BombardmentCombatValueBuilder

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#<init>()
// (Lombok no-arg builder constructor).
make_Bombardment_Combat_Value_Bombardment_Combat_Value_Builder :: proc(
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	return new(Bombardment_Combat_Value_Bombardment_Combat_Value_Builder)
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#gameDiceSides(Integer).
bombardment_combat_value_bombardment_combat_value_builder_game_dice_sides :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	game_dice_sides: int,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.game_dice_sides = game_dice_sides
	self.game_dice_sides_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#lhtrHeavyBombers(Boolean).
bombardment_combat_value_bombardment_combat_value_builder_lhtr_heavy_bombers :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	lhtr_heavy_bombers: bool,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.lhtr_heavy_bombers = lhtr_heavy_bombers
	self.lhtr_heavy_bombers_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#strengthSupportFromFriends(AvailableSupports).
bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_friends :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	strength_support_from_friends: ^Available_Supports,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.strength_support_from_friends = strength_support_from_friends
	self.strength_support_from_friends_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#strengthSupportFromEnemies(AvailableSupports).
bombardment_combat_value_bombardment_combat_value_builder_strength_support_from_enemies :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	strength_support_from_enemies: ^Available_Supports,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.strength_support_from_enemies = strength_support_from_enemies
	self.strength_support_from_enemies_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#rollSupportFromFriends(AvailableSupports).
bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_friends :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	roll_support_from_friends: ^Available_Supports,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.roll_support_from_friends = roll_support_from_friends
	self.roll_support_from_friends_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#rollSupportFromEnemies(AvailableSupports).
bombardment_combat_value_bombardment_combat_value_builder_roll_support_from_enemies :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	roll_support_from_enemies: ^Available_Supports,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.roll_support_from_enemies = roll_support_from_enemies
	self.roll_support_from_enemies_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#territoryEffects(Collection).
bombardment_combat_value_bombardment_combat_value_builder_territory_effects :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	territory_effects: [dynamic]^Territory_Effect,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.territory_effects = territory_effects
	self.territory_effects_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#friendUnits(Collection).
bombardment_combat_value_bombardment_combat_value_builder_friend_units :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	friend_units: [dynamic]^Unit,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.friend_units = friend_units
	self.friend_units_set = true
	return self
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#enemyUnits(Collection).
bombardment_combat_value_bombardment_combat_value_builder_enemy_units :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
	enemy_units: [dynamic]^Unit,
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	self.enemy_units = enemy_units
	self.enemy_units_set = true
	return self
}


// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#<init>()
// (Lombok no-arg builder constructor).
bombardment_combat_value_bombardment_combat_value_builder_new :: proc(
) -> ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder {
	return new(Bombardment_Combat_Value_Bombardment_Combat_Value_Builder)
}

// Ported from BombardmentCombatValue$BombardmentCombatValueBuilder#build().
// Lombok @Builder with @Builder.Default on friendUnits/enemyUnits → List.of()
// when the caller did not invoke the corresponding setter.
bombardment_combat_value_bombardment_combat_value_builder_build :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Combat_Value_Builder,
) -> ^Bombardment_Combat_Value {
	friend_units := self.friend_units
	if !self.friend_units_set {
		friend_units = bombardment_combat_value_default_friend_units()
	}
	enemy_units := self.enemy_units
	if !self.enemy_units_set {
		enemy_units = bombardment_combat_value_default_enemy_units()
	}
	return bombardment_combat_value_new(
		i32(self.game_dice_sides),
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
