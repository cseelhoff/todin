package game

Bombardment_Combat_Value_Builder :: struct {
	game_dice_sides:               int,
	lhtr_heavy_bombers:            bool,
	strength_support_from_friends: ^Available_Supports,
	strength_support_from_enemies: ^Available_Supports,
	roll_support_from_friends:     ^Available_Supports,
	roll_support_from_enemies:     ^Available_Supports,
	territory_effects:             [dynamic]^Territory_Effect,
	friend_units:                  [dynamic]^Unit,
	enemy_units:                   [dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.BombardmentCombatValue$BombardmentCombatValueBuilder

