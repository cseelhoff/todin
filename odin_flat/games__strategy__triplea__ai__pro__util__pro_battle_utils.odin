package game

import "core:math"

Pro_Battle_Utils :: struct {}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#estimatePower(
//     Territory t, Collection<Unit> myUnits, Collection<Unit> enemyUnits,
//     boolean attacking)
// Java:
//   final GameData data = t.getData();
//   final List<Unit> unitsThatCanFight =
//       CollectionUtils.getMatches(
//           myUnits, Matches.unitCanBeInBattle(attacking, !t.isWater(), 1, true));
//   final int myPower =
//       PowerStrengthAndRolls.build(
//               unitsThatCanFight,
//               CombatValueBuilder.mainCombatValue()
//                   .enemyUnits(enemyUnits)
//                   .friendlyUnits(unitsThatCanFight)
//                   .side(attacking ? Side.OFFENSE : Side.DEFENSE)
//                   .gameSequence(data.getSequence())
//                   .supportAttachments(data.getUnitTypeList().getSupportRules())
//                   .lhtrHeavyBombers(Properties.getLhtrHeavyBombers(data.getProperties()))
//                   .gameDiceSides(data.getDiceSides())
//                   .territoryEffects(TerritoryEffectHelper.getEffects(t))
//                   .build())
//           .calculateTotalPower();
//   return (myPower * 6.0 / data.getDiceSides());
pro_battle_utils_estimate_power :: proc(
	t:          ^Territory,
	my_units:   [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	attacking:  bool,
) -> f64 {
	data := game_data_component_get_data(&t.named_attachable.default_named.game_data_component)

	// Filter myUnits with Matches.unitCanBeInBattle(attacking, !t.isWater(), 1, true).
	// Java's 4-arg overload delegates to the 6-arg form with
	// includeAttackersThatCanNotMove=true, doNotIncludeBombardingSeaUnits=true,
	// firingUnits=List.of().
	can_fight_pred, can_fight_ctx := matches_unit_can_be_in_battle(
		attacking,
		!territory_is_water(t),
		1,
		true,
		true,
		make([dynamic]^Unit_Type),
	)
	units_that_can_fight: [dynamic]^Unit
	for u in my_units {
		if can_fight_pred(can_fight_ctx, u) {
			append(&units_that_can_fight, u)
		}
	}

	// supportAttachments is a Set<UnitSupportAttachment> in Java; the Odin
	// builder takes [dynamic]^Unit_Support_Attachment, so flatten the map.
	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}

	side: Battle_State_Side = .OFFENSE
	if !attacking {
		side = .DEFENSE
	}

	cv := combat_value_builder_main_builder_build(
		combat_value_builder_main_builder_territory_effects(
			combat_value_builder_main_builder_game_dice_sides(
				combat_value_builder_main_builder_lhtr_heavy_bombers(
					combat_value_builder_main_builder_support_attachments(
						combat_value_builder_main_builder_game_sequence(
							combat_value_builder_main_builder_side(
								combat_value_builder_main_builder_friendly_units(
									combat_value_builder_main_builder_enemy_units(
										combat_value_builder_main_combat_value(),
										enemy_units,
									),
									units_that_can_fight,
								),
								side,
							),
							game_data_get_sequence(data),
						),
						support_attachments,
					),
					properties_get_lhtr_heavy_bombers(game_data_get_properties(data)),
				),
				int(game_data_get_dice_sides(data)),
			),
			territory_effect_helper_get_effects(t),
		),
	)
	psar := power_strength_and_rolls_build(units_that_can_fight, cv)
	my_power := power_strength_and_rolls_calculate_total_power(psar)
	return (f64(my_power) * 6.0) / f64(game_data_get_dice_sides(data))
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#estimateStrength(
//     Territory t, Collection<Unit> myUnits, Collection<Unit> enemyUnits,
//     boolean attacking)
//
// Java:
//   final GameState data = t.getData();
//   List<Unit> unitsThatCanFight =
//       CollectionUtils.getMatches(
//           myUnits, Matches.unitCanBeInBattle(attacking, !t.isWater(), 1, true));
//   if (Properties.getTransportCasualtiesRestricted(data.getProperties())) {
//     unitsThatCanFight =
//         CollectionUtils.getMatches(
//             unitsThatCanFight,
//             Matches.unitIsSeaTransportButNotCombatSeaTransport().negate());
//   }
//   final int myHitPoints = CasualtyUtil.getTotalHitpointsLeft(unitsThatCanFight);
//   final double myPower = estimatePower(t, myUnits, enemyUnits, attacking);
//   return (2.0 * myHitPoints) + myPower;
pro_battle_utils_estimate_strength :: proc(
	t:           ^Territory,
	my_units:    [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	attacking:   bool,
) -> f64 {
	data := game_data_component_get_data(&t.named_attachable.default_named.game_data_component)

	can_fight_pred, can_fight_ctx := matches_unit_can_be_in_battle(
		attacking,
		!territory_is_water(t),
		1,
		true,
		true,
		make([dynamic]^Unit_Type),
	)
	units_that_can_fight: [dynamic]^Unit
	for u in my_units {
		if can_fight_pred(can_fight_ctx, u) {
			append(&units_that_can_fight, u)
		}
	}

	if properties_get_transport_casualties_restricted(game_data_get_properties(data)) {
		st_pred, st_ctx := matches_unit_is_sea_transport_but_not_combat_sea_transport()
		filtered: [dynamic]^Unit
		for u in units_that_can_fight {
			if !st_pred(st_ctx, u) {
				append(&filtered, u)
			}
		}
		units_that_can_fight = filtered
	}

	my_hit_points := casualty_util_get_total_hitpoints_left(units_that_can_fight)
	my_power := pro_battle_utils_estimate_power(t, my_units, enemy_units, attacking)
	return (2.0 * f64(my_hit_points)) + my_power
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#checkForOverwhelmingWin(
//     Territory t, Collection<Unit> attackingUnits, Collection<Unit> defendingUnits)
//
// Java:
//   final GameData data = t.getData();
//   if (defendingUnits.isEmpty() && !attackingUnits.isEmpty()) return true;
//   final double power = estimatePower(t, defendingUnits, attackingUnits, false);
//   if (power == 0 && !attackingUnits.isEmpty()) return true;
//   final int attackPower =
//       PowerStrengthAndRolls.build(
//               attackingUnits,
//               CombatValueBuilder.mainCombatValue()
//                   .enemyUnits(defendingUnits)
//                   .friendlyUnits(attackingUnits)
//                   .side(BattleState.Side.OFFENSE)
//                   .gameSequence(data.getSequence())
//                   .supportAttachments(data.getUnitTypeList().getSupportRules())
//                   .lhtrHeavyBombers(Properties.getLhtrHeavyBombers(data.getProperties()))
//                   .gameDiceSides(data.getDiceSides())
//                   .territoryEffects(TerritoryEffectHelper.getEffects(t))
//                   .build())
//           .calculateTotalPower();
//   final List<Unit> defendersWithHitPoints =
//       CollectionUtils.getMatches(defendingUnits, Matches.unitIsInfrastructure().negate());
//   final int totalDefenderHitPoints = CasualtyUtil.getTotalHitpointsLeft(defendersWithHitPoints);
//   return ((attackPower / data.getDiceSides()) >= totalDefenderHitPoints);
pro_battle_utils_check_for_overwhelming_win :: proc(
	t:               ^Territory,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
) -> bool {
	data := game_data_component_get_data(&t.named_attachable.default_named.game_data_component)

	if len(defending_units) == 0 && len(attacking_units) != 0 {
		return true
	}

	power := pro_battle_utils_estimate_power(t, defending_units, attacking_units, false)
	if power == 0 && len(attacking_units) != 0 {
		return true
	}

	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}

	cv := combat_value_builder_main_builder_build(
		combat_value_builder_main_builder_territory_effects(
			combat_value_builder_main_builder_game_dice_sides(
				combat_value_builder_main_builder_lhtr_heavy_bombers(
					combat_value_builder_main_builder_support_attachments(
						combat_value_builder_main_builder_game_sequence(
							combat_value_builder_main_builder_side(
								combat_value_builder_main_builder_friendly_units(
									combat_value_builder_main_builder_enemy_units(
										combat_value_builder_main_combat_value(),
										defending_units,
									),
									attacking_units,
								),
								Battle_State_Side.OFFENSE,
							),
							game_data_get_sequence(data),
						),
						support_attachments,
					),
					properties_get_lhtr_heavy_bombers(game_data_get_properties(data)),
				),
				int(game_data_get_dice_sides(data)),
			),
			territory_effect_helper_get_effects(t),
		),
	)
	psar := power_strength_and_rolls_build(attacking_units, cv)
	attack_power := power_strength_and_rolls_calculate_total_power(psar)

	infra_pred, infra_ctx := matches_unit_is_infrastructure()
	defenders_with_hit_points: [dynamic]^Unit
	for u in defending_units {
		if !infra_pred(infra_ctx, u) {
			append(&defenders_with_hit_points, u)
		}
	}
	total_defender_hit_points := casualty_util_get_total_hitpoints_left(defenders_with_hit_points)

	dice_sides := game_data_get_dice_sides(data)
	return (attack_power / i32(dice_sides)) >= total_defender_hit_points
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#estimateStrengthDifference(
//     Territory t, Collection<Unit> attackingUnits, Collection<Unit> defendingUnits)
//
// Java:
//   if (attackingUnits.stream().allMatch(Matches.unitIsInfrastructure())
//       || estimatePower(t, attackingUnits, defendingUnits, true) <= 0) {
//     return 0;
//   }
//   if (defendingUnits.stream().allMatch(Matches.unitIsInfrastructure())
//       || estimatePower(t, defendingUnits, attackingUnits, false) <= 0) {
//     return 99999;
//   }
//   final double attackerStrength = estimateStrength(t, attackingUnits, defendingUnits, true);
//   final double defenderStrength = estimateStrength(t, defendingUnits, attackingUnits, false);
//   return ((attackerStrength - defenderStrength) / Math.pow(defenderStrength, 0.85) * 50 + 50);
pro_battle_utils_estimate_strength_difference :: proc(
	t:               ^Territory,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
) -> f64 {
	infra_pred, infra_ctx := matches_unit_is_infrastructure()

	// allMatch on an empty stream is true in Java, matching this loop's behavior.
	all_attackers_infra := true
	for u in attacking_units {
		if !infra_pred(infra_ctx, u) {
			all_attackers_infra = false
			break
		}
	}
	if all_attackers_infra ||
	   pro_battle_utils_estimate_power(t, attacking_units, defending_units, true) <= 0 {
		return 0
	}

	all_defenders_infra := true
	for u in defending_units {
		if !infra_pred(infra_ctx, u) {
			all_defenders_infra = false
			break
		}
	}
	if all_defenders_infra ||
	   pro_battle_utils_estimate_power(t, defending_units, attacking_units, false) <= 0 {
		return 99999
	}

	attacker_strength := pro_battle_utils_estimate_strength(t, attacking_units, defending_units, true)
	defender_strength := pro_battle_utils_estimate_strength(t, defending_units, attacking_units, false)
	return ((attacker_strength - defender_strength) / math.pow(defender_strength, 0.85)) * 50.0 + 50.0
}

