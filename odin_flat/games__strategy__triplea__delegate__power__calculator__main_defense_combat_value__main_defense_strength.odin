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

main_defense_combat_value_main_defense_strength_is_negate_dominating_first_round_attack :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Strength,
	player: ^Game_Player,
) -> bool {
	ra := game_player_get_rules_attachment(player)
	return ra != nil && ra.negate_dominating_first_round_attack
}

main_defense_combat_value_main_defense_strength_is_dominating_first_round_attack :: proc(
	self: ^Main_Defense_Combat_Value_Main_Defense_Strength,
	player: ^Game_Player,
) -> bool {
	if player == nil {
		return false
	}
	ra := game_player_get_rules_attachment(player)
	return ra != nil && ra.dominating_first_round_attack
}
