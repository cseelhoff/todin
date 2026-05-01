package game

// Calculates offense strength and roll for non-AA dice (bombardment).
// Takes into account marine, bombarding, territory effects, friendly support, and enemy support.
Bombardment_Combat_Value :: struct {
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

bombardment_combat_value_default_friend_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

bombardment_combat_value_default_enemy_units :: proc() -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: public int getDiceSides(final Unit unit) { return gameDiceSides; }
bombardment_combat_value_get_dice_sides :: proc(
	self: ^Bombardment_Combat_Value,
	unit: ^Unit,
) -> i32 {
	return self.game_dice_sides
}

// Java: public BattleState.Side getBattleSide() { return BattleState.Side.OFFENSE; }
bombardment_combat_value_get_battle_side :: proc(
	self: ^Bombardment_Combat_Value,
) -> Battle_State_Side {
	return .OFFENSE
}

bombardment_combat_value_new :: proc(
	game_dice_sides: i32,
	lhtr_heavy_bombers: bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends: ^Available_Supports,
	roll_support_from_enemies: ^Available_Supports,
	territory_effects: [dynamic]^Territory_Effect,
	friend_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> ^Bombardment_Combat_Value {
	self := new(Bombardment_Combat_Value)
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

