package game

Aa_Defense_Combat_Value_Aa_Defense_Strength :: struct {
	calculator:           ^Aa_Defense_Combat_Value,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
}

aa_defense_strength_new :: proc(
	this0: ^Aa_Defense_Combat_Value,
	support_from_friends: ^Available_Supports,
	support_from_enemies: ^Available_Supports,
) -> ^Aa_Defense_Combat_Value_Aa_Defense_Strength {
	self := new(Aa_Defense_Combat_Value_Aa_Defense_Strength)
	self.calculator = this0
	self.support_from_friends = support_from_friends
	self.support_from_enemies = support_from_enemies
	return self
}

// Java: AaDefenseStrength.getStrength(Unit)
//   return StrengthValue.of(
//           this.calculator.getDiceSides(unit),
//           unit.getUnitAttachment().getAttackAa(unit.getOwner()))
//       .add(supportFromFriends.giveSupportToUnit(unit))
//       .add(supportFromEnemies.giveSupportToUnit(unit));
aa_defense_strength_get_strength :: proc(
	self: ^Aa_Defense_Combat_Value_Aa_Defense_Strength,
	unit: ^Unit,
) -> ^Strength_Value {
	sv := strength_value_of(
		aa_defense_combat_value_get_dice_sides(self.calculator, unit),
		unit_attachment_get_attack_aa(
			unit_get_unit_attachment(unit),
			unit_get_owner(unit),
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
