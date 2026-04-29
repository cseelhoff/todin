package game

// Port of games.strategy.triplea.attachments.TechAbilityAttachment.
Tech_Ability_Attachment :: struct {
	using default_attachment: Default_Attachment,

	attack_bonus:                                 ^Integer_Map,
	defense_bonus:                                ^Integer_Map,
	movement_bonus:                               ^Integer_Map,
	radar_bonus:                                  ^Integer_Map,
	air_attack_bonus:                             ^Integer_Map,
	air_defense_bonus:                            ^Integer_Map,
	production_bonus:                             ^Integer_Map,
	minimum_territory_value_for_production_bonus: i32,
	repair_discount:                              i32,
	war_bond_dice_sides:                          i32,
	war_bond_dice_number:                         i32,
	rocket_dice_number:                           ^Integer_Map,
	rocket_distance:                              i32,
	rocket_number_per_territory:                  i32,
	unit_abilities_gained:                        map[^Unit_Type]map[string]struct {},
	airborne_forces:                              bool,
	airborne_capacity:                            ^Integer_Map,
	airborne_types:                               map[^Unit_Type]struct {},
	airborne_distance:                            i32,
	airborne_bases:                               map[^Unit_Type]struct {},
	airborne_targeted_by_aa:                      map[string]map[^Unit_Type]struct {},
	attack_rolls_bonus:                           ^Integer_Map,
	defense_rolls_bonus:                          ^Integer_Map,
	bombing_bonus:                                ^Integer_Map,
}

