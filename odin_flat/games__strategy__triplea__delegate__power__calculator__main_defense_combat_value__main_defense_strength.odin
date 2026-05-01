package game

Main_Defense_Combat_Value_Main_Defense_Strength :: struct {
	game_sequence:        ^Game_Sequence,
	game_dice_sides:      i32,
	territory_effects:    [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

main_defense_combat_value_main_defense_strength_new :: proc(
	game_sequence: ^Game_Sequence,
	game_dice_sides: i32,
	territory_effects: [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Main_Defense_Combat_Value_Main_Defense_Strength {
	self := new(Main_Defense_Combat_Value_Main_Defense_Strength)
	self.game_sequence = game_sequence
	self.game_dice_sides = game_dice_sides
	self.territory_effects = territory_effects
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}
