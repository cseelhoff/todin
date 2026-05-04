package game

import "core:fmt"

// Ported from games.strategy.triplea.ai.pro.ProCombatMoveAi (Phase A: type only).

Pro_Combat_Move_Ai :: struct {
	ai:                ^Abstract_Pro_Ai,
	pro_data:          ^Pro_Data,
	calc:              ^Pro_Odds_Calculator,
	data:              ^Game_Data,
	player:            ^Game_Player,
	territory_manager: ^Pro_Territory_Manager,
	is_defensive:      bool,
	is_bombing:        bool,
}

pro_combat_move_ai_is_bombing :: proc(self: ^Pro_Combat_Move_Ai) -> bool {
	return self.is_bombing
}

// Java: ProCombatMoveAi(AbstractProAi ai) {
//   this.ai = ai; this.proData = ai.getProData(); calc = ai.getCalc();
// }
pro_combat_move_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Combat_Move_Ai {
	self := new(Pro_Combat_Move_Ai)
	self.ai = ai
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	return self
}

// Java: ProCombatMoveAi#lambda$determineUnitsToAttackWith$2(ProTerritory)
//   proTerritory -> proTerritory.getBombers().clear()
pro_combat_move_ai_lambda__determine_units_to_attack_with__2 :: proc(pro_territory: ^Pro_Territory) {
	clear(&pro_territory.bombers)
}

// Java: ProCombatMoveAi#lambda$removeTerritoriesWhereTransportsAreExposed$1(Map.Entry)
//   e -> !e.getValue().getUnits().isEmpty()
// Java Map.Entry<Territory, ProTerritory> is conventionally split into
// (entry_key, entry_value) parameters in the Odin port.
pro_combat_move_ai_lambda__remove_territories_where_transports_are_exposed__1 :: proc(
	entry_key: ^Territory,
	entry_value: ^Pro_Territory,
) -> bool {
	return len(pro_territory_get_units(entry_value)) != 0
}

// Java: ProCombatMoveAi#lambda$determineBestBombingAttackForBomber$4(Unit target, Unit u)
//   u -> Matches.unitIsLegalBombingTargetBy(u).test(target)
// `target` is the captured outer Unit; `u` is the Predicate argument.
// Adopts the matches rawptr-Predicate convention (proc(rawptr, ^Unit) -> bool).
Pro_Combat_Move_Ai_Lambda_Determine_Best_Bombing_Attack_For_Bomber_4_Ctx :: struct {
	target: ^Unit,
}

pro_combat_move_ai_lambda__determine_best_bombing_attack_for_bomber__4 :: proc(
	ctx: rawptr,
	u: ^Unit,
) -> bool {
	c := (^Pro_Combat_Move_Ai_Lambda_Determine_Best_Bombing_Attack_For_Bomber_4_Ctx)(ctx)
	pred, pctx := matches_unit_is_legal_bombing_target_by(u)
	return pred(pctx, c.target)
}

// Java: public static ProductionAndIsCapital getProductionAndIsCapital(Territory t)
//   final ProductionAndIsCapital productionAndIsCapital = new ProductionAndIsCapital();
//   final Optional<TerritoryAttachment> optionalTerritoryAttachment = TerritoryAttachment.get(t);
//   if (optionalTerritoryAttachment.isPresent()) {
//     final TerritoryAttachment ta = optionalTerritoryAttachment.get();
//     productionAndIsCapital.production = ta.getProduction();
//     if (ta.isCapital()) productionAndIsCapital.isCapital = 1;
//   }
//   return productionAndIsCapital;
pro_combat_move_ai_get_production_and_is_capital :: proc(
	t: ^Territory,
) -> ^Pro_Combat_Move_Ai_Production_And_Is_Capital {
	result := pro_combat_move_ai_production_and_is_capital_new()
	ta := territory_attachment_get(t)
	if ta != nil {
		result.production = territory_attachment_get_production(ta)
		if territory_attachment_is_capital(ta) {
			result.is_capital = 1
		}
	}
	return result
}

// Java: ProCombatMoveAi#lambda$removeTerritoriesThatArentWorthAttacking$0(
//     Predicate enemyTerritory, List prioritizedTerritoryList, Territory attackFromTerritory)
//   attackFromTerritory -> {
//     final Set<Territory> enemyNeighbors =
//         data.getMap().getNeighbors(attackFromTerritory, enemyTerritory);
//     return !prioritizedTerritoryList.containsAll(enemyNeighbors);
//   }
// `data` is captured implicitly via `this` (the lambda is non-static); the
// explicit parameter list mirrors what javac records on the synthetic method.
// The Predicate<Territory> is carried as the project's (proc + rawptr) pair.
Pro_Combat_Move_Ai_Lambda_Remove_Territories_That_Arent_Worth_Attacking_0_Ctx :: struct {
	self:                       ^Pro_Combat_Move_Ai,
	enemy_territory:            proc(rawptr, ^Territory) -> bool,
	enemy_territory_ctx:        rawptr,
	prioritized_territory_list: ^[dynamic]^Territory,
}

pro_combat_move_ai_lambda__remove_territories_that_arent_worth_attacking__0 :: proc(
	ctx: rawptr,
	attack_from_territory: ^Territory,
) -> bool {
	c := (^Pro_Combat_Move_Ai_Lambda_Remove_Territories_That_Arent_Worth_Attacking_0_Ctx)(ctx)
	gm := game_data_get_map(c.self.data)
	enemy_neighbors := game_map_get_neighbors_predicate(
		gm,
		attack_from_territory,
		c.enemy_territory,
		c.enemy_territory_ctx,
	)
	// !prioritizedTerritoryList.containsAll(enemyNeighbors)
	for n in enemy_neighbors {
		found := false
		for t in c.prioritized_territory_list^ {
			if t == n {
				found = true
				break
			}
		}
		if !found {
			return true
		}
	}
	return false
}

// Java: ProCombatMoveAi#lambda$determineTerritoriesThatCanBeBombed$3(Territory)
//   terr -> !AirBattle.territoryCouldPossiblyHaveAirBattleDefenders(
//               terr, player, data, true)
// Captures the enclosing instance's `player` and `data` fields.
Pro_Combat_Move_Ai_Lambda_Determine_Territories_That_Can_Be_Bombed_3_Ctx :: struct {
	self: ^Pro_Combat_Move_Ai,
}

pro_combat_move_ai_lambda__determine_territories_that_can_be_bombed__3 :: proc(
	ctx: rawptr,
	terr: ^Territory,
) -> bool {
	c := (^Pro_Combat_Move_Ai_Lambda_Determine_Territories_That_Can_Be_Bombed_3_Ctx)(ctx)
	return !air_battle_territory_could_possibly_have_air_battle_defenders(
		terr,
		c.self.player,
		c.self.data,
		true,
	)
}

// Java: ProCombatMoveAi#checkContestedSeaTerritories()
//   final Map<Territory, ProTerritory> attackMap =
//       territoryManager.getAttackOptions().getTerritoryMap();
//   for (final Territory t : proData.getMyUnitTerritories()) {
//     if (t.isWater()
//         && Matches.territoryHasEnemyUnits(player).test(t)
//         && (attackMap.get(t) == null || attackMap.get(t).getUnits().isEmpty())) {
//       final Set<Territory> possibleMoveTerritories = data.getMap()
//           .getNeighbors(t, ProMatches.territoryCanMoveSeaUnitsThrough(player, true));
//       if (!possibleMoveTerritories.isEmpty()) {
//         final Territory moveToTerritory = CollectionUtils.getAny(possibleMoveTerritories);
//         final List<Unit> mySeaUnits =
//             t.getMatches(ProMatches.unitCanBeMovedAndIsOwnedSea(player, true));
//         proData.getProTerritory(attackMap, moveToTerritory).addUnits(mySeaUnits);
//         ProLogger.info(t + " is a contested territory so moving subs to " + moveToTerritory);
//       }
//     }
//   }
pro_combat_move_ai_check_contested_sea_territories :: proc(self: ^Pro_Combat_Move_Ai) {
	attack_options := pro_territory_manager_get_attack_options(self.territory_manager)
	attack_map := pro_my_move_options_get_territory_map(attack_options)
	for t in pro_data_get_my_unit_territories(self.pro_data) {
		if !territory_is_water(t) {
			continue
		}
		enemy_p, enemy_c := matches_territory_has_enemy_units(self.player)
		if !enemy_p(enemy_c, t) {
			continue
		}
		pt := attack_map[t]
		if pt != nil && len(pro_territory_get_units(pt)) > 0 {
			continue
		}
		gm := game_data_get_map(self.data)
		sea_p, sea_c := pro_matches_territory_can_move_sea_units_through(self.player, true)
		possible := game_map_get_neighbors_predicate(gm, t, sea_p, sea_c)
		if len(possible) == 0 {
			continue
		}
		// CollectionUtils.getAny — pick any element from the unordered set.
		move_to_territory: ^Territory
		for k, _ in possible {
			move_to_territory = k
			break
		}
		owned_p, owned_c := pro_matches_unit_can_be_moved_and_is_owned_sea(self.player, true)
		my_sea_units := territory_get_matches(t, owned_p, owned_c)
		dest := pro_data_get_pro_territory(self.pro_data, attack_map, move_to_territory)
		pro_territory_add_units(dest, my_sea_units)
		pro_logger_info(
			fmt.tprintf(
				"%s is a contested territory so moving subs to %s",
				territory_to_string(t),
				territory_to_string(move_to_territory),
			),
		)
	}
}

// Java: ProCombatMoveAi#writeProLog(Map<String, Integer> printMap)
//   for (Map.Entry<String, Integer> printEntry : printMap.entrySet()) {
//     ProLogger.trace("    " + printEntry.getValue() + " " + printEntry.getKey());
//   }
pro_combat_move_ai_write_pro_log :: proc(self: ^Pro_Combat_Move_Ai, print_map: map[string]i32) {
	for k, v in print_map {
		pro_logger_trace(fmt.tprintf("    %d %s", v, k))
	}
}

// Adapter ctx + trampoline mirroring GameMap.getDistanceIgnoreEndForCondition's
// internal predicate `t -> t.equals(end) || cond.test(t)`. The combined
// predicate is fed to game_map_get_distance_predicate under the
// rawptr-ctx convention (see llm-instructions.md). We use this directly
// rather than game_map_get_distance_ignore_end_for_condition because the
// latter only accepts a bare proc(^Territory) -> bool, while the
// ProMatches predicate carries captured state through a rawptr ctx.
Pro_Combat_Move_Ai_Air_Distance_Ctx :: struct {
	end:      ^Territory,
	cond:     proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
}

pro_combat_move_ai_air_distance_pred :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Pro_Combat_Move_Ai_Air_Distance_Ctx)ctx_ptr
	if t == c.end {
		return true
	}
	return c.cond(c.cond_ctx, t)
}

// Java: ProCombatMoveAi#canAirSafelyLandAfterAttack(Unit unit, Territory t)
//   final boolean isAdjacentToAlliedFactory =
//       Matches.territoryHasNeighborMatching(
//               data.getMap(),
//               ProMatches.territoryHasInfraFactoryAndIsAlliedLand(player))
//           .test(t);
//   final int range = unit.getMovementLeft().intValue();
//   final int distance = data.getMap().getDistanceIgnoreEndForCondition(
//       proData.getUnitTerritory(unit), t,
//       ProMatches.territoryCanMoveAirUnitsAndNoAa(data, player, true));
//   final boolean usesMoreThanHalfOfRange = distance > range / 2;
//   return isAdjacentToAlliedFactory || !usesMoreThanHalfOfRange;
pro_combat_move_ai_can_air_safely_land_after_attack :: proc(
	self: ^Pro_Combat_Move_Ai,
	unit: ^Unit,
	t: ^Territory,
) -> bool {
	gm := game_data_get_map(self.data)
	infra_p, infra_c := pro_matches_territory_has_infra_factory_and_is_allied_land(self.player)
	hn_p, hn_c := matches_territory_has_neighbor_matching(gm, infra_p, infra_c)
	is_adjacent_to_allied_factory := hn_p(hn_c, t)
	range_left := i32(unit_get_movement_left(unit))
	air_p, air_c := pro_matches_territory_can_move_air_units_and_no_aa(self.data, self.player, true)
	adapter := new(Pro_Combat_Move_Ai_Air_Distance_Ctx)
	adapter.end = t
	adapter.cond = air_p
	adapter.cond_ctx = air_c
	distance := game_map_get_distance_predicate(
		gm,
		pro_data_get_unit_territory(self.pro_data, unit),
		t,
		pro_combat_move_ai_air_distance_pred,
		rawptr(adapter),
	)
	uses_more_than_half_of_range := distance > range_left / 2
	return is_adjacent_to_allied_factory || !uses_more_than_half_of_range
}

// Java: private static final int MIN_BOMBING_SCORE = 4;
// // Avoid bombing low production factories with AA
PRO_COMBAT_MOVE_AI_MIN_BOMBING_SCORE :: i32(4)

// Adapter ctx + trampoline for the combined predicate:
//   Matches.unitCanProduceUnitsAndCanBeDamaged()
//       .and(Matches.unitIsLegalBombingTargetBy(bomber))
// Each side of the AND is a (proc, rawptr) Predicate pair under the project's
// rawptr-ctx convention; we wrap both pairs so the combined predicate can be
// passed to territory_get_matches as a single proc + rawptr.
Pro_Combat_Move_Ai_Bombing_Target_Match_Ctx :: struct {
	produces_p: proc(rawptr, ^Unit) -> bool,
	produces_c: rawptr,
	legal_p:    proc(rawptr, ^Unit) -> bool,
	legal_c:    rawptr,
}

pro_combat_move_ai_bombing_target_match_pred :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Pro_Combat_Move_Ai_Bombing_Target_Match_Ctx)ctx_ptr
	return c.produces_p(c.produces_c, u) && c.legal_p(c.legal_c, u)
}

// Java: ProCombatMoveAi#determineBestBombingAttackForBomber(
//     Map<Territory, ProTerritory> attackMap,
//     Map<Unit, Set<Territory>> sortedUnitAttackOptions,
//     Collection<Territory> bomberTargetTerritories,
//     Unit bomber)
//
//   final Predicate<Unit> bombingTargetMatch =
//       Matches.unitCanProduceUnitsAndCanBeDamaged()
//           .and(Matches.unitIsLegalBombingTargetBy(bomber));
//   Optional<Territory> maxBombingTerritory = Optional.empty();
//   int maxBombingScore = MIN_BOMBING_SCORE;
//   for (final Territory t : bomberTargetTerritories) {
//     final List<Unit> targetUnits = t.getMatches(bombingTargetMatch);
//     if (!targetUnits.isEmpty() && canAirSafelyLandAfterAttack(bomber, t)) {
//       final int noAaBombingDefense =
//           t.anyUnitsMatch(Matches.unitIsAaForBombingThisUnitOnly()) ? 0 : 1;
//       int maxDamageProduction = TerritoryAttachment.getProduction(t);
//       int neededDamageUnits = 0;
//       int sameTargetBombersCount = 0;
//       final List<Unit> existingAttackingBombers = attackMap.get(t).getBombers();
//       if (Properties.getDamageFromBombingDoneToUnitsInsteadOfTerritories(
//               data.getProperties())) {
//         final Set<Unit> sameTargetBombers = new HashSet<>();
//         for (final Unit target : targetUnits) {
//           neededDamageUnits += target.getHowMuchMoreDamageCanThisUnitTake(t);
//           final Predicate<Unit> canBombTarget =
//               u -> Matches.unitIsLegalBombingTargetBy(u).test(target);
//           sameTargetBombers.addAll(
//               CollectionUtils.getMatches(existingAttackingBombers, canBombTarget));
//         }
//         sameTargetBombersCount = sameTargetBombers.size();
//       } else {
//         sameTargetBombersCount = existingAttackingBombers.size();
//       }
//       final int remainingDamagePotential =
//           maxDamageProduction + neededDamageUnits - 3 * sameTargetBombersCount;
//       final int bombingScore = (1 + 9 * noAaBombingDefense) * remainingDamagePotential;
//       if (bombingScore >= maxBombingScore) {
//         maxBombingScore = bombingScore;
//         maxBombingTerritory = Optional.of(t);
//       }
//     }
//   }
//   if (maxBombingTerritory.isPresent()) {
//     final Territory t = maxBombingTerritory.get();
//     attackMap.get(t).getBombers().add(bomber);
//     sortedUnitAttackOptions.remove(bomber);
//     ProLogger.debug("Add bomber (" + bomber + ") to " + t);
//   }
//
// `bomberTargetTerritories` arrives in Java as a `Collection<Territory>`; the
// Odin caller (determineTerritoriesThatCanBeBombed) carries it as the same
// `Set<Territory>` shape that `bomberMoveMap` stores —
// `map[^Territory]struct{}` — so we accept that here.
pro_combat_move_ai_determine_best_bombing_attack_for_bomber :: proc(
	self: ^Pro_Combat_Move_Ai,
	attack_map: map[^Territory]^Pro_Territory,
	sorted_unit_attack_options: map[^Unit]map[^Territory]struct {},
	bomber_target_territories: map[^Territory]struct {},
	bomber: ^Unit,
) {
	produces_p, produces_c := matches_unit_can_produce_units_and_can_be_damaged()
	legal_p, legal_c := matches_unit_is_legal_bombing_target_by(bomber)
	bombing_match_ctx := new(Pro_Combat_Move_Ai_Bombing_Target_Match_Ctx)
	bombing_match_ctx.produces_p = produces_p
	bombing_match_ctx.produces_c = produces_c
	bombing_match_ctx.legal_p = legal_p
	bombing_match_ctx.legal_c = legal_c
	bombing_match_pred := pro_combat_move_ai_bombing_target_match_pred
	bombing_match_rawptr := rawptr(bombing_match_ctx)

	aa_p, aa_c := matches_unit_is_aa_for_bombing_this_unit_only()

	max_bombing_territory: ^Territory = nil
	max_bombing_score := PRO_COMBAT_MOVE_AI_MIN_BOMBING_SCORE
	for t, _ in bomber_target_territories {
		target_units := territory_get_matches(t, bombing_match_pred, bombing_match_rawptr)
		if len(target_units) == 0 {
			continue
		}
		if !pro_combat_move_ai_can_air_safely_land_after_attack(self, bomber, t) {
			continue
		}
		no_aa_bombing_defense: i32 = 1
		if territory_any_units_match(t, aa_p, aa_c) {
			no_aa_bombing_defense = 0
		}
		max_damage_production := territory_attachment_static_get_production(t)
		needed_damage_units: i32 = 0
		same_target_bombers_count: i32 = 0
		existing_attacking_bombers := pro_territory_get_bombers(attack_map[t])
		if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
			game_data_get_properties(self.data),
		) {
			same_target_bombers: map[^Unit]struct {}
			defer delete(same_target_bombers)
			for target in target_units {
				needed_damage_units += unit_get_how_much_more_damage_can_this_unit_take(target, t)
				// Java: u -> Matches.unitIsLegalBombingTargetBy(u).test(target)
				lambda_ctx := Pro_Combat_Move_Ai_Lambda_Determine_Best_Bombing_Attack_For_Bomber_4_Ctx{
					target = target,
				}
				lambda_ctx_heap := new(Pro_Combat_Move_Ai_Lambda_Determine_Best_Bombing_Attack_For_Bomber_4_Ctx)
				lambda_ctx_heap^ = lambda_ctx
				for u in existing_attacking_bombers {
					if pro_combat_move_ai_lambda__determine_best_bombing_attack_for_bomber__4(
						rawptr(lambda_ctx_heap),
						u,
					) {
						same_target_bombers[u] = struct {}{}
					}
				}
			}
			same_target_bombers_count = i32(len(same_target_bombers))
		} else {
			same_target_bombers_count = i32(len(existing_attacking_bombers))
		}
		// assume each other bomber causes a damage of 3
		remaining_damage_potential :=
			max_damage_production + needed_damage_units - 3 * same_target_bombers_count
		bombing_score := (1 + 9 * no_aa_bombing_defense) * remaining_damage_potential
		if bombing_score >= max_bombing_score {
			max_bombing_score = bombing_score
			max_bombing_territory = t
		}
	}
	if max_bombing_territory != nil {
		t := max_bombing_territory
		append(&attack_map[t].bombers, bomber)
		sorted_mut := sorted_unit_attack_options
		delete_key(&sorted_mut, bomber)
		pro_logger_debug(
			fmt.tprintf(
				"Add bomber (%s) to %s",
				unit_to_string(bomber),
				territory_to_string(t),
			),
		)
	}
}

// Java: ProCombatMoveAi#logAttackMoves(List<ProTerritory> prioritizedTerritories)
//   final Map<Territory, ProTerritory> attackMap =
//       territoryManager.getAttackOptions().getTerritoryMap();
//   ProLogger.debug("Prioritized territories:");
//   for (final ProTerritory attackTerritoryData : prioritizedTerritories) {
//     ProLogger.trace(
//         "  " + attackTerritoryData.getMaxBattleResult().getTuvSwing()
//             + "  " + attackTerritoryData.getValue()
//             + "  " + attackTerritoryData.getTerritory().getName());
//   }
//   ProLogger.debug("Territories that can be attacked:");
//   int count = 0;
//   for (Map.Entry<Territory, ProTerritory> attackEntry : attackMap.entrySet()) {
//     ... five tally maps printed via writeProLog ...
//   }
pro_combat_move_ai_log_attack_moves :: proc(
	self: ^Pro_Combat_Move_Ai,
	prioritized_territories: [dynamic]^Pro_Territory,
) {
	attack_options := pro_territory_manager_get_attack_options(self.territory_manager)
	attack_map := pro_my_move_options_get_territory_map(attack_options)

	// Print prioritization
	pro_logger_debug("Prioritized territories:")
	for attack_territory_data in prioritized_territories {
		pro_logger_trace(
			fmt.tprintf(
				"  %v  %v  %s",
				pro_battle_result_get_tuv_swing(
					pro_territory_get_max_battle_result(attack_territory_data),
				),
				pro_territory_get_value(attack_territory_data),
				territory_to_string(pro_territory_get_territory(attack_territory_data)),
			),
		)
	}

	// Print enemy territories with enemy units vs my units
	pro_logger_debug("Territories that can be attacked:")
	count: i32 = 0
	for t, pt in attack_map {
		count += 1
		pro_logger_trace(fmt.tprintf("%d. ---%s", count, territory_to_string(t)))

		// new HashSet<>(getMaxUnits()); addAll(getMaxAmphibUnits())
		combined_units: map[^Unit]struct {}
		defer delete(combined_units)
		for u, _ in pro_territory_get_max_units(pt) {
			combined_units[u] = struct {}{}
		}
		for u in pro_territory_get_max_amphib_units(pt) {
			combined_units[u] = struct {}{}
		}

		pro_logger_trace("  --- My max units ---")
		print_map: map[string]i32
		defer delete(print_map)
		for u, _ in combined_units {
			key := unit_to_string_no_owner(u)
			if v, ok := print_map[key]; ok {
				print_map[key] = v + 1
			} else {
				print_map[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_map)

		pro_logger_trace("  --- My max bombard units ---")
		print_bombard_map: map[string]i32
		defer delete(print_bombard_map)
		for u, _ in pro_territory_get_max_bombard_units(pt) {
			key := unit_to_string_no_owner(u)
			if v, ok := print_bombard_map[key]; ok {
				print_bombard_map[key] = v + 1
			} else {
				print_bombard_map[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_bombard_map)

		units3 := pro_territory_get_units(pt)
		pro_logger_trace("  --- My actual units ---")
		print_map3: map[string]i32
		defer delete(print_map3)
		for u in units3 {
			key := unit_to_string_no_owner(u)
			if v, ok := print_map3[key]; ok {
				print_map3[key] = v + 1
			} else {
				print_map3[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_map3)

		pro_logger_trace("  --- Enemy units ---")
		print_map2: map[string]i32
		defer delete(print_map2)
		units2 := pro_territory_get_max_enemy_defenders(pt, self.player)
		for u in units2 {
			key := unit_to_string_no_owner(u)
			if v, ok := print_map2[key]; ok {
				print_map2[key] = v + 1
			} else {
				print_map2[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_map2)

		pro_logger_trace("  --- Enemy Counter Attack Units ---")
		print_map4: map[string]i32
		defer delete(print_map4)
		units4 := pro_territory_get_max_enemy_units(pt)
		for u in units4 {
			key := unit_to_string_no_owner(u)
			if v, ok := print_map4[key]; ok {
				print_map4[key] = v + 1
			} else {
				print_map4[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_map4)

		pro_logger_trace("  --- Enemy Counter Bombard Units ---")
		print_map5: map[string]i32
		defer delete(print_map5)
		for u, _ in pro_territory_get_max_enemy_bombard_units(pt) {
			key := unit_to_string_no_owner(u)
			if v, ok := print_map5[key]; ok {
				print_map5[key] = v + 1
			} else {
				print_map5[key] = 1
			}
		}
		pro_combat_move_ai_write_pro_log(self, print_map5)
	}
}

