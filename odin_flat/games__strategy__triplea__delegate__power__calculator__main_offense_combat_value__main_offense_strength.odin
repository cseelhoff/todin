package game

Main_Offense_Combat_Value_Main_Offense_Strength :: struct {
	game_dice_sides:      int,
	territory_effects:    [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

main_offense_combat_value_main_offense_strength_new :: proc(
	game_dice_sides: int,
	territory_effects: [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Main_Offense_Combat_Value_Main_Offense_Strength {
	self := new(Main_Offense_Combat_Value_Main_Offense_Strength)
	self.game_dice_sides = game_dice_sides
	self.territory_effects = territory_effects
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}
