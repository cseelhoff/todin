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

// Java: MainOffenseStrength.getSupportGiven()
//   return SupportCalculator.getCombinedSupportGiven(supportFromFriends, supportFromEnemies);
main_offense_combat_value_main_offense_strength_get_support_given :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Strength,
) -> map[^Unit]^Integer_Map {
	return support_calculator_get_combined_support_given(
		self.support_from_friends,
		self.support_from_enemies,
	)
}

// Java: MainOffenseStrength.getStrength(Unit)
//   final UnitAttachment ua = unit.getUnitAttachment();
//   int strength = ua.getAttack(unit.getOwner());
//   if (ua.getIsMarine() != 0 && unit.getWasAmphibious()) {
//     strength += ua.getIsMarine();
//   }
//   return StrengthValue.of(gameDiceSides, strength)
//       .add(TerritoryEffectHelper.getTerritoryCombatBonus(unit.getType(), territoryEffects, false))
//       .add(supportFromFriends.giveSupportToUnit(unit))
//       .add(supportFromEnemies.giveSupportToUnit(unit));
main_offense_combat_value_main_offense_strength_get_strength :: proc(
	self: ^Main_Offense_Combat_Value_Main_Offense_Strength,
	unit: ^Unit,
) -> ^Strength_Value {
	ua := unit_get_unit_attachment(unit)
	strength: i32 = unit_attachment_get_attack_no_player(ua)
	is_marine := unit_attachment_get_is_marine(ua)
	if is_marine != 0 && unit_get_was_amphibious(unit) {
		strength += is_marine
	}
	sv := strength_value_of(i32(self.game_dice_sides), strength)
	sv = strength_value_add(
		sv,
		territory_effect_helper_get_territory_combat_bonus(
			unit_get_type(unit),
			self.territory_effects,
			false,
		),
	)
	sv = strength_value_add(sv, available_supports_give_support_to_unit(self.support_from_friends, unit))
	sv = strength_value_add(sv, available_supports_give_support_to_unit(self.support_from_enemies, unit))
	return sv
}
