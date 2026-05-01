package game

Bombardment_Combat_Value_Bombardment_Strength :: struct {
	game_dice_sides:      int,
	territory_effects:    [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

bombardment_strength_new :: proc(
	game_dice_sides: int,
	territory_effects: [dynamic]^Territory_Effect,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Bombardment_Combat_Value_Bombardment_Strength {
	self := new(Bombardment_Combat_Value_Bombardment_Strength)
	self.game_dice_sides = game_dice_sides
	self.territory_effects = territory_effects
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}
