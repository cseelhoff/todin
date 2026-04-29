package game

Main_Defense_Combat_Value_Main_Defense_Strength :: struct {
	game_sequence:        ^Game_Sequence,
	game_dice_sides:      i32,
	territory_effects:    [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}
