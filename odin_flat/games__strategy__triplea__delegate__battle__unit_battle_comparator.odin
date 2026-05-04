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

