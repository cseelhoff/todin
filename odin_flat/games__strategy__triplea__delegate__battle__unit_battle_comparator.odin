package game

Unit_Battle_Comparator :: struct {
	costs:                            map[^Unit_Type]i32,
	bonus:                            bool,
	ignore_primary_power:             bool,
	multi_hitpoint_can_repair:        map[^Unit_Type]struct{},
	combat_value_calculator:          ^Combat_Value,
	reversed_combat_value_calculator: ^Combat_Value,
}

// public UnitBattleComparator(IntegerMap<UnitType> costs, GameState data,
//                             CombatValue combatValueCalculator,
//                             boolean bonus, boolean ignorePrimaryPower)
unit_battle_comparator_new :: proc(
	costs: ^Integer_Map_Unit_Type,
	data: ^Game_Data,
	combat_value_calculator: ^Combat_Value,
	bonus: bool,
	ignore_primary_power: bool,
) -> ^Unit_Battle_Comparator {
	self := new(Unit_Battle_Comparator)
	self.costs = make(map[^Unit_Type]i32)
	if costs != nil {
		for ut, v in costs.entries {
			self.costs[ut] = v
		}
	}
	self.combat_value_calculator = combat_value_calculator
	self.reversed_combat_value_calculator =
		combat_value_build_opposite_combat_value(combat_value_calculator)
	self.bonus = bonus
	self.ignore_primary_power = ignore_primary_power
	self.multi_hitpoint_can_repair = make(map[^Unit_Type]struct{})
	props := game_data_get_properties(data)
	if properties_get_battleships_repair_at_end_of_round(props) ||
	   properties_get_battleships_repair_at_beginning_of_round(props) {
		p, pc := matches_unit_type_has_more_than_one_hit_point_total()
		for ut in unit_type_list_iterator(game_data_get_unit_type_list(data)) {
			if p(pc, ut) {
				self.multi_hitpoint_can_repair[ut] = struct{}{}
			}
		}
		// TODO: check if there are units in the game that can repair this unit
	}
	return self
}

// public int compare(Unit u1, Unit u2)
unit_battle_comparator_compare :: proc(self: ^Unit_Battle_Comparator, u1: ^Unit, u2: ^Unit) -> i32 {
	if unit_equals(u1, rawptr(u2)) {
		return 0
	}
	transporting1 := unit_is_transporting_any(u1)
	transporting2 := unit_is_transporting_any(u2)
	if unit_type_equals(unit_get_type(u1), unit_get_type(u2)) &&
	   unit_is_owned_by(u1, unit_get_owner(u2)) &&
	   unit_get_was_amphibious(u1) == unit_get_was_amphibious(u2) {
		if transporting1 && !transporting2 {
			return 1
		}
		if !transporting1 && transporting2 {
			return -1
		}
		return 0
	}
	air_p, air_c := matches_unit_is_air()
	carrier_p, carrier_c := matches_unit_is_carrier()
	sea_transport_p, sea_transport_c := matches_unit_is_sea_transport()
	sub_battle_p, sub_battle_c := matches_unit_has_sub_battle_abilities()
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	air_or_carrier_or_transport1 :=
		air_p(air_c, u1) ||
		carrier_p(carrier_c, u1) ||
		(!transporting1 && sea_transport_p(sea_transport_c, u1))
	air_or_carrier_or_transport2 :=
		air_p(air_c, u2) ||
		carrier_p(carrier_c, u2) ||
		(!transporting2 && sea_transport_p(sea_transport_c, u2))
	sub_destroyer1 := sub_battle_p(sub_battle_c, u1) || destroyer_p(destroyer_c, u1)
	sub_destroyer2 := sub_battle_p(sub_battle_c, u2) || destroyer_p(destroyer_c, u2)
	multi_hp_can_repair1 := unit_get_type(u1) in self.multi_hitpoint_can_repair
	multi_hp_can_repair2 := unit_get_type(u2) in self.multi_hitpoint_can_repair
	if !self.ignore_primary_power {
		power1 := 8 * power_calculator_get_value_unit(combat_value_get_power(self.combat_value_calculator), u1)
		power2 := 8 * power_calculator_get_value_unit(combat_value_get_power(self.combat_value_calculator), u2)
		if self.bonus {
			if sub_destroyer1 && !sub_destroyer2 {
				power1 += 4
			} else if !sub_destroyer1 && sub_destroyer2 {
				power2 += 4
			}
			if multi_hp_can_repair1 && !multi_hp_can_repair2 {
				power1 += 1
			} else if !multi_hp_can_repair1 && multi_hp_can_repair2 {
				power2 += 1
			}
			if transporting1 && !transporting2 {
				power1 += 1
			} else if !transporting1 && transporting2 {
				power2 += 1
			}
			if air_or_carrier_or_transport1 && !air_or_carrier_or_transport2 {
				power1 += 1
			} else if !air_or_carrier_or_transport1 && air_or_carrier_or_transport2 {
				power2 += 1
			}
		}
		if power1 != power2 {
			return power1 - power2
		}
	}
	{
		cost1, _ := self.costs[unit_get_type(u1)]
		cost2, _ := self.costs[unit_get_type(u2)]
		if cost1 != cost2 {
			return cost1 - cost2
		}
	}
	{
		power1reverse := 8 * power_calculator_get_value_unit(combat_value_get_power(self.reversed_combat_value_calculator), u1)
		power2reverse := 8 * power_calculator_get_value_unit(combat_value_get_power(self.reversed_combat_value_calculator), u2)
		if self.bonus {
			if sub_destroyer1 && !sub_destroyer2 {
				power1reverse += 4
			} else if !sub_destroyer1 && sub_destroyer2 {
				power2reverse += 4
			}
			if multi_hp_can_repair1 && !multi_hp_can_repair2 {
				power1reverse += 1
			} else if !multi_hp_can_repair1 && multi_hp_can_repair2 {
				power2reverse += 1
			}
			if transporting1 && !transporting2 {
				power1reverse += 1
			} else if !transporting1 && transporting2 {
				power2reverse += 1
			}
			if air_or_carrier_or_transport1 && !air_or_carrier_or_transport2 {
				power1reverse += 1
			} else if !air_or_carrier_or_transport1 && air_or_carrier_or_transport2 {
				power2reverse += 1
			}
		}
		if power1reverse != power2reverse {
			return power1reverse - power2reverse
		}
	}
	if sub_destroyer1 && !sub_destroyer2 {
		return 1
	} else if !sub_destroyer1 && sub_destroyer2 {
		return -1
	}
	if multi_hp_can_repair1 && !multi_hp_can_repair2 {
		return 1
	} else if !multi_hp_can_repair1 && multi_hp_can_repair2 {
		return -1
	}
	if transporting1 && !transporting2 {
		return 1
	} else if !transporting1 && transporting2 {
		return -1
	}
	if air_or_carrier_or_transport1 && !air_or_carrier_or_transport2 {
		return 1
	} else if !air_or_carrier_or_transport1 && air_or_carrier_or_transport2 {
		return -1
	}
	ua1 := unit_get_unit_attachment(u1)
	ua2 := unit_get_unit_attachment(u2)
	return unit_attachment_get_movement_with_player(ua1, unit_get_owner(u1)) -
		unit_attachment_get_movement_with_player(ua2, unit_get_owner(u2))
}

