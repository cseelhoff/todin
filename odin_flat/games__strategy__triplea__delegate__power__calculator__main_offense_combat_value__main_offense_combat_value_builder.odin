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
