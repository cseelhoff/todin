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

// Java: BombardmentStrength.getStrength(Unit unit)
//   final UnitAttachment ua = unit.getUnitAttachment();
//   final int strength = ua.getBombard();
//   return StrengthValue.of(gameDiceSides, strength)
//       .add(TerritoryEffectHelper.getTerritoryCombatBonus(unit.getType(), territoryEffects, false))
//       .add(supportFromFriends.giveSupportToUnit(unit))
//       .add(supportFromEnemies.giveSupportToUnit(unit));
bombardment_strength_get_strength :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Strength,
	unit: ^Unit,
) -> ^Strength_Value {
	ua := unit_get_unit_attachment(unit)
	strength := unit_attachment_get_bombard(ua)
	sv := strength_value_of(i32(self.game_dice_sides), strength)
	sv = strength_value_add(
		sv,
		territory_effect_helper_get_territory_combat_bonus(
			unit_get_type(unit),
			self.territory_effects,
			false,
		),
	)
	sv = strength_value_add(
		sv,
		available_supports_give_support_to_unit(self.support_from_friends, unit),
	)
	sv = strength_value_add(
		sv,
		available_supports_give_support_to_unit(self.support_from_enemies, unit),
	)
	return sv
}

// Java: BombardmentStrength.getSupportGiven()
//   return SupportCalculator.getCombinedSupportGiven(supportFromFriends, supportFromEnemies);
bombardment_strength_get_support_given :: proc(
	self: ^Bombardment_Combat_Value_Bombardment_Strength,
) -> map[^Unit]^Integer_Map {
	return support_calculator_get_combined_support_given(
		self.support_from_friends,
		self.support_from_enemies,
	)
}
