package game



Pro_Odds_Calculator :: struct {
	calc:    ^I_Battle_Calculator,
	stopped: bool,
}

pro_odds_calculator_new :: proc(calculator: ^I_Battle_Calculator) -> ^Pro_Odds_Calculator {
	self := new(Pro_Odds_Calculator)
	self.calc = calculator
	self.stopped = false
	return self
}

// Java: ProOddsCalculator#canSubmergeBeforeBattle (private static)
//   return checkSubmerge
//       && Properties.getSubRetreatBeforeBattle(data.getProperties())
//       && defendingUnits.stream().allMatch(Matches.unitCanEvade())
//       && attackingUnits.stream().noneMatch(Matches.unitIsDestroyer());
pro_odds_calculator_can_submerge_before_battle :: proc(
	data: ^Game_State,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	check_submerge: bool,
) -> bool {
	if !check_submerge {
		return false
	}
	if !properties_get_sub_retreat_before_battle(game_state_get_properties(data)) {
		return false
	}
	evade_p, evade_c := matches_unit_can_evade()
	for u in defending_units {
		if !evade_p(evade_c, u) {
			return false
		}
	}
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	for u in attacking_units {
		if destroyer_p(destroyer_c, u) {
			return false
		}
	}
	return true
}

// Java: ProOddsCalculator#checkIfNoAttackersOrDefenders (private static)
//   final boolean hasNoDefenders =
//       defendingUnits.stream().noneMatch(Matches.unitIsNotInfrastructure());
//   final boolean isLandAndCanOnlyBeAttackedByAir =
//       !t.isWater()
//           && !attackingUnits.isEmpty()
//           && attackingUnits.stream().allMatch(Matches.unitIsAir());
//   if (attackingUnits.isEmpty() || (hasNoDefenders && isLandAndCanOnlyBeAttackedByAir)) {
//     return new ProBattleResult();
//   } else if (hasNoDefenders) {
//     final List<Unit> mainCombatDefenders =
//         CollectionUtils.getMatches(
//             defendingUnits, Matches.unitCanBeInBattle(false, !t.isWater(), 1, true));
//     final double tuv = TuvUtils.getTuv(mainCombatDefenders, proData.getUnitValueMap());
//     return new ProBattleResult(100, 0.1 + tuv, true, attackingUnits, List.of(), 0);
//   } else if (canSubmergeBeforeBattle(
//       proData.getData(), attackingUnits, defendingUnits, checkSubmerge)) {
//     return new ProBattleResult();
//   }
//   return null;
pro_odds_calculator_check_if_no_attackers_or_defenders :: proc(
	pro_data: ^Pro_Data,
	t: ^Territory,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	check_submerge: bool,
) -> ^Pro_Battle_Result {
	not_infra_p, not_infra_c := matches_unit_is_not_infrastructure()
	has_no_defenders := true
	for u in defending_units {
		if not_infra_p(not_infra_c, u) {
			has_no_defenders = false
			break
		}
	}
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in attacking_units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	is_land_and_can_only_be_attacked_by_air :=
		!territory_is_water(t) && len(attacking_units) > 0 && all_air
	if len(attacking_units) == 0 ||
	   (has_no_defenders && is_land_and_can_only_be_attacked_by_air) {
		return pro_battle_result_new_empty()
	} else if has_no_defenders {
		in_battle_p, in_battle_c := matches_unit_can_be_in_battle_no_firing_units(
			false, !territory_is_water(t), 1, true,
		)
		main_combat_defenders := make([dynamic]^Unit)
		for u in defending_units {
			if in_battle_p(in_battle_c, u) {
				append(&main_combat_defenders, u)
			}
		}
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(pro_data)
		tuv := tuv_utils_get_tuv(main_combat_defenders, costs)
		return pro_battle_result_new(
			100,
			0.1 + f64(tuv),
			true,
			attacking_units,
			make([dynamic]^Unit),
			0,
		)
	} else if pro_odds_calculator_can_submerge_before_battle(
		pro_data_get_data(pro_data),
		attacking_units,
		defending_units,
		check_submerge,
	) {
		return pro_battle_result_new_empty()
	}
	return nil
}

// Java: ProOddsCalculator#callBattleCalc (private, 7-arg full form)
//   private ProBattleResult callBattleCalc(
//       final ProData proData, final Territory t,
//       final Collection<Unit> attackingUnits,
//       final Collection<Unit> defendingUnits,
//       final Collection<Unit> bombardingUnits,
//       final boolean checkSubmerge,
//       final boolean retreatWhenOnlyAirLeft) { ... }
// `calc.calculate(...)` is dispatched against the `IBattleCalculator`
// interface; in this port the only concrete implementer reaching
// `Pro_Odds_Calculator` is `Concurrent_Battle_Calculator` (see
// `pro_ai.odin`), and `using i_battle_calculator: I_Battle_Calculator`
// in `Concurrent_Battle_Calculator` makes the embedded interface
// occupy zero leading bytes, so a downcast of `^I_Battle_Calculator`
// to `^Concurrent_Battle_Calculator` lands on the same address.
pro_odds_calculator_call_battle_calc :: proc(
	self: ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
	t: ^Territory,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	bombarding_units: [dynamic]^Unit,
	check_submerge: bool,
	retreat_when_only_air_left: bool,
) -> ^Pro_Battle_Result {
	data := game_data_component_get_data(
		&t.named_attachable.default_named.game_data_component,
	)

	if self.stopped || len(attacking_units) == 0 || len(defending_units) == 0 {
		return pro_battle_result_new_empty()
	}

	min_army_size := len(attacking_units)
	if len(defending_units) < min_army_size {
		min_army_size = len(defending_units)
	}
	run_count: i32 = 100 - i32(min_army_size)
	if run_count < 16 {
		run_count = 16
	}
	attacker := unit_get_owner(attacking_units[0])
	defender := unit_get_owner(defending_units[0])
	concrete_calc := cast(^Concurrent_Battle_Calculator)self.calc
	results := concurrent_battle_calculator_calculate(
		concrete_calc,
		attacker,
		defender,
		t,
		attacking_units,
		defending_units,
		bombarding_units,
		territory_effect_helper_get_effects(t),
		retreat_when_only_air_left,
		run_count,
	)

	// Find battle result statistics
	win_percentage := aggregate_results_get_attacker_win_percent(results) * 100
	average_attackers_remaining := aggregate_results_get_average_attacking_units_remaining(results)
	average_defenders_remaining := aggregate_results_get_average_defending_units_remaining(results)

	in_battle_attackers_p, in_battle_attackers_c := matches_unit_can_be_in_battle_no_firing_units(
		true, !territory_is_water(t), 1, true,
	)
	main_combat_attackers := make([dynamic]^Unit)
	for u in attacking_units {
		if in_battle_attackers_p(in_battle_attackers_c, u) {
			append(&main_combat_attackers, u)
		}
	}
	in_battle_defenders_p, in_battle_defenders_c := matches_unit_can_be_in_battle_no_firing_units(
		false, !territory_is_water(t), 1, true,
	)
	main_combat_defenders := make([dynamic]^Unit)
	for u in defending_units {
		if in_battle_defenders_p(in_battle_defenders_c, u) {
			append(&main_combat_defenders, u)
		}
	}
	tuv_swing := aggregate_results_get_average_tuv_swing(
		results, attacker, main_combat_attackers, defender, main_combat_defenders, data,
	)

	// Set TUV swing for neutrals
	neutral_p, neutral_c := matches_territory_is_neutral_but_not_water()
	if neutral_p(neutral_c, t) {
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(pro_data)
		attacking_unit_value := tuv_utils_get_tuv(main_combat_attackers, costs)
		left_over := aggregate_results_get_average_tuv_of_units_left_over(results, costs, costs)
		remaining_unit_value := tuple_get_first(left_over)
		tuv_swing = remaining_unit_value - f64(attacking_unit_value)
	}

	// Add TUV swing for transported units
	transported_p, transported_c := matches_unit_is_being_transported()
	defending_transported_units := make([dynamic]^Unit)
	for u in defending_units {
		if transported_p(transported_c, u) {
			append(&defending_transported_units, u)
		}
	}
	if territory_is_water(t) && len(defending_transported_units) > 0 {
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(pro_data)
		transported_unit_value := tuv_utils_get_tuv(defending_transported_units, costs)
		tuv_swing += f64(transported_unit_value) * win_percentage / 100
	}

	// Remove TUV and add to remaining units for defenders that can submerge before battle
	if tuv_swing > 0 &&
	   pro_odds_calculator_can_submerge_before_battle(
		   data, attacking_units, defending_units, check_submerge,
	   ) {
		evade_p, evade_c := matches_unit_can_evade()
		defending_subs_killed := make([dynamic]^Unit)
		for u in defending_units {
			if evade_p(evade_c, u) {
				append(&defending_subs_killed, u)
			}
		}
		// removeAll(averageDefendersRemaining) — drop any element of
		// defending_subs_killed that is also in averageDefendersRemaining.
		filtered := make([dynamic]^Unit)
		for u in defending_subs_killed {
			in_remaining := false
			for r in average_defenders_remaining {
				if r == u {
					in_remaining = true
					break
				}
			}
			if !in_remaining {
				append(&filtered, u)
			}
		}
		delete(defending_subs_killed)
		defending_subs_killed = filtered
		for u in defending_subs_killed {
			append(&average_defenders_remaining, u)
		}
		costs := new(Integer_Map_Unit_Type)
		costs.entries = pro_data_get_unit_value_map(pro_data)
		sub_tuv := tuv_utils_get_tuv(defending_subs_killed, costs)
		tuv_swing -= f64(sub_tuv)
		if tuv_swing < 0 {
			tuv_swing = 0
		}
	}

	// Create battle result object
	has_land_units_remaining: bool
	if territory_is_water(t) {
		has_land_units_remaining = len(average_attackers_remaining) > 0
	} else {
		land_p, land_c := matches_unit_is_land()
		has_land_units_remaining = false
		for u in average_attackers_remaining {
			if land_p(land_c, u) {
				has_land_units_remaining = true
				break
			}
		}
	}
	return pro_battle_result_new(
		win_percentage,
		tuv_swing,
		has_land_units_remaining,
		average_attackers_remaining,
		average_defenders_remaining,
		aggregate_results_get_average_battle_rounds_fought(results),
	)
}

