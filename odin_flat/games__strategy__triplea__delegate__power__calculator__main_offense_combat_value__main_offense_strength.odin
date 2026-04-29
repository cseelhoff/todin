package game

Main_Offense_Combat_Value_Main_Offense_Strength :: struct {
	game_dice_sides:      int,
	territory_effects:    [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}
