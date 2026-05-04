package game

import "core:fmt"
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

// games.strategy.triplea.ai.pro.util.ProBattleUtils#territoryHasLocalLandSuperiority(
//     ProData proData, Territory t, int distance, GamePlayer player,
//     Map<Territory, ProPurchaseTerritory> purchaseTerritories)
//
// Java:
//   final GameState data = proData.getData();
//   if (t == null) return true;
//   for (int i = 2; i <= distance; i++) {
//     final Set<Territory> nearbyTerritoriesForEnemy =
//         data.getMap().getNeighbors(t, i, ProMatches.territoryCanMoveLandUnits(player, false));
//     nearbyTerritoriesForEnemy.add(t);
//     final List<Unit> enemyUnits = new ArrayList<>();
//     for (final Territory nearbyTerritory : nearbyTerritoriesForEnemy) {
//       enemyUnits.addAll(nearbyTerritory.getMatches(ProMatches.unitIsEnemyNotNeutral(player)));
//     }
//     final Set<Territory> nearbyTerritoriesForAllied =
//         data.getMap().getNeighbors(t, i - 1, ProMatches.territoryCanMoveLandUnits(player, false));
//     nearbyTerritoriesForAllied.add(t);
//     final List<Unit> alliedUnits = new ArrayList<>();
//     for (final Territory nearbyTerritory : nearbyTerritoriesForAllied) {
//       alliedUnits.addAll(nearbyTerritory.getMatches(Matches.isUnitAllied(player)));
//     }
//     for (final ProPurchaseTerritory purchaseTerritory : purchaseTerritories.values()) {
//       for (final ProPlaceTerritory ppt : purchaseTerritory.getCanPlaceTerritories()) {
//         if (nearbyTerritoriesForAllied.contains(ppt.getTerritory())) {
//           alliedUnits.addAll(ppt.getPlaceUnits());
//         }
//       }
//     }
//     final double strengthDifference = estimateStrengthDifference(t, enemyUnits, alliedUnits);
//     ProLogger.trace(...);
//     if (strengthDifference > 50) return false;
//   }
//   return true;
pro_battle_utils_territory_has_local_land_superiority :: proc(
	pro_data:             ^Pro_Data,
	t:                    ^Territory,
	distance:             i32,
	player:               ^Game_Player,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
) -> bool {
	data := pro_data_get_data(pro_data)
	if t == nil {
		return true
	}

	game_map := game_data_get_map(data)

	for i: i32 = 2; i <= distance; i += 1 {
		// Find enemy strength.
		land_pred_e, land_ctx_e := pro_matches_territory_can_move_land_units(player, false)
		nearby_for_enemy := game_map_get_neighbors_distance_predicate(
			game_map, t, i, land_pred_e, land_ctx_e,
		)
		nearby_for_enemy[t] = {}

		enemy_pred, enemy_ctx := pro_matches_unit_is_enemy_not_neutral(player)
		enemy_units: [dynamic]^Unit
		for nearby_t, _ in nearby_for_enemy {
			matched := territory_get_matches(nearby_t, enemy_pred, enemy_ctx)
			for u in matched {
				append(&enemy_units, u)
			}
		}

		// Find allied strength.
		land_pred_a, land_ctx_a := pro_matches_territory_can_move_land_units(player, false)
		nearby_for_allied := game_map_get_neighbors_distance_predicate(
			game_map, t, i - 1, land_pred_a, land_ctx_a,
		)
		nearby_for_allied[t] = {}

		allied_pred, allied_ctx := matches_is_unit_allied(player)
		allied_units: [dynamic]^Unit
		for nearby_t, _ in nearby_for_allied {
			matched := territory_get_matches(nearby_t, allied_pred, allied_ctx)
			for u in matched {
				append(&allied_units, u)
			}
		}
		for _, purchase_territory in purchase_territories {
			for ppt in pro_purchase_territory_get_can_place_territories(purchase_territory) {
				ppt_t := pro_place_territory_get_territory(ppt)
				if _, ok := nearby_for_allied[ppt_t]; ok {
					for u in pro_place_territory_get_place_units(ppt) {
						append(&allied_units, u)
					}
				}
			}
		}

		// Determine strength difference.
		strength_difference := pro_battle_utils_estimate_strength_difference(
			t, enemy_units, allied_units,
		)
		pro_logger_trace(
			fmt.tprintf(
				"%s, current enemy land strengthDifference=%v, distance=%v, enemySize=%v, alliedSize=%v",
				territory_to_string(t),
				strength_difference,
				i,
				len(enemy_units),
				len(allied_units),
			),
		)
		if strength_difference > 50 {
			return false
		}
	}
	return true
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#territoryHasLocalLandSuperiorityAfterMoves(
//     ProData proData, Territory t, int distance, GamePlayer player,
//     Map<Territory, ProTerritory> moveMap)
//
// Java:
//   final GameState data = proData.getData();
//   final Set<Territory> nearbyTerritoriesForEnemy =
//       data.getMap().getNeighbors(t, distance, ProMatches.territoryCanMoveLandUnits(player, false));
//   nearbyTerritoriesForEnemy.add(t);
//   final List<Unit> enemyUnits = new ArrayList<>();
//   for (final Territory nearbyTerritory : nearbyTerritoriesForEnemy) {
//     enemyUnits.addAll(nearbyTerritory.getMatches(ProMatches.unitIsEnemyNotNeutral(player)));
//   }
//   final Set<Territory> nearbyTerritoriesForAllied =
//       data.getMap().getNeighbors(t, distance - 1, ProMatches.territoryCanMoveLandUnits(player, false));
//   nearbyTerritoriesForAllied.add(t);
//   final Set<Unit> alliedUnits = new HashSet<>();
//   for (final Territory nearbyTerritory : nearbyTerritoriesForAllied) {
//     if (moveMap.get(nearbyTerritory) != null) {
//       alliedUnits.addAll(moveMap.get(nearbyTerritory).getMaxDefenders());
//     }
//   }
//   for (final Entry<Territory, ProTerritory> entry : moveMap.entrySet()) {
//     if (!nearbyTerritoriesForAllied.contains(entry.getKey())) {
//       alliedUnits.removeAll(entry.getValue().getUnits());
//       alliedUnits.removeAll(entry.getValue().getTempUnits());
//     }
//   }
//   final double strengthDifference =
//       estimateStrengthDifference(t, enemyUnits, new ArrayList<>(alliedUnits));
//   ProLogger.trace(...);
//   return strengthDifference <= 50;
pro_battle_utils_territory_has_local_land_superiority_after_moves :: proc(
	pro_data: ^Pro_Data,
	t:        ^Territory,
	distance: i32,
	player:   ^Game_Player,
	move_map: map[^Territory]^Pro_Territory,
) -> bool {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	// Find enemy strength.
	land_pred_e, land_ctx_e := pro_matches_territory_can_move_land_units(player, false)
	nearby_for_enemy := game_map_get_neighbors_distance_predicate(
		game_map, t, distance, land_pred_e, land_ctx_e,
	)
	nearby_for_enemy[t] = {}

	enemy_pred, enemy_ctx := pro_matches_unit_is_enemy_not_neutral(player)
	enemy_units: [dynamic]^Unit
	for nearby_t, _ in nearby_for_enemy {
		matched := territory_get_matches(nearby_t, enemy_pred, enemy_ctx)
		for u in matched {
			append(&enemy_units, u)
		}
	}

	// Find allied strength (HashSet semantics).
	land_pred_a, land_ctx_a := pro_matches_territory_can_move_land_units(player, false)
	nearby_for_allied := game_map_get_neighbors_distance_predicate(
		game_map, t, distance - 1, land_pred_a, land_ctx_a,
	)
	nearby_for_allied[t] = {}

	allied_set := make(map[^Unit]struct{})
	for nearby_t, _ in nearby_for_allied {
		pt, ok := move_map[nearby_t]
		if ok && pt != nil {
			for u in pro_territory_get_max_defenders(pt) {
				allied_set[u] = {}
			}
		}
	}
	for k, v in move_map {
		if _, in_allied := nearby_for_allied[k]; in_allied {
			continue
		}
		for u in pro_territory_get_units(v) {
			delete_key(&allied_set, u)
		}
		for u in pro_territory_get_temp_units(v) {
			delete_key(&allied_set, u)
		}
	}

	allied_units: [dynamic]^Unit
	for u, _ in allied_set {
		append(&allied_units, u)
	}

	// Determine strength difference.
	strength_difference := pro_battle_utils_estimate_strength_difference(
		t, enemy_units, allied_units,
	)
	pro_logger_trace(
		fmt.tprintf(
			"%s, current enemy land strengthDifference=%v, enemySize=%v, alliedSize=%v",
			territory_to_string(t),
			strength_difference,
			len(enemy_units),
			len(allied_units),
		),
	)
	return strength_difference <= 50
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#territoryHasLocalLandSuperiority(
//     ProData proData, Territory t, int distance, GamePlayer player)
//
// Java:
//   return territoryHasLocalLandSuperiority(proData, t, distance, player, new HashMap<>());
//
// 4-arg overload that delegates to the 5-arg form with an empty
// purchaseTerritories map.
pro_battle_utils_territory_has_local_land_superiority_4 :: proc(
	pro_data: ^Pro_Data,
	t:        ^Territory,
	distance: i32,
	player:   ^Game_Player,
) -> bool {
	empty := make(map[^Territory]^Pro_Purchase_Territory)
	defer delete(empty)
	return pro_battle_utils_territory_has_local_land_superiority(
		pro_data, t, distance, player, empty,
	)
}

// games.strategy.triplea.ai.pro.util.ProBattleUtils#territoryHasLocalNavalSuperiority(
//     ProData proData, ProOddsCalculator calc, Territory t, GamePlayer player,
//     Map<Territory, ProPurchaseTerritory> purchaseTerritories,
//     Collection<Unit> unitsToPlace)
//
// Java:
//   final GameState data = proData.getData();
//   int landDistance = ProUtils.getClosestEnemyLandTerritoryDistanceOverWater(data, player, t);
//   if (landDistance <= 0) landDistance = 10;
//   final int enemyDistance = Math.max(3, (landDistance + 1));
//   final Set<Territory> nearbyTerritories = data.getMap().getNeighbors(t, enemyDistance);
//   final List<Territory> nearbyLandTerritories =
//       CollectionUtils.getMatches(nearbyTerritories, Matches.territoryIsLand());
//   final Set<Territory> nearbyEnemySeaTerritories =
//       data.getMap().getNeighbors(t, enemyDistance, Matches.territoryIsWater());
//   nearbyEnemySeaTerritories.add(t);
//   final int alliedDistance = (enemyDistance + 1) / 2;
//   final Set<Territory> nearbyAlliedSeaTerritories =
//       data.getMap().getNeighbors(t, alliedDistance, Matches.territoryIsWater());
//   nearbyAlliedSeaTerritories.add(t);
//
//   final List<Unit> alliedUnitsInSeaTerritories = new ArrayList<>();
//   final List<Unit> myUnits = new ArrayList<>(unitsToPlace);
//   for (final Territory nearbySeaTerritory : nearbyAlliedSeaTerritories) {
//     final var units = nearbySeaTerritory.getUnitCollection();
//     myUnits.addAll(units.getMatches(ProMatches.unitIsOwnedNotLand(player)));
//     myUnits.addAll(ProPurchaseUtils.getPlaceUnits(nearbySeaTerritory, purchaseTerritories));
//     alliedUnitsInSeaTerritories.addAll(units.getMatches(ProMatches.unitIsAlliedNotOwned(player)));
//   }
//   myUnits.addAll(alliedUnitsInSeaTerritories);
//
//   final List<Unit> enemyUnitsInLandTerritories = new ArrayList<>();
//   for (final Territory nearbyLandTerritory : nearbyLandTerritories) {
//     enemyUnitsInLandTerritories.addAll(
//         nearbyLandTerritory.getMatches(ProMatches.unitIsEnemyAir(player)));
//   }
//   final Predicate<Unit> enemyNonLandUnit = ProMatches.unitIsEnemyNotLand(player);
//   final List<Unit> enemyUnitsInSeaTerritories = new ArrayList<>();
//   List<Unit> strongestEnemyDefenseFleet = null;
//   double strongestEnemyDefenseFleetStrength = -1;
//   for (final Territory nearbySeaTerritory : nearbyEnemySeaTerritories) {
//     final List<Unit> enemySeaUnits = nearbySeaTerritory.getMatches(enemyNonLandUnit);
//     if (enemySeaUnits.isEmpty()) continue;
//     final Optional<Route> optionalRoute =
//         data.getMap().getRouteForUnits(t, nearbySeaTerritory, Matches.territoryIsWater(),
//             enemySeaUnits, enemySeaUnits.get(0).getOwner());
//     if (optionalRoute.isEmpty()) continue;
//     final int routeLength = optionalRoute.get().numberOfSteps();
//     if (routeLength <= enemyDistance) {
//       final double strength = estimateStrength(t, myUnits, enemySeaUnits, false);
//       if (strength > strongestEnemyDefenseFleetStrength) {
//         strongestEnemyDefenseFleet = enemySeaUnits;
//         strongestEnemyDefenseFleetStrength = strength;
//       }
//       enemyUnitsInSeaTerritories.addAll(enemySeaUnits);
//     }
//   }
//   ProLogger.trace(...);
//   final List<Unit> enemyAttackers = new ArrayList<>(enemyUnitsInSeaTerritories);
//   enemyAttackers.addAll(enemyUnitsInLandTerritories);
//   final double defenseStrengthDifference = estimateStrengthDifference(t, enemyAttackers, myUnits);
//   boolean hasSuperiority = (defenseStrengthDifference < 50);
//   ProLogger.trace(...);
//   if (!hasSuperiority) return false;
//   double attackStrengthDifference = estimateStrengthDifference(t, myUnits, enemyUnitsInSeaTerritories);
//   attackStrengthDifference += 0.5 * estimateStrengthDifference(t, alliedUnitsInSeaTerritories, enemyUnitsInSeaTerritories);
//   hasSuperiority = (attackStrengthDifference > 50);
//   ProLogger.trace(...);
//   if (!hasSuperiority) return false;
//   if (strongestEnemyDefenseFleet != null) {
//     ProBattleResult result = calc.estimateAttackBattleResults(proData, t, myUnits, strongestEnemyDefenseFleet, List.of());
//     hasSuperiority = (result.getTuvSwing() > 0);
//     ProLogger.trace(...);
//   }
//   return hasSuperiority;
pro_battle_utils_territory_has_local_naval_superiority :: proc(
	pro_data:             ^Pro_Data,
	calc:                 ^Pro_Odds_Calculator,
	t:                    ^Territory,
	player:               ^Game_Player,
	purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	units_to_place:       [dynamic]^Unit,
) -> bool {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	land_distance := pro_utils_get_closest_enemy_land_territory_distance_over_water(
		&data.game_state, player, t,
	)
	if land_distance <= 0 {
		land_distance = 10
	}
	enemy_distance: i32 = land_distance + 1
	if enemy_distance < 3 {
		enemy_distance = 3
	}

	nearby_territories := game_map_get_neighbors_distance(game_map, t, enemy_distance)

	land_pred, land_ctx := matches_territory_is_land()
	nearby_land_territories: [dynamic]^Territory
	for nt, _ in nearby_territories {
		if land_pred(land_ctx, nt) {
			append(&nearby_land_territories, nt)
		}
	}

	water_pred_e, water_ctx_e := matches_territory_is_water()
	nearby_enemy_sea := game_map_get_neighbors_distance_predicate(
		game_map, t, enemy_distance, water_pred_e, water_ctx_e,
	)
	nearby_enemy_sea[t] = {}

	allied_distance := (enemy_distance + 1) / 2
	water_pred_a, water_ctx_a := matches_territory_is_water()
	nearby_allied_sea := game_map_get_neighbors_distance_predicate(
		game_map, t, allied_distance, water_pred_a, water_ctx_a,
	)
	nearby_allied_sea[t] = {}

	allied_units_in_sea_territories: [dynamic]^Unit
	my_units: [dynamic]^Unit
	for u in units_to_place {
		append(&my_units, u)
	}

	owned_pred, owned_ctx := pro_matches_unit_is_owned_not_land(player)
	allied_pred, allied_ctx := pro_matches_unit_is_allied_not_owned(player)
	for nearby_sea, _ in nearby_allied_sea {
		owned_matches := territory_get_matches(nearby_sea, owned_pred, owned_ctx)
		for u in owned_matches {
			append(&my_units, u)
		}
		place_units := pro_purchase_utils_get_place_units(nearby_sea, purchase_territories)
		for u in place_units {
			append(&my_units, u)
		}
		allied_matches := territory_get_matches(nearby_sea, allied_pred, allied_ctx)
		for u in allied_matches {
			append(&allied_units_in_sea_territories, u)
		}
	}
	for u in allied_units_in_sea_territories {
		append(&my_units, u)
	}

	enemy_air_pred, enemy_air_ctx := pro_matches_unit_is_enemy_air(player)
	enemy_units_in_land_territories: [dynamic]^Unit
	for nl in nearby_land_territories {
		matched := territory_get_matches(nl, enemy_air_pred, enemy_air_ctx)
		for u in matched {
			append(&enemy_units_in_land_territories, u)
		}
	}

	enemy_non_land_pred, enemy_non_land_ctx := pro_matches_unit_is_enemy_not_land(player)
	enemy_units_in_sea_territories: [dynamic]^Unit
	strongest_enemy_defense_fleet: [dynamic]^Unit
	has_strongest := false
	strongest_enemy_defense_fleet_strength: f64 = -1.0
	for nearby_sea, _ in nearby_enemy_sea {
		enemy_sea_units := territory_get_matches(
			nearby_sea, enemy_non_land_pred, enemy_non_land_ctx,
		)
		if len(enemy_sea_units) == 0 {
			continue
		}
		// Java's getRouteForUnits takes a Predicate<Territory>; the Odin shim
		// uses a non-ctx proc(^Territory)->bool. Use territory_is_water directly.
		route := game_map_get_route_for_units(
			game_map,
			t,
			nearby_sea,
			territory_is_water,
			enemy_sea_units,
			unit_get_owner(enemy_sea_units[0]),
		)
		if route == nil {
			continue
		}
		route_length := route_number_of_steps(route)
		if route_length <= enemy_distance {
			strength := pro_battle_utils_estimate_strength(
				t, my_units, enemy_sea_units, false,
			)
			if strength > strongest_enemy_defense_fleet_strength {
				strongest_enemy_defense_fleet = enemy_sea_units
				strongest_enemy_defense_fleet_strength = strength
				has_strongest = true
			}
			for u in enemy_sea_units {
				append(&enemy_units_in_sea_territories, u)
			}
		}
	}

	pro_logger_trace(
		fmt.tprintf(
			"%s, enemyDistance=%v, alliedDistance=%v, enemyAirUnits=%s, enemySeaUnits=%s, myUnits=%s",
			territory_to_string(t),
			enemy_distance,
			allied_distance,
			pro_utils_summarize_units(enemy_units_in_land_territories),
			pro_utils_summarize_units(enemy_units_in_sea_territories),
			pro_utils_summarize_units(my_units),
		),
	)

	// Find current naval defense strength.
	enemy_attackers: [dynamic]^Unit
	for u in enemy_units_in_sea_territories {
		append(&enemy_attackers, u)
	}
	for u in enemy_units_in_land_territories {
		append(&enemy_attackers, u)
	}
	defense_strength_difference := pro_battle_utils_estimate_strength_difference(
		t, enemy_attackers, my_units,
	)
	has_superiority := defense_strength_difference < 50
	pro_logger_trace(
		fmt.tprintf(
			"%s, current enemy naval attack strengthDifference=%v, enemySize=%v, alliedSize=%v, hasSuperiority=%v",
			territory_to_string(t),
			defense_strength_difference,
			len(enemy_attackers),
			len(my_units),
			has_superiority,
		),
	)
	if !has_superiority {
		return false
	}

	// Find current naval attack strength.
	attack_strength_difference := pro_battle_utils_estimate_strength_difference(
		t, my_units, enemy_units_in_sea_territories,
	)
	attack_strength_difference +=
		0.5 *
		pro_battle_utils_estimate_strength_difference(
			t, allied_units_in_sea_territories, enemy_units_in_sea_territories,
		)
	has_superiority = attack_strength_difference > 50
	pro_logger_trace(
		fmt.tprintf(
			"%s, current allied naval attack strengthDifference=%v, alliedSize=%v, enemySize=%v, hasSuperiority=%v",
			territory_to_string(t),
			attack_strength_difference,
			len(my_units),
			len(enemy_units_in_sea_territories),
			has_superiority,
		),
	)
	if !has_superiority {
		return false
	}

	if has_strongest {
		empty_bombarding: [dynamic]^Unit
		result := pro_odds_calculator_estimate_attack_battle_results(
			calc, pro_data, t, my_units, strongest_enemy_defense_fleet, empty_bombarding,
		)
		has_superiority = pro_battle_result_get_tuv_swing(result) > 0
		pro_logger_trace(
			fmt.tprintf(
				"%s, TUVSwing=%v, myUnits=%s, strongestEnemyDefenseFleet=%s, hasSuperiority=%v",
				territory_to_string(t),
				pro_battle_result_get_tuv_swing(result),
				pro_utils_summarize_units(my_units),
				pro_utils_summarize_units(strongest_enemy_defense_fleet),
				has_superiority,
			),
		)
	}

	return has_superiority
}

