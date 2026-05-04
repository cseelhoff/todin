package game

Firing_Group_Splitter_Aa :: struct {
	side: Battle_State_Side,
}

firing_group_splitter_aa_new :: proc(side: Battle_State_Side) -> ^Firing_Group_Splitter_Aa {
	self := new(Firing_Group_Splitter_Aa)
	self.side = side
	return self
}

// Static constructor: @Value(staticConstructor = "of") on FiringGroupSplitterAa.
firing_group_splitter_aa_of :: proc(side: Battle_State_Side) -> ^Firing_Group_Splitter_Aa {
	return firing_group_splitter_aa_new(side)
}

// games.strategy.triplea.delegate.battle.steps.fire.aa.FiringGroupSplitterAa#apply(BattleState)
//
// Creates AA and Targeted Hit firing groups: for each unique typeAa, at least one
// FiringGroup is produced, with isSuicideOnHit unit types split into their own
// groups via FiringGroup.groupBySuicideOnHit. Only DEFENSE may fire at airborne
// (paratrooper) targets, governed by TechAbilityAttachment.getAirborneTargettedByAa.
firing_group_splitter_aa_apply :: proc(
	self: ^Firing_Group_Splitter_Aa,
	battle_state: ^Battle_State,
) -> [dynamic]^Firing_Group {
	opposite := battle_state_side_get_opposite(self.side)

	airborne_tech_targets_allowed: map[string]map[^Unit_Type]struct {}
	if self.side == .DEFENSE {
		opp_player := battle_state_get_player(battle_state, opposite)
		frontier := game_data_get_technology_frontier(battle_state_get_game_data(battle_state))
		techs := tech_tracker_get_current_tech_advances(opp_player, frontier)
		defer delete(techs)
		airborne_tech_targets_allowed =
			tech_ability_attachment_get_airborne_targetted_by_aa_with_techs(techs)
	} else {
		airborne_tech_targets_allowed = make(map[string]map[^Unit_Type]struct {})
	}

	active_filter := battle_state_unit_battle_filter_new(.Alive, .Casualty)
	alive_filter := battle_state_unit_battle_filter_new(.Alive)

	active_self_units := battle_state_filter_units(battle_state, active_filter, self.side)
	alive_opp_units := battle_state_filter_units(battle_state, alive_filter, opposite)

	type_of_aa_p, type_of_aa_c := matches_unit_is_aa_for_combat_only()
	can_fire_p, can_fire_c := matches_unit_is_aa_that_can_fire(
		alive_opp_units,
		airborne_tech_targets_allowed,
		battle_state_get_player(battle_state, opposite),
		type_of_aa_p,
		type_of_aa_c,
		battle_status_get_round(battle_state_get_status(battle_state)),
		self.side == .DEFENSE,
	)
	aa_units: [dynamic]^Unit
	for u in active_self_units {
		if can_fire_p(can_fire_c, u) {
			append(&aa_units, u)
		}
	}

	type_aas := unit_attachment_get_all_of_type_aas(aa_units)

	transported_p, transported_c := matches_unit_is_being_transported()
	valid_target_units: [dynamic]^Unit
	for u in alive_opp_units {
		if !transported_p(transported_c, u) {
			append(&valid_target_units, u)
		}
	}

	firing_groups: [dynamic]^Firing_Group
	for type_aa in type_aas {
		of_type_p, of_type_c := matches_unit_is_aa_of_type_aa(type_aa)
		firing_units: [dynamic]^Unit
		for u in aa_units {
			if of_type_p(of_type_c, u) {
				append(&firing_units, u)
			}
		}

		// CollectionUtils.getAny(firingUnits).getUnitAttachment().getTargetsAa(...)
		any_unit := firing_units[0]
		valid_target_types := unit_attachment_get_targets_aa(
			unit_get_unit_attachment(any_unit),
			game_data_get_unit_type_list(battle_state_get_game_data(battle_state)),
		)

		of_types_p, of_types_c := matches_unit_is_of_types(valid_target_types)
		airborne_p, airborne_c := matches_unit_is_airborne()
		airborne_subset := airborne_tech_targets_allowed[type_aa]
		airborne_types_p, airborne_types_c := matches_unit_is_of_types(airborne_subset)

		target_units: [dynamic]^Unit
		for u in valid_target_units {
			if of_types_p(of_types_c, u) ||
			   (airborne_p(airborne_c, u) && airborne_types_p(airborne_types_c, u)) {
				append(&target_units, u)
			}
		}

		groups := firing_group_group_by_suicide_on_hit(type_aa, firing_units, target_units)
		for g in groups {
			append(&firing_groups, g)
		}
	}
	return firing_groups
}

