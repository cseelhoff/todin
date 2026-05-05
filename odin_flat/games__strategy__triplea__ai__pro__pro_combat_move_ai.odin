package game

import "core:fmt"
import "core:math"
import "core:slice"

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

// Java: ProCombatMoveAi#determineTerritoriesThatCanBeBombed(
//     Map<Territory, ProTerritory> attackMap,
//     Map<Unit, Set<Territory>> sortedUnitAttackOptions,
//     Set<Unit> alreadyAttackedWithUnits)
//   final boolean raidsMayBePrecededByAirBattles =
//       Properties.getRaidsMayBePreceededByAirBattles(data.getProperties());
//   for (final Map.Entry<Unit, Set<Territory>> bomberEntry :
//       territoryManager.getAttackOptions().getBomberMoveMap().entrySet()) {
//     final Unit bomber = bomberEntry.getKey();
//     if (alreadyAttackedWithUnits.contains(bomber)) {
//       return; // already attacked bombers cannot move
//     }
//     Collection<Territory> bomberTargetTerritories = bomberEntry.getValue();
//     if (raidsMayBePrecededByAirBattles) {
//       bomberTargetTerritories =
//           CollectionUtils.getMatches(
//               bomberTargetTerritories,
//               terr -> !AirBattle.territoryCouldPossiblyHaveAirBattleDefenders(
//                   terr, player, data, true));
//     }
//     determineBestBombingAttackForBomber(
//         attackMap, sortedUnitAttackOptions, bomberTargetTerritories, bomber);
//   }
pro_combat_move_ai_determine_territories_that_can_be_bombed :: proc(
	self: ^Pro_Combat_Move_Ai,
	attack_map: map[^Territory]^Pro_Territory,
	sorted_unit_attack_options: map[^Unit]map[^Territory]struct {},
	already_attacked_with_units: map[^Unit]struct {},
) {
	raids_may_be_preceded_by_air_battles :=
		properties_get_raids_may_be_preceeded_by_air_battles(game_data_get_properties(self.data))
	attack_options := pro_territory_manager_get_attack_options(self.territory_manager)
	bomber_move_map := pro_my_move_options_get_bomber_move_map(attack_options)
	for bomber, terrs in bomber_move_map {
		if bomber in already_attacked_with_units {
			return // already attacked bombers cannot move
		}
		bomber_target_territories := terrs
		if raids_may_be_preceded_by_air_battles {
			lambda_ctx := new(
				Pro_Combat_Move_Ai_Lambda_Determine_Territories_That_Can_Be_Bombed_3_Ctx,
			)
			lambda_ctx.self = self
			filtered: map[^Territory]struct {}
			for terr, _ in terrs {
				if pro_combat_move_ai_lambda__determine_territories_that_can_be_bombed__3(
					rawptr(lambda_ctx),
					terr,
				) {
					filtered[terr] = struct {}{}
				}
			}
			bomber_target_territories = filtered
		}
		pro_combat_move_ai_determine_best_bombing_attack_for_bomber(
			self,
			attack_map,
			sorted_unit_attack_options,
			bomber_target_territories,
			bomber,
		)
	}
}

// Java: void doMove(Map<Territory,ProTerritory> attackMap,
//                  IMoveDelegate moveDel, GameData data, GamePlayer player)
pro_combat_move_ai_do_move :: proc(
	self: ^Pro_Combat_Move_Ai,
	attack_map: map[^Territory]^Pro_Territory,
	move_del: ^I_Move_Delegate,
	data: ^Game_Data,
	player: ^Game_Player,
) {
	self.data = data
	self.player = player

	moves1 := pro_move_utils_calculate_move_routes(self.pro_data, player, attack_map, true)
	pro_move_utils_do_move(self.pro_data, &moves1, move_del)

	moves2 := pro_move_utils_calculate_amphib_routes(self.pro_data, player, attack_map, true)
	pro_move_utils_do_move(self.pro_data, &moves2, move_del)

	moves3 := pro_move_utils_calculate_bombard_move_routes(self.pro_data, player, attack_map)
	pro_move_utils_do_move(self.pro_data, &moves3, move_del)

	self.is_bombing = true
	moves4 := pro_move_utils_calculate_bombing_routes(self.pro_data, player, attack_map)
	pro_move_utils_do_move(self.pro_data, &moves4, move_del)
	self.is_bombing = false
}

// Helper for slice.sort_by — sort ProTerritory by value descending,
// matching Comparator.comparingDouble(ProTerritory::getValue).reversed().
@(private = "file")
pro_combat_move_ai_value_desc_less_ :: proc(a, b: ^Pro_Territory) -> bool {
	return pro_territory_get_value(a) > pro_territory_get_value(b)
}

// Java: ProCombatMoveAi#prioritizeAttackOptions(GamePlayer, List<ProTerritory>)
//   Computes an attack value for each candidate territory, removes the ones
//   with non-positive value (or with low value when on the defensive and
//   close to my capital), then sorts the remaining list by value descending.
//   The Java method mutates the passed-in List via Iterator.remove() and
//   List.sort, so the Odin port takes a `^[dynamic]^Pro_Territory`.
pro_combat_move_ai_prioritize_attack_options :: proc(
	self:           ^Pro_Combat_Move_Ai,
	player:         ^Game_Player,
	attack_options: ^[dynamic]^Pro_Territory,
) {
	pro_logger_info("Prioritizing territories to try to attack")

	gm := game_data_get_map(self.data)
	my_capital := pro_data_get_my_capital(self.pro_data)

	i := 0
	for i < len(attack_options^) {
		patd := attack_options^[i]
		t := pro_territory_get_territory(patd)

		// Determine territory attack properties
		is_land: i32 = 0
		if !territory_is_water(t) {
			is_land = 1
		}
		is_neutral: i32 = 0
		if pro_utils_is_neutral_land(t) {
			is_neutral = 1
		}
		is_can_hold: i32 = 0
		if pro_territory_is_can_hold(patd) {
			is_can_hold = 1
		}
		is_amphib: i32 = 0
		if pro_territory_is_need_amphib_units(patd) {
			is_amphib = 1
		}

		// CollectionUtils.getMatches(patd.getMaxEnemyDefenders(player),
		//                            ProMatches.unitIsEnemyAndNotInfa(player))
		max_enemy_defenders := pro_territory_get_max_enemy_defenders(patd, player)
		eni_p, eni_c := pro_matches_unit_is_enemy_and_not_infa(player)
		defending_units: [dynamic]^Unit
		for u in max_enemy_defenders {
			if eni_p(eni_c, u) {
				append(&defending_units, u)
			}
		}
		is_empty_land: i32 = 0
		if !territory_is_water(t) &&
		   len(defending_units) == 0 &&
		   !pro_territory_is_need_amphib_units(patd) {
			is_empty_land = 1
		}

		cap_p, cap_c := matches_territory_is(my_capital)
		cap_neighbors := game_map_get_neighbors_predicate(gm, t, cap_p, cap_c)
		is_adjacent_to_my_capital := len(cap_neighbors) != 0

		is_not_neutral_adjacent_to_my_capital: i32 = 0
		if is_adjacent_to_my_capital {
			enpn_p, enpn_c := pro_matches_territory_is_enemy_not_passive_neutral_land(player)
			if enpn_p(enpn_c, t) {
				is_not_neutral_adjacent_to_my_capital = 1
			}
		}

		factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()
		is_factory: i32 = 0
		if factory_p(factory_c, t) {
			is_factory = 1
		}

		is_ffa: i32 = 0
		if pro_utils_is_ffa(&self.data.game_state, player) {
			is_ffa = 1
		}

		// Determine production value and if it is an enemy capital
		production_and_is_capital := pro_combat_move_ai_get_production_and_is_capital(t)

		// Calculate attack value for prioritization
		tuv_swing := pro_battle_result_get_tuv_swing(pro_territory_get_max_battle_result(patd))
		if is_ffa == 1 && tuv_swing > 0 {
			tuv_swing *= 0.5
		}
		territory_value :=
			(1.0 + f64(is_land) + f64(is_can_hold) * (1.0 + 2.0 * f64(is_ffa) * f64(is_land))) *
			(1.0 + f64(is_empty_land)) *
			(1.0 + f64(is_factory)) *
			(1.0 - 0.5 * f64(is_amphib)) *
			f64(production_and_is_capital.production)
		attack_value :=
			(tuv_swing + territory_value) *
			(1.0 + 4.0 * f64(production_and_is_capital.is_capital)) *
			(1.0 + 2.0 * f64(is_not_neutral_adjacent_to_my_capital)) *
			(1.0 - 0.9 * f64(is_neutral))

		// Check if a negative value neutral territory should be attacked
		if attack_value <= 0 &&
		   !pro_territory_is_need_amphib_units(patd) &&
		   pro_utils_is_neutral_land(t) {

			// Determine enemy neighbor territory production value for neutral land
			nearby_enemy_value := 0.0
			cant_reach_enemy_territories: [dynamic]^Territory
			move_p, move_c := pro_matches_territory_can_move_land_units(player, true)
			nearby_territories := game_map_get_neighbors_predicate(gm, t, move_p, move_c)

			te_p, te_c := matches_is_territory_enemy(player)
			nearby_enemy_territories: [dynamic]^Territory
			for n, _ in nearby_territories {
				if te_p(te_c, n) {
					append(&nearby_enemy_territories, n)
				}
			}
			ho_p, ho_c := matches_territory_has_units_owned_by(player)
			nearby_territories_with_owned_units: [dynamic]^Territory
			for n, _ in nearby_territories {
				if ho_p(ho_c, n) {
					append(&nearby_territories_with_owned_units, n)
				}
			}

			for nearby_enemy_territory in nearby_enemy_territories {
				all_allied_neighbors_have_route := true
				for nearby_allied_territory in nearby_territories_with_owned_units {
					enpa_p, enpa_c :=
						pro_matches_territory_is_enemy_not_passive_neutral_or_allied(player)
					adapter := new(Pro_Combat_Move_Ai_Air_Distance_Ctx)
					adapter.end = nearby_enemy_territory
					adapter.cond = enpa_p
					adapter.cond_ctx = enpa_c
					distance := game_map_get_distance_predicate(
						gm,
						nearby_allied_territory,
						nearby_enemy_territory,
						pro_combat_move_ai_air_distance_pred,
						rawptr(adapter),
					)
					if distance < 0 || distance > 2 {
						all_allied_neighbors_have_route = false
						break
					}
				}
				if !all_allied_neighbors_have_route {
					value := pro_territory_value_utils_find_territory_attack_value(
						self.pro_data,
						player,
						nearby_enemy_territory,
					)
					if value > 0 {
						nearby_enemy_value += value
					}
					append(&cant_reach_enemy_territories, nearby_enemy_territory)
				}
			}
			pro_logger_debug(
				fmt.tprintf(
					"%s calculated nearby enemy value=%v from %d cant-reach territories",
					territory_to_string(t),
					nearby_enemy_value,
					len(cant_reach_enemy_territories),
				),
			)
			if nearby_enemy_value > 0 {
				pro_logger_trace(
					fmt.tprintf(
						"%s updating negative neutral attack value=%v",
						territory_to_string(t),
						attack_value,
					),
				)
				attack_value = nearby_enemy_value * 0.001 / (1.0 - attack_value)
			} else {
				// Check if overwhelming attack strength (more than 5 times)
				max_units_list: [dynamic]^Unit
				for u, _ in pro_territory_get_max_units(patd) {
					append(&max_units_list, u)
				}
				strength_difference := pro_battle_utils_estimate_strength_difference(
					t,
					max_units_list,
					pro_territory_get_max_enemy_defenders(patd, player),
				)
				pro_logger_debug(
					fmt.tprintf(
						"%s calculated strengthDifference=%v",
						territory_to_string(t),
						strength_difference,
					),
				)
				if strength_difference > 500 {
					pro_logger_trace(
						fmt.tprintf(
							"%s updating negative neutral attack value=%v",
							territory_to_string(t),
							attack_value,
						),
					)
					attack_value = strength_difference * 0.00001 / (1.0 - attack_value)
				}
			}
		}

		// Remove negative value territories
		pro_territory_set_value(patd, attack_value)
		if attack_value <= 0 ||
		   (self.is_defensive &&
				   attack_value <= 8 &&
				   game_map_get_distance(gm, my_capital, t) <= 3) {
			pro_logger_debug(
				fmt.tprintf(
					"Removing territory that has a negative attack value: %s, AttackValue=%v",
					territory_to_string(t),
					pro_territory_get_value(patd),
				),
			)
			ordered_remove(attack_options, i)
			continue
		}
		i += 1
	}

	// Sort attack territories by value descending
	slice.sort_by(attack_options^[:], pro_combat_move_ai_value_desc_less_)

	// Log prioritized territories
	for patd in attack_options^ {
		pro_logger_debug(
			fmt.tprintf(
				"AttackValue=%v, TUVSwing=%v, isAmphib=%v, %s",
				pro_territory_get_value(patd),
				pro_battle_result_get_tuv_swing(pro_territory_get_max_battle_result(patd)),
				pro_territory_is_need_amphib_units(patd),
				territory_to_string(pro_territory_get_territory(patd)),
			),
		)
	}
}

// Java: ProCombatMoveAi#removeTerritoriesThatArentWorthAttacking(List<ProTerritory>)
//   Filters out: empty unholdable convoy zones; unholdable neutrals without
//   overwhelming strength; unholdable low-value amphib targets; and neutrals
//   whose attackers would expose adjacent uncovered enemy territories.
//   Mutates the passed list — Odin signature uses `^[dynamic]^Pro_Territory`.
pro_combat_move_ai_remove_territories_that_arent_worth_attacking :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: ^[dynamic]^Pro_Territory,
) {
	pro_logger_info("Remove territories that aren't worth attacking")

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)
	gm := game_data_get_map(self.data)

	// Loop through all prioritized territories
	i := 0
	for i < len(prioritized_territories^) {
		patd := prioritized_territories^[i]
		t := pro_territory_get_territory(patd)
		pro_logger_debug(
			fmt.tprintf(
				"Checking territory=%s with isAmphib=%v",
				territory_to_string(pro_territory_get_territory(patd)),
				pro_territory_is_need_amphib_units(patd),
			),
		)

		enemy_max := pro_other_move_options_get_max(enemy_attack_options, t)

		// Remove empty convoy zones that can't be held
		if !pro_territory_is_can_hold(patd) && enemy_max != nil && territory_is_water(t) {
			eu_p, eu_c := matches_enemy_unit(self.player)
			if !territory_any_units_match(t, eu_p, eu_c) {
				em_units_list: [dynamic]^Unit
				for u, _ in pro_territory_get_max_units(enemy_max) {
					append(&em_units_list, u)
				}
				pro_logger_debug(
					fmt.tprintf(
						"Removing convoy zone that can't be held: %s, enemyAttackers=%s",
						territory_to_string(t),
						pro_utils_summarize_units(em_units_list),
					),
				)
				ordered_remove(prioritized_territories, i)
				continue
			}
		}

		// Remove neutral and low value amphib land territories that can't be held
		is_neutral := pro_utils_is_neutral_land(t)
		max_units_list: [dynamic]^Unit
		for u, _ in pro_territory_get_max_units(patd) {
			append(&max_units_list, u)
		}
		strength_difference := pro_battle_utils_estimate_strength_difference(
			t,
			max_units_list,
			pro_territory_get_max_enemy_defenders(patd, self.player),
		)
		if !pro_territory_is_can_hold(patd) && enemy_max != nil && !territory_is_water(t) {
			if is_neutral && strength_difference <= 500 {
				em_units_list: [dynamic]^Unit
				for u, _ in pro_territory_get_max_units(enemy_max) {
					append(&em_units_list, u)
				}
				pro_logger_debug(
					fmt.tprintf(
						"Removing neutral territory that can't be held: %s, enemyAttackers=%s, enemyAmphibAttackers=%s, strengthDifference=%v",
						territory_to_string(t),
						pro_utils_summarize_units(em_units_list),
						pro_utils_summarize_units(pro_territory_get_max_amphib_units(enemy_max)),
						strength_difference,
					),
				)
				ordered_remove(prioritized_territories, i)
				continue
			} else if pro_territory_is_need_amphib_units(patd) &&
			   pro_territory_get_value(patd) < 2 {
				em_units_list: [dynamic]^Unit
				for u, _ in pro_territory_get_max_units(enemy_max) {
					append(&em_units_list, u)
				}
				pro_logger_debug(
					fmt.tprintf(
						"Removing low value amphib territory that can't be held: %s, enemyAttackers=%s, enemyAmphibAttackers=%s",
						territory_to_string(t),
						pro_utils_summarize_units(em_units_list),
						pro_utils_summarize_units(pro_territory_get_max_amphib_units(enemy_max)),
					),
				)
				ordered_remove(prioritized_territories, i)
				continue
			}
		}

		// Remove neutral territories where attackers are adjacent to enemy
		// territories that aren't being attacked.
		if is_neutral && !territory_is_water(t) && strength_difference <= 500 {
			// Get list of territories I'm attacking
			prioritized_territory_list: [dynamic]^Territory
			for prioritized_territory in prioritized_territories^ {
				append(
					&prioritized_territory_list,
					pro_territory_get_territory(prioritized_territory),
				)
			}

			// Find all territories units are attacking from that are adjacent
			// to territory.
			attack_from_set: map[^Territory]struct {}
			defer delete(attack_from_set)
			for u, _ in pro_territory_get_max_units(patd) {
				attack_from_set[pro_data_get_unit_territory(self.pro_data, u)] = {}
			}
			t_neighbors := game_map_get_neighbors(gm, t)
			defer delete(t_neighbors)
			attack_from_filtered: [dynamic]^Territory
			for k, _ in attack_from_set {
				if k in t_neighbors {
					append(&attack_from_filtered, k)
				}
			}

			// Note: territoryIsEnemyNotNeutralLand (not the passive variant)
			// keeps the neutrality check consistent with `isNeutral` above.
			ent_p, ent_c := pro_matches_territory_is_enemy_not_neutral_land(self.player)

			lambda_ctx := new(
				Pro_Combat_Move_Ai_Lambda_Remove_Territories_That_Arent_Worth_Attacking_0_Ctx,
			)
			lambda_ctx.self = self
			lambda_ctx.enemy_territory = ent_p
			lambda_ctx.enemy_territory_ctx = ent_c
			lambda_ctx.prioritized_territory_list = &prioritized_territory_list

			attack_from_territory_with_enemy_neighbors: ^Territory = nil
			for aft in attack_from_filtered {
				if pro_combat_move_ai_lambda__remove_territories_that_arent_worth_attacking__0(
					rawptr(lambda_ctx),
					aft,
				) {
					attack_from_territory_with_enemy_neighbors = aft
					break
				}
			}
			if attack_from_territory_with_enemy_neighbors != nil {
				pro_logger_debug(
					fmt.tprintf(
						"Removing neutral territory that has attackers that are adjacent to enemies: %s, attackFromTerritory=%s",
						territory_to_string(t),
						territory_to_string(attack_from_territory_with_enemy_neighbors),
					),
				)
				ordered_remove(prioritized_territories, i)
				continue
			}
		}
		i += 1
	}
}

// Java: ProCombatMoveAi#moveOneDefenderToLandTerritoriesBorderingEnemy(List<ProTerritory>)
// Combined predicate `unitIsLand & unitIsNotInfrastructure & unitCanMove` (no
// captures); used as the unit-match argument to
// `Matches.territoryIsEnemyNonNeutralAndHasEnemyUnitMatching`. Each leaf
// matcher follows the project's (proc, rawptr) Predicate convention.
pro_combat_move_ai_pred_land_not_infra_can_move :: proc(_: rawptr, u: ^Unit) -> bool {
	land_p, land_c := matches_unit_is_land()
	if !land_p(land_c, u) {
		return false
	}
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	if !ni_p(ni_c, u) {
		return false
	}
	cm_p, cm_c := matches_unit_can_move()
	return cm_p(cm_c, u)
}

// Combined predicate `unitIsOwnedBy(player) & unitIsNotInfrastructure`
// (player is captured).
Pro_Combat_Move_Ai_Owned_Not_Infra_Ctx :: struct {
	player: ^Game_Player,
}

pro_combat_move_ai_pred_owned_not_infra :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Pro_Combat_Move_Ai_Owned_Not_Infra_Ctx)ctx_ptr
	owned_p, owned_c := matches_unit_is_owned_by(c.player)
	if !owned_p(owned_c, u) {
		return false
	}
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	return ni_p(ni_c, u)
}

// Java:
//   private List<Unit> moveOneDefenderToLandTerritoriesBorderingEnemy(
//       final List<ProTerritory> prioritizedTerritories) {
//     ProLogger.info("Determine which territories to defend with one land unit");
//     final Map<Unit, Set<Territory>> unitMoveMap =
//         territoryManager.getAttackOptions().getUnitMoveMap();
//     final List<Territory> territoriesToAttack = new ArrayList<>();
//     for (final ProTerritory patd : prioritizedTerritories) {
//       territoriesToAttack.add(patd.getTerritory());
//     }
//     final List<Unit> alreadyMovedUnits = new ArrayList<>();
//     for (final Territory t : proData.getMyUnitTerritories()) {
//       final boolean hasAlliedLandUnits =
//           t.anyUnitsMatch(ProMatches.unitCantBeMovedAndIsAlliedDefenderAndNotInfra(player, t));
//       final Set<Territory> enemyNeighbors =
//           data.getMap()
//               .getNeighbors(
//                   t,
//                   Matches.territoryIsEnemyNonNeutralAndHasEnemyUnitMatching(
//                       player,
//                       Matches.unitIsLand()
//                           .and(Matches.unitIsNotInfrastructure())
//                           .and(Matches.unitCanMove())));
//       enemyNeighbors.removeAll(territoriesToAttack);
//       if (!t.isWater() && !hasAlliedLandUnits && !enemyNeighbors.isEmpty()) {
//         int minCost = Integer.MAX_VALUE;
//         Unit minUnit = null;
//         for (final Unit u :
//             t.getMatches(Matches.unitIsOwnedBy(player).and(Matches.unitIsNotInfrastructure()))) {
//           if (proData.getUnitValue(u.getType()) < minCost) {
//             minCost = proData.getUnitValue(u.getType());
//             minUnit = u;
//           }
//         }
//         if (minUnit != null) {
//           unitMoveMap.remove(minUnit);
//           alreadyMovedUnits.add(minUnit);
//           ProLogger.debug(t + ", added one land unit: " + minUnit);
//         }
//       }
//     }
//     return alreadyMovedUnits;
//   }
pro_combat_move_ai_move_one_defender_to_land_territories_bordering_enemy :: proc(
	self: ^Pro_Combat_Move_Ai,
	prioritized_territories: [dynamic]^Pro_Territory,
) -> [dynamic]^Unit {
	pro_logger_info("Determine which territories to defend with one land unit")

	unit_move_map := pro_my_move_options_get_unit_move_map(
		pro_territory_manager_get_attack_options(self.territory_manager),
	)

	territories_to_attack := make([dynamic]^Territory)
	defer delete(territories_to_attack)
	for patd in prioritized_territories {
		append(&territories_to_attack, pro_territory_get_territory(patd))
	}

	already_moved_units := make([dynamic]^Unit)
	gm := game_data_get_map(self.data)

	for t in pro_data_get_my_unit_territories(self.pro_data) {
		allied_p, allied_c := pro_matches_unit_cant_be_moved_and_is_allied_defender_and_not_infra(
			self.player,
			t,
		)
		has_allied_land_units := territory_any_units_match(t, allied_p, allied_c)

		enemy_t_p, enemy_t_c := matches_territory_is_enemy_non_neutral_and_has_enemy_unit_matching(
			self.player,
			pro_combat_move_ai_pred_land_not_infra_can_move,
			nil,
		)
		enemy_neighbors := game_map_get_neighbors_predicate(gm, t, enemy_t_p, enemy_t_c)
		// enemyNeighbors.removeAll(territoriesToAttack)
		for tt in territories_to_attack {
			delete_key(&enemy_neighbors, tt)
		}

		if !territory_is_water(t) && !has_allied_land_units && len(enemy_neighbors) > 0 {
			min_cost := max(i32)
			min_unit: ^Unit = nil
			owned_ctx := new(Pro_Combat_Move_Ai_Owned_Not_Infra_Ctx)
			owned_ctx.player = self.player
			matched := territory_get_matches(
				t,
				pro_combat_move_ai_pred_owned_not_infra,
				rawptr(owned_ctx),
			)
			for u in matched {
				v := pro_data_get_unit_value(self.pro_data, unit_get_type(u))
				if v < min_cost {
					min_cost = v
					min_unit = u
				}
			}
			if min_unit != nil {
				unit_move_map_mut := unit_move_map
				delete_key(&unit_move_map_mut, min_unit)
				append(&already_moved_units, min_unit)
				pro_logger_debug(
					fmt.tprintf(
						"%s, added one land unit: %s",
						territory_to_string(t),
						unit_to_string_no_owner(min_unit),
					),
				)
			}
		}
	}
	return already_moved_units
}

// Java:
//   private void removeTerritoriesWhereTransportsAreExposed() {
//     ProLogger.info("Remove territories where transports are exposed");
//     final Map<Territory, ProTerritory> attackMap =
//         territoryManager.getAttackOptions().getTerritoryMap();
//     final ProOtherMoveOptions enemyAttackOptions = territoryManager.getEnemyAttackOptions();
//     final List<Territory> clearedTerritories =
//         attackMap.entrySet().stream()
//             .filter(e -> !e.getValue().getUnits().isEmpty())
//             .map(Map.Entry::getKey)
//             .collect(Collectors.toList());
//     territoryManager.populateDefenseOptions(clearedTerritories);
//     final Map<Territory, ProTerritory> defendMap =
//         territoryManager.getDefendOptions().getTerritoryMap();
//     final Set<Unit> alreadyAttackedWithUnits = new HashSet<>();
//     for (final ProTerritory t : attackMap.values()) {
//       alreadyAttackedWithUnits.addAll(t.getUnits());
//       alreadyAttackedWithUnits.addAll(t.getAmphibAttackMap().keySet());
//     }
//     for (final ProTerritory t : defendMap.values()) {
//       t.getMaxUnits().removeAll(alreadyAttackedWithUnits);
//     }
//     ... [see Java for full body] ...
//   }
pro_combat_move_ai_remove_territories_where_transports_are_exposed :: proc(
	self: ^Pro_Combat_Move_Ai,
) {
	pro_logger_info("Remove territories where transports are exposed")

	attack_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_attack_options(self.territory_manager),
	)
	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)

	// Find maximum defenders for each transport territory
	cleared_territories := make([dynamic]^Territory)
	defer delete(cleared_territories)
	for t, patd in attack_map {
		if len(pro_territory_get_units(patd)) != 0 {
			append(&cleared_territories, t)
		}
	}
	pro_territory_manager_populate_defense_options(self.territory_manager, cleared_territories)
	defend_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_defend_options(self.territory_manager),
	)

	// Remove units that have already attacked
	already_attacked_with_units := make(map[^Unit]struct {})
	defer delete(already_attacked_with_units)
	for _, t in attack_map {
		for u in pro_territory_get_units(t) {
			already_attacked_with_units[u] = {}
		}
		for u, _ in pro_territory_get_amphib_attack_map(t) {
			already_attacked_with_units[u] = {}
		}
	}
	for _, t in defend_map {
		max_units := pro_territory_get_max_units(t)
		for u in already_attacked_with_units {
			delete_key(&max_units, u)
		}
	}

	// Loop through all prioritized territories
	for t, patd in attack_map {
		pro_logger_debug(
			fmt.tprintf(
				"Checking territory=%s with transport size=%d",
				territory_to_string(pro_territory_get_territory(patd)),
				len(pro_territory_get_transport_territory_map(patd)),
			),
		)
		if territory_is_water(pro_territory_get_territory(patd)) ||
		   len(pro_territory_get_transport_territory_map(patd)) == 0 {
			continue
		}

		// Find all transports for each unload territory
		territory_transport_and_bombard_map := make(map[^Territory][dynamic]^Unit)
		defer {
			for _, lst in territory_transport_and_bombard_map {
				delete(lst)
			}
			delete(territory_transport_and_bombard_map)
		}
		for u, unload_territory in pro_territory_get_transport_territory_map(patd) {
			if existing, ok := territory_transport_and_bombard_map[unload_territory]; ok {
				e := existing
				append(&e, u)
				territory_transport_and_bombard_map[unload_territory] = e
			} else {
				transports := make([dynamic]^Unit)
				append(&transports, u)
				territory_transport_and_bombard_map[unload_territory] = transports
			}
		}

		// Find all bombard units for each unload territory
		for u, unload_territory in pro_territory_get_bombard_territory_map(patd) {
			if existing, ok := territory_transport_and_bombard_map[unload_territory]; ok {
				e := existing
				append(&e, u)
				territory_transport_and_bombard_map[unload_territory] = e
			} else {
				transports := make([dynamic]^Unit)
				append(&transports, u)
				territory_transport_and_bombard_map[unload_territory] = transports
			}
		}

		// Determine counter-attack results for each transport territory
		enemy_tuv_swing := 0.0
		empty_bombard := make([dynamic]^Unit)
		defer delete(empty_bombard)
		for unload_territory, _ in territory_transport_and_bombard_map {
			enemy_max := pro_other_move_options_get_max(enemy_attack_options, unload_territory)
			if enemy_max == nil {
				pro_logger_trace(
					fmt.tprintf(
						"Territory=%s has no enemy attackers",
						territory_to_string(unload_territory),
					),
				)
				continue
			}
			allied_p, allied_c := pro_matches_unit_is_allied_not_owned(self.player)
			defenders_list := territory_get_matches(unload_territory, allied_p, allied_c)
			defenders := make(map[^Unit]struct {})
			defer delete(defenders)
			for u in defenders_list {
				defenders[u] = {}
			}
			delete(defenders_list)
			for u in territory_transport_and_bombard_map[unload_territory] {
				defenders[u] = {}
			}
			if defend_pt, ok := defend_map[unload_territory]; ok && defend_pt != nil {
				for u, _ in pro_territory_get_max_units(defend_pt) {
					defenders[u] = {}
				}
			}
			enemy_attackers_set := pro_territory_get_max_units(enemy_max)
			enemy_attackers := make([dynamic]^Unit)
			defer delete(enemy_attackers)
			for u, _ in enemy_attackers_set {
				append(&enemy_attackers, u)
			}
			defenders_dyn := make([dynamic]^Unit)
			defer delete(defenders_dyn)
			for u, _ in defenders {
				append(&defenders_dyn, u)
			}
			result := pro_odds_calculator_calculate_battle_results(
				self.calc,
				self.pro_data,
				unload_territory,
				enemy_attackers,
				defenders_dyn,
				empty_bombard,
			)
			min_defenders := territory_transport_and_bombard_map[unload_territory]
			min_result := pro_odds_calculator_calculate_battle_results(
				self.calc,
				self.pro_data,
				unload_territory,
				enemy_attackers,
				min_defenders,
				empty_bombard,
			)
			min_tuv_swing := min(
				pro_battle_result_get_tuv_swing(result),
				pro_battle_result_get_tuv_swing(min_result),
			)
			if min_tuv_swing > 0 {
				enemy_tuv_swing += min_tuv_swing
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s, EnemyAttackers=%d, MaxDefenders=%d, MaxEnemyTUVSwing=%v, MinDefenders=%d, MinEnemyTUVSwing=%v",
					territory_to_string(unload_territory),
					len(enemy_attackers),
					len(defenders),
					pro_battle_result_get_tuv_swing(result),
					len(min_defenders),
					pro_battle_result_get_tuv_swing(min_result),
				),
			)
		}

		// Determine whether its worth attacking
		bombard_keys := make([dynamic]^Unit)
		defer delete(bombard_keys)
		for u, _ in pro_territory_get_bombard_territory_map(patd) {
			append(&bombard_keys, u)
		}
		result := pro_odds_calculator_calculate_battle_results(
			self.calc,
			self.pro_data,
			t,
			pro_territory_get_units(patd),
			pro_territory_get_max_enemy_defenders(patd, self.player),
			bombard_keys,
		)
		initial_production_and_is_capital := pro_combat_move_ai_get_production_and_is_capital(t)
		attack_value :=
			pro_battle_result_get_tuv_swing(result) +
			f64(initial_production_and_is_capital.production) *
				(1.0 + 3.0 * f64(initial_production_and_is_capital.is_capital))
		if !pro_territory_is_strafing(patd) && (0.75 * enemy_tuv_swing) > attack_value {
			pro_logger_debug(
				fmt.tprintf(
					"Removing amphib territory: %s, enemyTUVSwing=%v, attackValue=%v",
					territory_to_string(pro_territory_get_territory(patd)),
					enemy_tuv_swing,
					attack_value,
				),
			)
			clear(&patd.units)
			clear(&patd.amphib_attack_map)
			clear(&patd.bombard_territory_map)
		} else {
			pro_logger_debug(
				fmt.tprintf(
					"Keeping amphib territory: %s, enemyTUVSwing=%v, attackValue=%v",
					territory_to_string(pro_territory_get_territory(patd)),
					enemy_tuv_swing,
					attack_value,
				),
			)
		}
	}
}

// Java: ProCombatMoveAi#tryToAttackTerritories(
//     final List<ProTerritory> prioritizedTerritories,
//     final List<Unit> alreadyMovedUnits)
//   Multi-pass solver that distributes the player's available combat
//   units across the prioritized territories. Resets every ProTerritory's
//   working state, then assigns destroyers (anti-sub), affordable
//   land/sea units, non-air units to holdable territories, air units to
//   non-holdable targets, and finally any leftovers. Layered on top of
//   that are transports (naval-attack and amphibious) and bombardment
//   units. Returns the residual unit→territories map of attackers that
//   were considered but never placed.
pro_combat_move_ai_try_to_attack_territories :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: [dynamic]^Pro_Territory,
	already_moved_units:     [dynamic]^Unit,
) -> map[^Unit]map[^Territory]struct {} {
	attack_options := pro_territory_manager_get_attack_options(self.territory_manager)
	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)
	attack_map := pro_my_move_options_get_territory_map(attack_options)
	unit_attack_map := pro_my_move_options_get_unit_move_map(attack_options)
	transport_attack_map := pro_my_move_options_get_transport_move_map(attack_options)
	bombard_map := pro_my_move_options_get_bombard_map(attack_options)
	transport_map_list := pro_my_move_options_get_transport_list(attack_options)

	// Reset lists
	for _, t in attack_map {
		clear(&t.units)
		clear(&t.bombard_territory_map)
		clear(&t.amphib_attack_map)
		clear(&t.transport_territory_map)
		pro_territory_set_battle_result(t, nil)
	}

	// Loop through all units and determine attack options
	unit_attack_options := make(map[^Unit]map[^Territory]struct {})
	for u, ts in unit_attack_map {
		can_attack: map[^Territory]struct {}
		for atd in prioritized_territories {
			at := pro_territory_get_territory(atd)
			if _, ok := ts[at]; ok {
				can_attack[at] = {}
			}
		}
		if len(can_attack) > 0 {
			unit_attack_options[u] = can_attack
		} else {
			delete(can_attack)
		}
	}

	// Sort units by number of attack options and cost
	sorted_unit_attack_options := pro_sort_move_options_utils_sort_unit_move_options(
		self.pro_data,
		unit_attack_options,
	)
	added_units: [dynamic]^Unit
	added_set := make(map[^Unit]struct {})
	defer delete(added_units)
	defer delete(added_set)

	// Try to set at least one destroyer in each sea territory with subs
	for unit, _ in sorted_unit_attack_options {
		is_destroyer_unit := unit_attachment_is_destroyer(unit_get_unit_attachment(unit))
		if !is_destroyer_unit {
			continue
		}
		for t, _ in sorted_unit_attack_options[unit] {
			patd := attack_map[t]
			defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
			sub_p, sub_c := matches_unit_has_sub_battle_abilities()
			has_sub := false
			for d in defending_units {
				if sub_p(sub_c, d) {
					has_sub = true
					break
				}
			}
			destroyer_p, destroyer_c := matches_unit_is_destroyer()
			has_destroyer := false
			for u2 in pro_territory_get_units(patd) {
				if destroyer_p(destroyer_c, u2) {
					has_destroyer = true
					break
				}
			}
			if has_sub && !has_destroyer {
				pro_territory_add_unit(patd, unit)
				append(&added_units, unit)
				added_set[unit] = {}
				break
			}
		}
	}
	for u in added_units {
		delete_key(&sorted_unit_attack_options, u)
	}

	// Set enough land and sea units in territories to have at least a chance of winning
	for unit, _ in sorted_unit_attack_options {
		ua := unit_get_unit_attachment(unit)
		is_air_unit := unit_attachment_is_air(ua)
		land_p, land_c := matches_unit_is_land()
		is_expensive_land_unit :=
			land_p(land_c, unit) &&
			f64(pro_data_get_unit_value(self.pro_data, unit_get_type(unit))) >
				2.0 * pro_data_get_min_cost_per_hit_point(self.pro_data)
		_, in_added := added_set[unit]
		if is_air_unit || is_expensive_land_unit || in_added {
			continue
		}

		// Track the smallest estimate (Java uses TreeMap.firstKey()).
		min_estimate := 0.0
		min_t: ^Territory = nil
		for t, _ in sorted_unit_attack_options[unit] {
			pro_territory := attack_map[t]
			if territory_is_water(t) && !pro_territory_is_can_hold(pro_territory) {
				continue
			}
			defending_units := pro_territory_get_max_enemy_defenders(pro_territory, self.player)
			estimate := pro_battle_utils_estimate_strength_difference(
				t,
				pro_territory_get_units(pro_territory),
				defending_units,
			)
			aa_p, aa_c := matches_unit_is_aa_for_anything()
			has_aa := false
			for d in defending_units {
				if aa_p(aa_c, d) {
					has_aa = true
					break
				}
			}
			if has_aa {
				estimate -= 10
			}
			if min_t == nil || estimate < min_estimate {
				min_estimate = estimate
				min_t = t
			}
		}
		if min_t != nil && min_estimate < 40 {
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				unit,
				already_moved_units,
				attack_map,
			)
			pro_territory_add_units(attack_map[min_t], units_to_add)
			for u2 in units_to_add {
				append(&added_units, u2)
				added_set[u2] = {}
			}
		}
	}
	for u in added_units {
		delete_key(&sorted_unit_attack_options, u)
	}

	// Re-sort attack options
	sorted_unit_attack_options = pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
		self.pro_data,
		self.player,
		sorted_unit_attack_options,
		attack_map,
		self.calc,
	)

	// Set non-air units in territories that can be held
	for unit, _ in sorted_unit_attack_options {
		is_air_unit := unit_attachment_is_air(unit_get_unit_attachment(unit))
		_, in_added := added_set[unit]
		if is_air_unit || in_added {
			continue
		}
		min_win_territory: ^Territory = nil
		min_win_percentage := pro_data_get_win_percentage(self.pro_data)
		for t, _ in sorted_unit_attack_options[unit] {
			patd := attack_map[t]
			if !pro_territory_is_currently_wins(patd) && pro_territory_is_can_hold(patd) {
				if pro_territory_get_battle_result(patd) == nil {
					pro_territory_estimate_battle_result(patd, self.calc, self.player)
				}
				result := pro_territory_get_battle_result(patd)
				if pro_battle_result_get_win_percentage(result) < min_win_percentage ||
				   (!pro_battle_result_is_has_land_unit_remaining(result) &&
						   min_win_territory == nil) {
					min_win_percentage = pro_battle_result_get_win_percentage(result)
					min_win_territory = t
				}
			}
		}
		if min_win_territory != nil {
			pro_territory_set_battle_result(attack_map[min_win_territory], nil)
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				unit,
				already_moved_units,
				attack_map,
			)
			pro_territory_add_units(attack_map[min_win_territory], units_to_add)
			for u2 in units_to_add {
				append(&added_units, u2)
				added_set[u2] = {}
			}
		}
	}
	for u in added_units {
		delete_key(&sorted_unit_attack_options, u)
	}

	// Re-sort attack options
	sorted_unit_attack_options = pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
		self.pro_data,
		self.player,
		sorted_unit_attack_options,
		attack_map,
		self.calc,
	)

	// Set air units in territories that can't be held (don't move planes to empty territories)
	live_enemy_capitals := pro_utils_get_live_enemy_capitals(&self.data.game_state, self.player)
	defer delete(live_enemy_capitals)
	live_allied_capitals := pro_utils_get_live_allied_capitals(&self.data.game_state, self.player)
	defer delete(live_allied_capitals)
	gm := game_data_get_map(self.data)
	for unit, _ in sorted_unit_attack_options {
		is_air_unit := unit_attachment_is_air(unit_get_unit_attachment(unit))
		if !is_air_unit {
			continue
		}
		min_win_territory: ^Territory = nil
		min_win_percentage := pro_data_get_win_percentage(self.pro_data)
		for t, _ in sorted_unit_attack_options[unit] {
			patd := attack_map[t]
			if pro_territory_is_currently_wins(patd) || pro_territory_is_can_hold(patd) {
				continue
			}

			// Avoid this territory unless safe landing nearby
			is_enemy_capital := false
			for cap in live_enemy_capitals {
				if cap == t {
					is_enemy_capital = true
					break
				}
			}
			allied_caps_set := make(map[^Territory]struct {})
			for cap in live_allied_capitals {
				allied_caps_set[cap] = {}
			}
			// matches.territoryHasNeighborMatching(map,
			//   ProUtils.getLiveAlliedCapitals(...)::contains).test(t)
			is_adjacent_to_allied_capital := false
			neighbors := game_map_get_neighbors(gm, t)
			for n, _ in neighbors {
				if _, ok := allied_caps_set[n]; ok {
					is_adjacent_to_allied_capital = true
					break
				}
			}
			delete(neighbors)
			delete(allied_caps_set)

			range_left := i32(unit_get_movement_left(unit))
			air_p, air_c := pro_matches_territory_can_move_air_units_and_no_aa(
				self.data,
				self.player,
				true,
			)
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
			if !is_enemy_capital && !is_adjacent_to_allied_capital && uses_more_than_half_of_range {
				continue
			}

			// Check battle results
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			result := pro_territory_get_battle_result(patd)
			if pro_battle_result_get_win_percentage(result) < min_win_percentage ||
			   (!pro_battle_result_is_has_land_unit_remaining(result) && min_win_territory == nil) {
				defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
				enemy_p, enemy_c := pro_matches_unit_is_enemy_and_not_infa(self.player)
				has_no_defenders := true
				for d in defending_units {
					if enemy_p(enemy_c, d) {
						has_no_defenders = false
						break
					}
				}
				is_overwhelming_win := pro_battle_utils_check_for_overwhelming_win(
					t,
					pro_territory_get_units(patd),
					defending_units,
				)
				aa_p, aa_c := matches_unit_is_aa_for_anything()
				has_aa := false
				for d in defending_units {
					if aa_p(aa_c, d) {
						has_aa = true
						break
					}
				}
				if !has_no_defenders &&
				   !is_overwhelming_win &&
				   (!has_aa || pro_battle_result_get_win_percentage(result) < min_win_percentage) {
					min_win_percentage = pro_battle_result_get_win_percentage(result)
					min_win_territory = t
					if pro_territory_is_strafing(patd) {
						break
					}
				}
			}
		}
		if min_win_territory != nil {
			pro_territory_set_battle_result(attack_map[min_win_territory], nil)
			pro_territory_add_unit(attack_map[min_win_territory], unit)
			append(&added_units, unit)
			added_set[unit] = {}
		}
	}
	for u in added_units {
		delete_key(&sorted_unit_attack_options, u)
	}

	// Re-sort attack options
	sorted_unit_attack_options = pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
		self.pro_data,
		self.player,
		sorted_unit_attack_options,
		attack_map,
		self.calc,
	)

	// Set remaining units in any territory that needs it
	for unit, _ in sorted_unit_attack_options {
		if _, in_added := added_set[unit]; in_added {
			continue
		}
		is_air_unit := unit_attachment_is_air(unit_get_unit_attachment(unit))
		min_win_territory: ^Territory = nil
		min_win_percentage := pro_data_get_win_percentage(self.pro_data)
		for t, _ in sorted_unit_attack_options[unit] {
			patd := attack_map[t]
			if pro_territory_is_currently_wins(patd) {
				continue
			}

			// Air landing safety
			infra_p, infra_c := pro_matches_territory_has_infra_factory_and_is_allied_land(
				self.player,
			)
			hn_p, hn_c := matches_territory_has_neighbor_matching(gm, infra_p, infra_c)
			is_adjacent_to_allied_factory := hn_p(hn_c, t)
			range_left := i32(unit_get_movement_left(unit))
			air_p, air_c := pro_matches_territory_can_move_air_units_and_no_aa(
				self.data,
				self.player,
				true,
			)
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
			territory_value_is_less_than_unit_value :=
				pro_territory_get_value(patd) <
				f64(pro_data_get_unit_value(self.pro_data, unit_get_type(unit)))
			if is_air_unit &&
			   !is_adjacent_to_allied_factory &&
			   uses_more_than_half_of_range &&
			   (territory_value_is_less_than_unit_value ||
					   (!territory_is_water(t) && !pro_territory_is_can_hold(patd))) {
				continue
			}
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			result := pro_territory_get_battle_result(patd)
			if pro_battle_result_get_win_percentage(result) < min_win_percentage ||
			   (!pro_battle_result_is_has_land_unit_remaining(result) && min_win_territory == nil) {
				defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
				enemy_p, enemy_c := pro_matches_unit_is_enemy_and_not_infa(self.player)
				has_no_defenders := true
				for d in defending_units {
					if enemy_p(enemy_c, d) {
						has_no_defenders = false
						break
					}
				}
				is_overwhelming_win := pro_battle_utils_check_for_overwhelming_win(
					t,
					pro_territory_get_units(patd),
					defending_units,
				)
				aa_p, aa_c := matches_unit_is_aa_for_anything()
				has_aa := false
				for d in defending_units {
					if aa_p(aa_c, d) {
						has_aa = true
						break
					}
				}
				if !is_air_unit ||
				   (!has_no_defenders &&
						   !is_overwhelming_win &&
						   (!has_aa ||
								   pro_battle_result_get_win_percentage(result) <
									   min_win_percentage)) {
					min_win_percentage = pro_battle_result_get_win_percentage(result)
					min_win_territory = t
				}
			}
		}
		if min_win_territory != nil {
			pro_territory_set_battle_result(attack_map[min_win_territory], nil)
			units_to_add := pro_transport_utils_get_units_to_add(
				self.pro_data,
				unit,
				already_moved_units,
				attack_map,
			)
			pro_territory_add_units(attack_map[min_win_territory], units_to_add)
			for u2 in units_to_add {
				append(&added_units, u2)
				added_set[u2] = {}
			}
		}
	}
	for u in added_units {
		delete_key(&sorted_unit_attack_options, u)
	}

	// Re-sort attack options
	sorted_unit_attack_options = pro_sort_move_options_utils_sort_unit_needed_options(
		self.pro_data,
		self.player,
		sorted_unit_attack_options,
		attack_map,
		self.calc,
	)

	// If transports can take casualties try placing in naval battles first
	already_attacked_with_transports: [dynamic]^Unit
	defer delete(already_attacked_with_transports)
	already_attacked_with_transports_set := make(map[^Unit]struct {})
	defer delete(already_attacked_with_transports_set)
	if !properties_get_transport_casualties_restricted(game_data_get_properties(self.data)) {
		// Loop through all my transports and see which territories they can attack
		transport_attack_options := make(map[^Unit]map[^Territory]struct {})
		for u, ts in transport_attack_map {
			can_attack: map[^Territory]struct {}
			for atd in prioritized_territories {
				at := pro_territory_get_territory(atd)
				if _, ok := ts[at]; ok {
					can_attack[at] = {}
				}
			}
			if len(can_attack) > 0 {
				transport_attack_options[u] = can_attack
			} else {
				delete(can_attack)
			}
		}

		// Loop through transports with attack options and determine if any naval battle needs it
		for transport, ts in transport_attack_options {
			for t, _ in ts {
				patd := attack_map[t]
				defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
				if !pro_territory_is_currently_wins(patd) &&
				   !unit_is_transporting_in_territory_arg(
						   transport,
						   pro_data_get_unit_territory(self.pro_data, transport),
					   ) &&
				   len(defending_units) > 0 {
					if pro_territory_get_battle_result(patd) == nil {
						pro_territory_estimate_battle_result(patd, self.calc, self.player)
					}
					result := pro_territory_get_battle_result(patd)
					if pro_battle_result_get_win_percentage(result) <
						   pro_data_get_win_percentage(self.pro_data) ||
					   !pro_battle_result_is_has_land_unit_remaining(result) {
						pro_territory_add_unit(patd, transport)
						pro_territory_set_battle_result(patd, nil)
						append(&already_attacked_with_transports, transport)
						already_attacked_with_transports_set[transport] = {}
						pro_logger_trace(
							fmt.tprintf("Adding attack transport to: %s", territory_to_string(t)),
						)
						break
					}
				}
			}
		}
	}

	// Loop through all my transports and see which can make amphib attack
	amphib_attack_options := make(map[^Unit]map[^Territory]struct {})
	for pro_transport_data in transport_map_list {
		transport_unit := pro_transport_get_transport(pro_transport_data)
		if _, in_set := already_attacked_with_transports_set[transport_unit]; in_set {
			continue
		}
		can_amphib: map[^Territory]struct {}
		tmap := pro_transport_get_transport_map(pro_transport_data)
		for atd in prioritized_territories {
			at := pro_territory_get_territory(atd)
			if _, ok := tmap[at]; ok {
				can_amphib[at] = {}
			}
		}
		if len(can_amphib) > 0 {
			amphib_attack_options[transport_unit] = can_amphib
		} else {
			delete(can_amphib)
		}
	}

	// Loop through transports with amphib attack options and determine if any land battle needs it
	for transport, ts in amphib_attack_options {
		min_win_territory: ^Territory = nil
		min_win_percentage := pro_data_get_win_percentage(self.pro_data)
		min_amphib_units_to_add: [dynamic]^Unit
		have_amphib_units := false
		min_unload_from_territory: ^Territory = nil
		for t, _ in ts {
			patd := attack_map[t]
			if pro_territory_is_currently_wins(patd) {
				continue
			}
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			result := pro_territory_get_battle_result(patd)
			if !(pro_battle_result_get_win_percentage(result) < min_win_percentage ||
				   (!pro_battle_result_is_has_land_unit_remaining(result) &&
						   min_win_territory == nil)) {
				continue
			}

			// Find units that haven't attacked and can be transported
			already_attacked_with_units_set := pro_transport_utils_get_moved_units(
				already_moved_units,
				attack_map,
			)
			already_attacked_units_dyn: [dynamic]^Unit
			for u, _ in already_attacked_with_units_set {
				append(&already_attacked_units_dyn, u)
			}
			delete(already_attacked_with_units_set)

			for inner_pt in transport_map_list {
				if pro_transport_get_transport(inner_pt) != transport {
					continue
				}
				territories_can_load_from := pro_transport_get_transport_map(inner_pt)[t]
				amphib_units_to_add := pro_transport_utils_get_units_to_transport_from_territories_4(
					self.player,
					transport,
					territories_can_load_from,
					already_attacked_units_dyn,
				)
				if len(amphib_units_to_add) == 0 {
					delete(amphib_units_to_add)
					continue
				}

				// Find the best territory to move transport
				min_strength_difference := math.INF_F64
				min_unload_from_territory = nil
				sea_p, sea_c := pro_matches_territory_can_move_sea_units(self.player, false)
				territories_to_move_transport := game_map_get_neighbors_predicate(
					gm,
					t,
					sea_p,
					sea_c,
				)
				load_from_territories := make(map[^Territory]struct {})
				defer delete(load_from_territories)
				for u in amphib_units_to_add {
					load_from_territories[pro_data_get_unit_territory(self.pro_data, u)] = {}
				}
				for destination, _ in territories_to_move_transport {
					sea_tmap := pro_transport_get_sea_transport_map(inner_pt)
					reachable, has_dest := sea_tmap[destination]
					if !has_dest {
						continue
					}
					contains_all := true
					for lf, _ in load_from_territories {
						if _, ok := reachable[lf]; !ok {
							contains_all = false
							break
						}
					}
					if !contains_all {
						continue
					}
					attackers: [dynamic]^Unit
					if max := pro_other_move_options_get_max(enemy_attack_options, destination);
					   max != nil {
						for u, _ in pro_territory_get_max_units(max) {
							append(&attackers, u)
						}
					}
					allied_p, allied_c := matches_is_unit_allied(self.player)
					defenders := territory_get_matches(destination, allied_p, allied_c)
					append(&defenders, transport)
					strength_difference := pro_battle_utils_estimate_strength_difference(
						destination,
						attackers,
						defenders,
					)
					delete(attackers)
					delete(defenders)
					if strength_difference <= min_strength_difference {
						min_strength_difference = strength_difference
						min_unload_from_territory = destination
					}
				}
				delete(territories_to_move_transport)
				min_win_territory = t
				min_win_percentage = pro_battle_result_get_win_percentage(result)
				if have_amphib_units {
					delete(min_amphib_units_to_add)
				}
				min_amphib_units_to_add = amphib_units_to_add
				have_amphib_units = true
				break
			}
			delete(already_attacked_units_dyn)
		}
		if min_win_territory != nil {
			if min_unload_from_territory != nil {
				attack_map[min_win_territory].transport_territory_map[transport] =
					min_unload_from_territory
			}
			pro_territory_add_units(attack_map[min_win_territory], min_amphib_units_to_add)
			pro_territory_put_amphib_attack_map(
				attack_map[min_win_territory],
				transport,
				min_amphib_units_to_add,
			)
			pro_territory_set_battle_result(attack_map[min_win_territory], nil)
			for unit in min_amphib_units_to_add {
				delete_key(&sorted_unit_attack_options, unit)
			}
			pro_logger_trace(
				fmt.tprintf(
					"Adding amphibious attack to %s, units=%d, unloadFrom=%s",
					territory_to_string(min_win_territory),
					len(min_amphib_units_to_add),
					territory_to_string(min_unload_from_territory),
				),
			)
		} else if have_amphib_units {
			delete(min_amphib_units_to_add)
		}
	}

	// Get all units that have already moved
	already_attacked_with_units := make(map[^Unit]struct {})
	defer delete(already_attacked_with_units)
	for _, t in attack_map {
		for u in pro_territory_get_units(t) {
			already_attacked_with_units[u] = {}
		}
		for u, _ in pro_territory_get_amphib_attack_map(t) {
			already_attacked_with_units[u] = {}
		}
	}

	// Loop through all my bombard units and see which can bombard
	bombard_options := make(map[^Unit]map[^Territory]struct {})
	for u, _ in bombard_map {
		if _, in_attacked := already_attacked_with_units[u]; in_attacked {
			continue
		}
		can_bombard: map[^Territory]struct {}
		for patd in prioritized_territories {
			defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
			infra_p, infra_c := matches_unit_is_infrastructure()
			has_defenders := false
			for d in defending_units {
				if !infra_p(infra_c, d) {
					has_defenders = true
					break
				}
			}
			territory := pro_territory_get_territory(patd)
			_, in_bombard := bombard_map[u][territory]
			if in_bombard &&
			   len(pro_territory_get_transport_territory_map(patd)) != 0 &&
			   has_defenders &&
			   !unit_is_transporting_in_territory_arg(
					   u,
					   pro_data_get_unit_territory(self.pro_data, u),
				   ) {
				can_bombard[territory] = {}
			}
		}
		if len(can_bombard) > 0 {
			bombard_options[u] = can_bombard
		} else {
			delete(can_bombard)
		}
	}

	// Loop through bombard units to see if any amphib battles need
	for unit, ts in bombard_options {
		min_win_territory: ^Territory = nil
		min_win_percentage := max(f64)
		min_bombard_from_territory: ^Territory = nil
		for t, _ in ts {
			patd := attack_map[t]
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			result := pro_territory_get_battle_result(patd)
			if pro_battle_result_get_win_percentage(result) < min_win_percentage ||
			   (!pro_battle_result_is_has_land_unit_remaining(result) && min_win_territory == nil) {
				bombard_from_territory: ^Territory = nil
				bom_map := pro_territory_get_bombard_options_map(patd)
				for _, unload_from_territory in pro_territory_get_transport_territory_map(patd) {
					if reach, ok := bom_map[unit]; ok {
						if _, has := reach[unload_from_territory]; has {
							bombard_from_territory = unload_from_territory
						}
					}
				}
				if bombard_from_territory != nil {
					min_win_territory = t
					min_win_percentage = pro_battle_result_get_win_percentage(result)
					min_bombard_from_territory = bombard_from_territory
				}
			}
		}
		if min_win_territory != nil {
			attack_map[min_win_territory].bombard_territory_map[unit] =
				min_bombard_from_territory
			pro_territory_set_battle_result(attack_map[min_win_territory], nil)
			delete_key(&sorted_unit_attack_options, unit)
			pro_logger_trace(
				fmt.tprintf(
					"Adding bombard to %s, units=%v, bombardFrom=%s",
					territory_to_string(min_win_territory),
					unit,
					territory_to_string(min_bombard_from_territory),
				),
			)
		}
	}
	return sorted_unit_attack_options
}

// Java: ProCombatMoveAi#determineTerritoriesToAttack(List<ProTerritory> prioritizedTerritories)
//   Iteratively grows the set of territories under attack: tries the first N,
//   estimates each battle, and either commits the slice (incrementing N) or
//   removes the last failing territory. Also drops still-amphib targets once
//   we've exhausted our attack transports.
pro_combat_move_ai_determine_territories_to_attack :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: ^[dynamic]^Pro_Territory,
) {
	pro_logger_info("Determine which territories to attack")

	// Assign units to territories by prioritization
	num_to_attack: i32 = i32(min(1, len(prioritized_territories^)))
	have_removed_all_amphib_territories := false
	for {
		territories_to_try_to_attack: [dynamic]^Pro_Territory
		for i: i32 = 0; i < num_to_attack; i += 1 {
			append(&territories_to_try_to_attack, prioritized_territories^[i])
		}
		pro_logger_debug(fmt.tprintf("Current number of territories: %d", num_to_attack))
		empty_already_moved: [dynamic]^Unit
		residual := pro_combat_move_ai_try_to_attack_territories(
			self,
			territories_to_try_to_attack,
			empty_already_moved,
		)
		delete(empty_already_moved)
		// Discard residual map (Java only consumes it indirectly via attackMap state).
		for _, inner in residual {
			delete(inner)
		}
		delete(residual)

		// Determine if all attacks are successful
		are_successful := true
		for patd in territories_to_try_to_attack {
			t := pro_territory_get_territory(patd)
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			pro_logger_trace(
				fmt.tprintf(
					"%s with attackers: %v",
					pro_territory_get_result_string(patd),
					pro_territory_get_units(patd),
				),
			)
			estimate := pro_battle_utils_estimate_strength_difference(
				t,
				pro_territory_get_units(patd),
				pro_territory_get_max_enemy_defenders(patd, self.player),
			)
			result := pro_territory_get_battle_result(patd)
			if !pro_territory_is_strafing(patd) &&
			   estimate < pro_territory_get_strength_estimate(patd) &&
			   (pro_battle_result_get_win_percentage(result) <
					   self.pro_data.min_win_percentage ||
					   !pro_battle_result_is_has_land_unit_remaining(result)) {
				are_successful = false
			}
		}

		if are_successful {
			for patd in territories_to_try_to_attack {
				pro_territory_set_can_attack(patd, true)
				estimate := pro_battle_utils_estimate_strength_difference(
					pro_territory_get_territory(patd),
					pro_territory_get_units(patd),
					pro_territory_get_max_enemy_defenders(patd, self.player),
				)
				if estimate < pro_territory_get_strength_estimate(patd) {
					pro_territory_set_strength_estimate(patd, estimate)
				}
			}

			// If already used all transports then remove any remaining amphib territories
			if !have_removed_all_amphib_territories &&
			   pro_territory_manager_have_used_all_attack_transports(self.territory_manager) {
				amphib_territories_to_remove: [dynamic]^Pro_Territory
				defer delete(amphib_territories_to_remove)
				for i: i32 = num_to_attack; i < i32(len(prioritized_territories^)); i += 1 {
					if pro_territory_is_need_amphib_units(prioritized_territories^[i]) {
						append(&amphib_territories_to_remove, prioritized_territories^[i])
						pro_logger_debug(
							fmt.tprintf(
								"Removing amphib territory since already used all transports: %s",
								territory_to_string(
									pro_territory_get_territory(prioritized_territories^[i]),
								),
							),
						)
					}
				}
				for rem in amphib_territories_to_remove {
					for j := 0; j < len(prioritized_territories^); j += 1 {
						if prioritized_territories^[j] == rem {
							ordered_remove(prioritized_territories, j)
							break
						}
					}
				}
				have_removed_all_amphib_territories = true
			}

			// Can attack all territories in list so end
			num_to_attack += 1
			if num_to_attack > i32(len(prioritized_territories^)) {
				delete(territories_to_try_to_attack)
				break
			}
		} else {
			pro_logger_debug(
				fmt.tprintf(
					"Removing territory: %s",
					territory_to_string(
						pro_territory_get_territory(
							prioritized_territories^[num_to_attack - 1],
						),
					),
				),
			)
			ordered_remove(prioritized_territories, int(num_to_attack - 1))
			if num_to_attack > i32(len(prioritized_territories^)) {
				num_to_attack -= 1
			}
		}
		delete(territories_to_try_to_attack)
	}
	pro_logger_debug(fmt.tprintf("Final number of territories: %d", num_to_attack - 1))
}

// Java: ProCombatMoveAi#determineTerritoriesThatCanBeHeld(
//     List<ProTerritory> prioritizedTerritories, List<Territory> clearedTerritories)
//   Decides for each prioritized territory whether we can hold it after
//   capturing it. Uses ProTerritoryValueUtils to score the value of every
//   territory adjacent to our attackers, then runs a counter-attack
//   simulation through the odds calculator.
pro_combat_move_ai_determine_territories_that_can_be_held :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: [dynamic]^Pro_Territory,
	cleared_territories:     [dynamic]^Territory,
) {
	pro_logger_info("Check if we should try to hold attack territories")

	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)
	attack_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_attack_options(self.territory_manager),
	)

	// Determine which territories to try and hold
	territories_to_check := make(map[^Territory]struct {})
	defer delete(territories_to_check)
	not_air_p, not_air_c := matches_unit_is_not_air()
	for patd in prioritized_territories {
		t := pro_territory_get_territory(patd)
		territories_to_check[t] = {}
		for u, _ in pro_territory_get_max_units(patd) {
			if not_air_p(not_air_c, u) {
				territories_to_check[pro_data_get_unit_territory(self.pro_data, u)] = {}
			}
		}
	}

	empty_cant_be_held: [dynamic]^Territory
	defer delete(empty_cant_be_held)
	territory_value_map := pro_territory_value_utils_find_territory_values(
		self.pro_data,
		self.player,
		empty_cant_be_held,
		cleared_territories,
		territories_to_check,
	)
	defer delete(territory_value_map)

	for patd in prioritized_territories {
		t := pro_territory_get_territory(patd)

		// If strafing then can't hold
		if pro_territory_is_strafing(patd) {
			pro_territory_set_can_hold(patd, false)
			pro_logger_debug(fmt.tprintf("%s, strafing so CanHold=false", territory_to_string(t)))
			continue
		}

		// Set max enemy attackers
		enemy_attack_max := pro_other_move_options_get_max(enemy_attack_options, t)
		if enemy_attack_max != nil {
			enemy_attacking_units_set := make(map[^Unit]struct {})
			defer delete(enemy_attacking_units_set)
			for u, _ in pro_territory_get_max_units(enemy_attack_max) {
				enemy_attacking_units_set[u] = {}
			}
			for u in pro_territory_get_max_amphib_units(enemy_attack_max) {
				enemy_attacking_units_set[u] = {}
			}
			enemy_attacking_units_list: [dynamic]^Unit
			for u, _ in enemy_attacking_units_set {
				append(&enemy_attacking_units_list, u)
			}
			pro_territory_set_max_enemy_units(patd, enemy_attacking_units_list)
			delete(enemy_attacking_units_list)
			max_bombard := pro_territory_get_max_bombard_units(enemy_attack_max)
			pro_territory_set_max_enemy_bombard_units(patd, max_bombard)
		}

		// Add strategic value for factories
		is_factory: i32 = 0
		factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()
		if factory_p(factory_c, t) {
			is_factory = 1
		}

		// Determine whether its worth trying to hold territory
		total_value := 0.0
		non_air_attackers: [dynamic]^Unit
		defer delete(non_air_attackers)
		for u, _ in pro_territory_get_max_units(patd) {
			if not_air_p(not_air_c, u) {
				append(&non_air_attackers, u)
			}
		}
		for u in non_air_attackers {
			total_value += territory_value_map[pro_data_get_unit_territory(self.pro_data, u)]
		}
		average_value := 0.0
		if len(non_air_attackers) > 0 {
			average_value = total_value / f64(len(non_air_attackers)) * 0.75
		}
		territory_value := territory_value_map[t] * (1.0 + 4.0 * f64(is_factory))
		if !territory_is_water(t) && territory_value < average_value {
			pro_territory_set_can_hold(attack_map[t], false)
			pro_logger_debug(
				fmt.tprintf(
					"%s, CanHold=false, value=%v, averageAttackFromValue=%v",
					territory_to_string(t),
					territory_value_map[t],
					average_value,
				),
			)
			continue
		}
		if pro_other_move_options_get_max(enemy_attack_options, t) != nil {
			// Find max remaining defenders
			attacking_units_set := make(map[^Unit]struct {})
			defer delete(attacking_units_set)
			for u, _ in pro_territory_get_max_units(patd) {
				attacking_units_set[u] = {}
			}
			for u in pro_territory_get_max_amphib_units(patd) {
				attacking_units_set[u] = {}
			}
			attacking_units_list: [dynamic]^Unit
			defer delete(attacking_units_list)
			for u, _ in attacking_units_set {
				append(&attacking_units_list, u)
			}
			max_bombard_set := pro_territory_get_max_bombard_units(patd)
			max_bombard_list: [dynamic]^Unit
			defer delete(max_bombard_list)
			for u, _ in max_bombard_set {
				append(&max_bombard_list, u)
			}
			result := pro_odds_calculator_estimate_attack_battle_results(
				self.calc,
				self.pro_data,
				t,
				attacking_units_list,
				pro_territory_get_max_enemy_defenders(patd, self.player),
				max_bombard_list,
			)
			air_p, air_c := matches_unit_is_air()
			remaining_units_to_defend_with: [dynamic]^Unit
			for u in pro_battle_result_get_average_attackers_remaining(result) {
				if !air_p(air_c, u) {
					append(&remaining_units_to_defend_with, u)
				}
			}
			pro_logger_debug(
				fmt.tprintf(
					"%s, value=%v, averageAttackFromValue=%v, MyAttackers=%d, RemainingUnits=%d",
					territory_to_string(t),
					territory_value_map[t],
					average_value,
					len(attacking_units_list),
					len(remaining_units_to_defend_with),
				),
			)

			// Determine counter-attack results to see if I can hold it
			enemy_max := pro_other_move_options_get_max(enemy_attack_options, t)
			enemy_max_bombard_set := pro_territory_get_max_bombard_units(enemy_max)
			enemy_max_bombard_list: [dynamic]^Unit
			defer delete(enemy_max_bombard_list)
			for u, _ in enemy_max_bombard_set {
				append(&enemy_max_bombard_list, u)
			}
			result2 := pro_odds_calculator_calculate_battle_results(
				self.calc,
				self.pro_data,
				t,
				pro_territory_get_max_enemy_units(patd),
				remaining_units_to_defend_with,
				enemy_max_bombard_list,
			)
			can_hold :=
				(!pro_battle_result_is_has_land_unit_remaining(result2) && !territory_is_water(t)) ||
				(pro_battle_result_get_tuv_swing(result2) < 0) ||
				(pro_battle_result_get_win_percentage(result2) < self.pro_data.min_win_percentage)
			pro_territory_set_can_hold(patd, can_hold)
			pro_logger_debug(
				fmt.tprintf(
					"%s, CanHold=%v, MyDefenders=%d, EnemyAttackers=%d, win%%=%v, EnemyTUVSwing=%v, hasLandUnitRemaining=%v",
					territory_to_string(t),
					can_hold,
					len(remaining_units_to_defend_with),
					len(pro_territory_get_max_enemy_units(patd)),
					pro_battle_result_get_win_percentage(result2),
					pro_battle_result_get_tuv_swing(result2),
					pro_battle_result_is_has_land_unit_remaining(result2),
				),
			)
			delete(remaining_units_to_defend_with)
		} else {
			pro_territory_set_can_hold(attack_map[t], true)
			pro_logger_debug(
				fmt.tprintf(
					"%s, CanHold=true since no enemy counter attackers, value=%v, averageAttackFromValue=%v",
					territory_to_string(t),
					territory_value_map[t],
					average_value,
				),
			)
		}
	}
}

// Java: ProCombatMoveAi#determineUnitsToAttackWith(
//     List<ProTerritory> prioritizedTerritories, List<Unit> alreadyMovedUnits)
//   Iteratively distributes our attack force across the prioritized
//   territories. After each round it re-evaluates whether each territory
//   should still be attacked (computing TUV swing, counter-attack risk and
//   neutral-territory penalties); when a territory is rejected it is
//   removed from `prioritizedTerritories` and the loop runs again.
pro_combat_move_ai_determine_units_to_attack_with :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: ^[dynamic]^Pro_Territory,
	already_moved_units:     [dynamic]^Unit,
) {
	pro_logger_info("Determine units to attack each territory with")

	attack_options := pro_territory_manager_get_attack_options(self.territory_manager)
	attack_map := pro_my_move_options_get_territory_map(attack_options)
	enemy_attack_options := pro_territory_manager_get_enemy_attack_options(self.territory_manager)
	unit_attack_map := pro_my_move_options_get_unit_move_map(attack_options)

	// Assign units to territories by prioritization
	for {
		sorted_unit_attack_options := pro_combat_move_ai_try_to_attack_territories(
			self,
			prioritized_territories^,
			already_moved_units,
		)

		// Clear bombers
		for _, pt in attack_map {
			clear(&pt.bombers)
		}

		// Get all units that have already moved
		already_attacked_with_units := make(map[^Unit]struct {})
		for _, t in attack_map {
			for u in pro_territory_get_units(t) {
				already_attacked_with_units[u] = {}
			}
			for u, _ in pro_territory_get_amphib_attack_map(t) {
				already_attacked_with_units[u] = {}
			}
		}

		// Check to see if any territories can be bombed
		pro_combat_move_ai_determine_territories_that_can_be_bombed(
			self,
			attack_map,
			sorted_unit_attack_options,
			already_attacked_with_units,
		)
		delete(already_attacked_with_units)

		// Re-sort attack options
		sorted_unit_attack_options =
			pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
				self.pro_data,
				self.player,
				sorted_unit_attack_options,
				attack_map,
				self.calc,
			)
		added_units: [dynamic]^Unit
		defer delete(added_units)
		added_set := make(map[^Unit]struct {})
		defer delete(added_set)

		// Set air units in any territory with no AA
		for unit, _ in sorted_unit_attack_options {
			is_air_unit := unit_attachment_is_air(unit_get_unit_attachment(unit))
			if !is_air_unit {
				continue
			}
			min_win_territory: ^Territory = nil
			min_win_percentage := max(f64)
			for t, _ in sorted_unit_attack_options[unit] {
				patd := attack_map[t]

				// Check landing safety
				ef_p, ef_c := pro_matches_territory_has_infra_factory_and_is_enemy_land(
					self.player,
				)
				is_enemy_factory := ef_p(ef_c, t)
				if !is_enemy_factory &&
				   !pro_combat_move_ai_can_air_safely_land_after_attack(self, unit, t) {
					continue
				}
				if pro_territory_get_battle_result(patd) == nil {
					pro_territory_estimate_battle_result(patd, self.calc, self.player)
				}
				result := pro_territory_get_battle_result(patd)
				if pro_battle_result_get_win_percentage(result) < min_win_percentage ||
				   (!pro_battle_result_is_has_land_unit_remaining(result) &&
						   min_win_territory == nil) {
					attacking_units := pro_territory_get_units(patd)
					defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
					is_overwhelming_win := pro_battle_utils_check_for_overwhelming_win(
						t,
						attacking_units,
						defending_units,
					)
					aa_p, aa_c := matches_unit_is_aa_for_anything()
					has_aa := false
					for d in defending_units {
						if aa_p(aa_c, d) {
							has_aa = true
							break
						}
					}
					if !has_aa && !is_overwhelming_win {
						min_win_percentage = pro_battle_result_get_win_percentage(result)
						min_win_territory = t
					}
				}
			}
			if min_win_territory != nil {
				pro_territory_set_battle_result(attack_map[min_win_territory], nil)
				pro_territory_add_unit(attack_map[min_win_territory], unit)
				append(&added_units, unit)
				added_set[unit] = {}
			}
		}
		for u in added_units {
			delete_key(&sorted_unit_attack_options, u)
		}

		// Re-sort attack options
		sorted_unit_attack_options =
			pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
				self.pro_data,
				self.player,
				sorted_unit_attack_options,
				attack_map,
				self.calc,
			)

		// Find territory that we can try to hold that needs unit
		for unit, _ in sorted_unit_attack_options {
			if _, in_added := added_set[unit]; in_added {
				continue
			}
			min_win_territory: ^Territory = nil
			for t, _ in sorted_unit_attack_options[unit] {
				patd := attack_map[t]
				if pro_territory_is_can_hold(patd) {
					if pro_territory_get_battle_result(patd) == nil {
						pro_territory_estimate_battle_result(patd, self.calc, self.player)
					}
					result := pro_territory_get_battle_result(patd)
					attacking_units := pro_territory_get_units(patd)
					defending_units := pro_territory_get_max_enemy_defenders(patd, self.player)
					is_overwhelming_win := pro_battle_utils_check_for_overwhelming_win(
						t,
						attacking_units,
						defending_units,
					)
					if !is_overwhelming_win && pro_battle_result_get_battle_rounds(result) > 2 {
						min_win_territory = t
						break
					}
				}
			}
			if min_win_territory != nil {
				pro_territory_set_battle_result(attack_map[min_win_territory], nil)
				units_to_add := pro_transport_utils_get_units_to_add(
					self.pro_data,
					unit,
					already_moved_units,
					attack_map,
				)
				pro_territory_add_units(attack_map[min_win_territory], units_to_add)
				for u2 in units_to_add {
					append(&added_units, u2)
					added_set[u2] = {}
				}
			}
		}
		for u in added_units {
			delete_key(&sorted_unit_attack_options, u)
		}

		// Re-sort attack options
		sorted_unit_attack_options =
			pro_sort_move_options_utils_sort_unit_needed_options_then_attack(
				self.pro_data,
				self.player,
				sorted_unit_attack_options,
				attack_map,
				self.calc,
			)

		// Add sea units to any territory that significantly increases TUV gain
		for unit, _ in sorted_unit_attack_options {
			is_sea_unit := unit_attachment_is_sea(unit_get_unit_attachment(unit))
			if !is_sea_unit {
				continue
			}
			for t, _ in sorted_unit_attack_options[unit] {
				patd := attack_map[t]
				if pro_territory_get_battle_result(patd) == nil {
					pro_territory_estimate_battle_result(patd, self.calc, self.player)
				}
				result := pro_territory_get_battle_result(patd)
				attackers := make([dynamic]^Unit)
				for u in pro_territory_get_units(patd) {
					append(&attackers, u)
				}
				append(&attackers, unit)
				bombard_keys: [dynamic]^Unit
				for u, _ in pro_territory_get_bombard_territory_map(patd) {
					append(&bombard_keys, u)
				}
				result2 := pro_odds_calculator_estimate_attack_battle_results(
					self.calc,
					self.pro_data,
					t,
					attackers,
					pro_territory_get_max_enemy_defenders(patd, self.player),
					bombard_keys,
				)
				delete(attackers)
				delete(bombard_keys)
				unit_value := f64(pro_data_get_unit_value(self.pro_data, unit_get_type(unit)))
				if (pro_battle_result_get_tuv_swing(result2) - unit_value / 3.0) >
				   pro_battle_result_get_tuv_swing(result) {
					pro_territory_set_battle_result(patd, nil)
					pro_territory_add_unit(patd, unit)
					append(&added_units, unit)
					added_set[unit] = {}
					break
				}
			}
		}
		for u in added_units {
			delete_key(&sorted_unit_attack_options, u)
		}

		// Determine if all attacks are worth it
		used_units: [dynamic]^Unit
		used_set := make(map[^Unit]struct {})
		for patd in prioritized_territories^ {
			for u in pro_territory_get_units(patd) {
				append(&used_units, u)
				used_set[u] = {}
			}
		}
		territory_to_remove: ^Pro_Territory = nil
		for patd in prioritized_territories^ {
			t := pro_territory_get_territory(patd)

			// Find battle result
			if pro_territory_get_battle_result(patd) == nil {
				pro_territory_estimate_battle_result(patd, self.calc, self.player)
			}
			result := pro_territory_get_battle_result(patd)

			// Determine enemy counter-attack results
			can_hold := true
			enemy_counter_tuv_swing: f64 = 0
			water_adj_p, water_adj_c :=
				pro_matches_territory_is_water_and_adjacent_to_owned_factory(self.player)
			if pro_other_move_options_get_max(enemy_attack_options, t) != nil &&
			   !water_adj_p(water_adj_c, t) {
				air_p, air_c := matches_unit_is_air()
				remaining_units_to_defend_with: [dynamic]^Unit
				for u in pro_battle_result_get_average_attackers_remaining(result) {
					if !air_p(air_c, u) {
						append(&remaining_units_to_defend_with, u)
					}
				}
				max_bombard_set := pro_territory_get_max_bombard_units(patd)
				max_bombard_list: [dynamic]^Unit
				for u, _ in max_bombard_set {
					append(&max_bombard_list, u)
				}
				result2 := pro_odds_calculator_calculate_battle_results(
					self.calc,
					self.pro_data,
					t,
					pro_territory_get_max_enemy_units(patd),
					remaining_units_to_defend_with,
					max_bombard_list,
				)
				if pro_territory_is_can_hold(patd) &&
				   pro_battle_result_get_tuv_swing(result2) > 0 {
					unused_units_set := make(map[^Unit]struct {})
					for u, _ in pro_territory_get_max_units(patd) {
						unused_units_set[u] = {}
					}
					for u in pro_territory_get_max_amphib_units(patd) {
						unused_units_set[u] = {}
					}
					for u in used_units {
						delete_key(&unused_units_set, u)
					}
					for u in remaining_units_to_defend_with {
						unused_units_set[u] = {}
					}
					unused_units_list: [dynamic]^Unit
					for u, _ in unused_units_set {
						append(&unused_units_list, u)
					}
					delete(unused_units_set)
					result3 := pro_odds_calculator_calculate_battle_results(
						self.calc,
						self.pro_data,
						t,
						pro_territory_get_max_enemy_units(patd),
						unused_units_list,
						max_bombard_list,
					)
					if pro_battle_result_get_tuv_swing(result3) <
					   pro_battle_result_get_tuv_swing(result2) {
						result2 = result3
						delete(remaining_units_to_defend_with)
						remaining_units_to_defend_with = unused_units_list
					} else {
						delete(unused_units_list)
					}
				}
				can_hold =
					(!pro_battle_result_is_has_land_unit_remaining(result2) &&
							!territory_is_water(t)) ||
					(pro_battle_result_get_tuv_swing(result2) < 0) ||
					(pro_battle_result_get_win_percentage(result2) <
							self.pro_data.min_win_percentage)
				if pro_battle_result_get_tuv_swing(result2) > 0 {
					enemy_counter_tuv_swing = pro_battle_result_get_tuv_swing(result2)
				}
				pro_logger_trace(
					fmt.tprintf(
						"Territory=%s, CanHold=%v, MyDefenders=%d, EnemyAttackers=%d, win%%=%v, EnemyTUVSwing=%v, hasLandUnitRemaining=%v",
						territory_to_string(t),
						can_hold,
						len(remaining_units_to_defend_with),
						len(pro_territory_get_max_enemy_units(patd)),
						pro_battle_result_get_win_percentage(result2),
						pro_battle_result_get_tuv_swing(result2),
						pro_battle_result_is_has_land_unit_remaining(result2),
					),
				)
				delete(remaining_units_to_defend_with)
				delete(max_bombard_list)
			}

			// Find attack value
			is_neutral := pro_utils_is_neutral_land(t)
			is_land: i32 = 0
			if !territory_is_water(t) {
				is_land = 1
			}
			is_can_hold: i32 = 0
			if can_hold {
				is_can_hold = 1
			}
			is_cant_hold_amphib: i32 = 0
			if !can_hold && len(pro_territory_get_amphib_attack_map(patd)) > 0 {
				is_cant_hold_amphib = 1
			}
			factory_p, factory_c := pro_matches_territory_has_infra_factory_and_is_land()
			is_factory: i32 = 0
			if factory_p(factory_c, t) {
				is_factory = 1
			}
			capturable_units: i32 = 0
			tl_p, tl_c := matches_territory_is_land()
			if tl_p(tl_c, t) {
				cap_p, cap_c := matches_unit_can_be_captured_on_entering_this_territory(
					self.player,
					t,
				)
				for u in unit_collection_get_units(territory_get_unit_collection(t)) {
					if cap_p(cap_c, u) {
						capturable_units += 1
					}
				}
			}
			is_ffa: i32 = 0
			if pro_utils_is_ffa(&self.data.game_state, self.player) {
				is_ffa = 1
			}
			production := territory_attachment_static_get_production(t)
			capital_value: f64 = 0
			ta := territory_attachment_get(t)
			if ta != nil && territory_attachment_is_capital(ta) {
				capital_value = pro_utils_get_player_production(
					territory_get_owner(t),
					&self.data.game_state,
				)
			}
			territory_value :=
				(1.0 +
						f64(is_land) -
						f64(is_cant_hold_amphib) +
						f64(is_factory) +
						f64(is_can_hold) *
							(1.0 +
									2.0 * f64(is_ffa) +
									1.5 * f64(is_factory) +
									0.5 * f64(capturable_units))) *
					f64(production) +
				capital_value
			tuv_swing := pro_battle_result_get_tuv_swing(result)
			if is_ffa == 1 && tuv_swing > 0 {
				tuv_swing *= 0.5
			}
			attack_value :=
				1 +
				tuv_swing +
				territory_value * pro_battle_result_get_win_percentage(result) / 100.0 -
				enemy_counter_tuv_swing * 2.0 / 3.0
			all_units_can_attack_other_territory := true
			if is_neutral && attack_value < 0 {
				for u in pro_territory_get_units(patd) {
					can_attack_other_territory := false
					for patd2 in prioritized_territories^ {
						if patd != patd2 {
							if ts, ok := unit_attack_map[u]; ok {
								if _, in_set :=
									ts[pro_territory_get_territory(patd2)]; in_set {
									can_attack_other_territory = true
									break
								}
							}
						}
					}
					if !can_attack_other_territory {
						all_units_can_attack_other_territory = false
						break
					}
				}
			}

			// Determine whether to remove attack
			if !pro_territory_is_strafing(patd) &&
			   (pro_battle_result_get_win_percentage(result) <
					   self.pro_data.min_win_percentage ||
					   !pro_battle_result_is_has_land_unit_remaining(result) ||
					   (is_neutral && !can_hold) ||
					   (attack_value < 0 &&
							   (!is_neutral ||
									   all_units_can_attack_other_territory ||
									   pro_battle_result_get_battle_rounds(result) >= 4))) {
				territory_to_remove = patd
			}
			pro_logger_debug(
				fmt.tprintf(
					"%s, attackValue=%v, territoryValue=%v, allUnitsCanAttackOtherTerritory=%v with attackers=%v",
					pro_territory_get_result_string(patd),
					attack_value,
					territory_value,
					all_units_can_attack_other_territory,
					pro_territory_get_units(patd),
				),
			)
		}
		delete(used_units)
		delete(used_set)

		// Determine whether all attacks are successful or try to hold fewer territories
		if territory_to_remove == nil {
			break
		}
		for j := 0; j < len(prioritized_territories^); j += 1 {
			if prioritized_territories^[j] == territory_to_remove {
				ordered_remove(prioritized_territories, j)
				break
			}
		}
		pro_logger_debug(
			fmt.tprintf(
				"Removing %s",
				territory_to_string(pro_territory_get_territory(territory_to_remove)),
			),
		)
	}
}

// Java: ProCombatMoveAi#removeAttacksUntilCapitalCanBeHeld(
//     List<ProTerritory> prioritizedTerritories,
//     List<ProPurchaseOption> landPurchaseOptions)
//   While our capital cannot be held against the projected enemy
//   counter-attack, drops the prioritized attack whose committed units
//   are most concentrated near the capital.
pro_combat_move_ai_remove_attacks_until_capital_can_be_held :: proc(
	self:                    ^Pro_Combat_Move_Ai,
	prioritized_territories: ^[dynamic]^Pro_Territory,
	land_purchase_options:   [dynamic]^Pro_Purchase_Option,
) {
	pro_logger_info("Check capital defenses after attack moves")

	attack_map := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_attack_options(self.territory_manager),
	)
	my_capital := pro_data_get_my_capital(self.pro_data)

	// Add max purchase defenders to capital for non-mobile factories
	place_units: [dynamic]^Unit
	defer delete(place_units)
	nmf_p, nmf_c := pro_matches_territory_has_non_mobile_factory_and_is_not_conquered_owned_land(
		self.player,
	)
	if nmf_p(nmf_c, my_capital) {
		max_defenders := pro_purchase_utils_find_max_purchase_defenders(
			self.pro_data,
			self.player,
			my_capital,
			land_purchase_options,
		)
		for u in max_defenders {
			append(&place_units, u)
		}
		delete(max_defenders)
	}

	// Remove attack until capital can be defended
	gm := game_data_get_map(self.data)
	for {
		if len(prioritized_territories^) == 0 {
			break
		}

		// Determine max enemy counter attack units
		territories_to_attack: [dynamic]^Territory
		for t in prioritized_territories^ {
			append(&territories_to_attack, pro_territory_get_territory(t))
		}
		pro_logger_trace(
			fmt.tprintf("Remaining territories to attack=%v", territories_to_attack),
		)
		cleared_capital: [dynamic]^Territory
		append(&cleared_capital, my_capital)
		pro_territory_manager_populate_enemy_attack_options(
			self.territory_manager,
			territories_to_attack,
			cleared_capital,
		)
		delete(territories_to_attack)
		delete(cleared_capital)
		enemy_attack_options := pro_territory_manager_get_enemy_attack_options(
			self.territory_manager,
		)
		if pro_other_move_options_get_max(enemy_attack_options, my_capital) == nil {
			break
		}

		// Find max remaining defenders
		land_p, land_c := matches_territory_is_land()
		territories_adjacent_to_capital := game_map_get_neighbors_predicate(
			gm,
			my_capital,
			land_p,
			land_c,
		)
		allied_p, allied_c := matches_is_unit_allied(self.player)
		defenders: [dynamic]^Unit
		for u in unit_collection_get_units(territory_get_unit_collection(my_capital)) {
			if allied_p(allied_c, u) {
				append(&defenders, u)
			}
		}
		for u in place_units {
			append(&defenders, u)
		}
		owned_p, owned_c := pro_matches_unit_can_be_moved_and_is_owned_land(self.player, false)
		for t, _ in territories_adjacent_to_capital {
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				if owned_p(owned_c, u) {
					append(&defenders, u)
				}
			}
		}
		delete(territories_adjacent_to_capital)
		// defenders.removeAll(t.getUnits()) for every t in attackMap.values()
		used_set := make(map[^Unit]struct {})
		for _, t in attack_map {
			for u in pro_territory_get_units(t) {
				used_set[u] = {}
			}
		}
		filtered_defenders: [dynamic]^Unit
		for u in defenders {
			if _, in_used := used_set[u]; !in_used {
				append(&filtered_defenders, u)
			}
		}
		delete(defenders)
		delete(used_set)

		// Determine counter-attack results
		enemy_max := pro_other_move_options_get_max(enemy_attack_options, my_capital)
		enemy_attacking_units_set := make(map[^Unit]struct {})
		for u, _ in pro_territory_get_max_units(enemy_max) {
			enemy_attacking_units_set[u] = {}
		}
		for u in pro_territory_get_max_amphib_units(enemy_max) {
			enemy_attacking_units_set[u] = {}
		}
		enemy_attacking_units_list: [dynamic]^Unit
		for u, _ in enemy_attacking_units_set {
			append(&enemy_attacking_units_list, u)
		}
		delete(enemy_attacking_units_set)
		max_bombard_set := pro_territory_get_max_bombard_units(enemy_max)
		max_bombard_list: [dynamic]^Unit
		for u, _ in max_bombard_set {
			append(&max_bombard_list, u)
		}
		result := pro_odds_calculator_estimate_defend_battle_results(
			self.calc,
			self.pro_data,
			my_capital,
			enemy_attacking_units_list,
			filtered_defenders,
			max_bombard_list,
		)
		pro_logger_trace(
			fmt.tprintf(
				"Current capital result hasLandUnitRemaining=%v, TUVSwing=%v, defenders=%d, attackers=%d",
				pro_battle_result_is_has_land_unit_remaining(result),
				pro_battle_result_get_tuv_swing(result),
				len(filtered_defenders),
				len(enemy_attacking_units_list),
			),
		)
		delete(enemy_attacking_units_list)
		delete(max_bombard_list)
		delete(filtered_defenders)

		// Determine attack to remove
		if pro_battle_result_is_has_land_unit_remaining(result) {
			max_units_near_capital_per_value: f64 = 0
			max_territory: ^Territory = nil
			territories_near_capital := game_map_get_neighbors_predicate(
				gm,
				my_capital,
				land_p,
				land_c,
			)
			territories_near_capital[my_capital] = {}
			for t, attack_pt in attack_map {
				units_near_capital: i32 = 0
				for u in pro_territory_get_units(attack_pt) {
					ut := pro_data_get_unit_territory(self.pro_data, u)
					if _, in_set := territories_near_capital[ut]; in_set {
						units_near_capital += 1
					}
				}
				val := pro_territory_get_value(attack_map[t])
				if val == 0 {
					continue
				}
				units_near_capital_per_value := f64(units_near_capital) / val
				pro_logger_trace(
					fmt.tprintf(
						"%s has unit near capital per value: %v",
						territory_to_string(t),
						units_near_capital_per_value,
					),
				)
				if units_near_capital_per_value > max_units_near_capital_per_value {
					max_units_near_capital_per_value = units_near_capital_per_value
					max_territory = t
				}
			}
			delete(territories_near_capital)
			if max_territory != nil {
				patd_max := attack_map[max_territory]
				for j := 0; j < len(prioritized_territories^); j += 1 {
					if prioritized_territories^[j] == patd_max {
						ordered_remove(prioritized_territories, j)
						break
					}
				}
				clear(&patd_max.units)
				clear(&patd_max.amphib_attack_map)
				pro_territory_set_battle_result(patd_max, nil)
				pro_logger_debug(
					fmt.tprintf(
						"Removing territory to try to hold capital: %s",
						territory_to_string(max_territory),
					),
				)
			} else {
				break
			}
		} else {
			pro_logger_debug(
				fmt.tprintf("Can hold capital: %s", territory_to_string(my_capital)),
			)
			break
		}
	}
}

// Java: ProCombatMoveAi#doCombatMove(IMoveDelegate moveDel)
//   Drives the combat-move phase end-to-end: snapshots GameData/player,
//   builds a fresh ProTerritoryManager, evaluates whether we should be on
//   the defensive, populates attack/defense options, prioritizes and prunes
//   targets in two passes (the second pass adds water neighbors of any
//   amphib targets so transports get counter-attack coverage), assigns
//   units, calculates amphib routes for transport-territory bookkeeping,
//   removes attacks that expose transports or jeopardize the capital,
//   handles contested sea, executes the moves, records strafing
//   territories, logs the result and returns the attack map.
pro_combat_move_ai_do_combat_move :: proc(
	self: ^Pro_Combat_Move_Ai,
	move_del: ^I_Move_Delegate,
) -> map[^Territory]^Pro_Territory {
	pro_logger_info("Starting combat move phase")

	// Current data at the start of combat move
	self.data = pro_data_get_data(self.pro_data)
	self.player = pro_data_get_player(self.pro_data)
	self.territory_manager = pro_territory_manager_new(self.calc, self.pro_data)

	// Determine whether capital is threatened, and I should be in a defensive stance
	empty_purchase_territories: map[^Territory]^Pro_Purchase_Territory
	self.is_defensive = !pro_battle_utils_territory_has_local_land_superiority(
		self.pro_data,
		pro_data_get_my_capital(self.pro_data),
		3, // ProBattleUtils.MEDIUM_RANGE
		self.player,
		empty_purchase_territories,
	)
	self.is_bombing = false
	pro_logger_debug(fmt.tprintf("Currently in defensive stance: %v", self.is_defensive))

	// Find the maximum number of units that can attack each territory and max enemy defenders
	pro_territory_manager_populate_attack_options(self.territory_manager)
	pro_territory_manager_populate_enemy_defense_options(self.territory_manager)

	// Remove territories that aren't worth attacking and prioritize the remaining ones
	attack_options := pro_territory_manager_remove_territories_that_cant_be_conquered_0(
		self.territory_manager,
	)
	cleared_territories: [dynamic]^Territory
	for patd in attack_options {
		append(&cleared_territories, pro_territory_get_territory(patd))
	}
	pro_territory_manager_populate_enemy_attack_options(
		self.territory_manager,
		cleared_territories,
		cleared_territories,
	)
	pro_combat_move_ai_determine_territories_that_can_be_held(
		self,
		attack_options,
		cleared_territories,
	)
	pro_combat_move_ai_prioritize_attack_options(self, self.player, &attack_options)
	pro_combat_move_ai_remove_territories_that_arent_worth_attacking(self, &attack_options)

	// Determine which territories to attack
	pro_combat_move_ai_determine_territories_to_attack(self, &attack_options)

	// Determine which territories can be held and remove any that aren't worth attacking
	clear(&cleared_territories)
	possible_transport_territories := make(map[^Territory]struct {})
	defer delete(possible_transport_territories)
	water_p, water_c := matches_territory_is_water()
	for patd in attack_options {
		t := pro_territory_get_territory(patd)
		append(&cleared_territories, t)
		if len(pro_territory_get_amphib_attack_map(patd)) > 0 {
			neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(self.data),
				t,
				water_p,
				water_c,
			)
			for n in neighbors {
				possible_transport_territories[n] = {}
			}
			delete(neighbors)
		}
	}
	for t in cleared_territories {
		possible_transport_territories[t] = {}
	}
	possible_transport_dyn: [dynamic]^Territory
	defer delete(possible_transport_dyn)
	for t in possible_transport_territories {
		append(&possible_transport_dyn, t)
	}
	pro_territory_manager_populate_enemy_attack_options(
		self.territory_manager,
		cleared_territories,
		possible_transport_dyn,
	)
	pro_combat_move_ai_determine_territories_that_can_be_held(
		self,
		attack_options,
		cleared_territories,
	)
	pro_combat_move_ai_remove_territories_that_arent_worth_attacking(self, &attack_options)

	// Determine how many units to attack each territory with
	already_moved_units :=
		pro_combat_move_ai_move_one_defender_to_land_territories_bordering_enemy(
			self,
			attack_options,
		)
	pro_combat_move_ai_determine_units_to_attack_with(
		self,
		&attack_options,
		already_moved_units,
	)

	// Get all transport final territories (side-effects bookkeeping)
	_ = pro_move_utils_calculate_amphib_routes(
		self.pro_data,
		self.player,
		pro_my_move_options_get_territory_map(
			pro_territory_manager_get_attack_options(self.territory_manager),
		),
		true,
	)

	// Determine max enemy counter-attack units and remove territories where transports are exposed
	pro_combat_move_ai_remove_territories_where_transports_are_exposed(self)

	// Determine if capital can be held if I still own it
	my_capital := pro_data_get_my_capital(self.pro_data)
	if my_capital != nil && territory_is_owned_by(my_capital, self.player) {
		pro_combat_move_ai_remove_attacks_until_capital_can_be_held(
			self,
			&attack_options,
			pro_purchase_option_map_get_land_options(
				pro_data_get_purchase_options(self.pro_data),
			),
		)
	}

	// Check if any subs in contested territory that's not being attacked
	pro_combat_move_ai_check_contested_sea_territories(self)

	// Calculate attack routes and perform moves
	pro_combat_move_ai_do_move(
		self,
		pro_my_move_options_get_territory_map(
			pro_territory_manager_get_attack_options(self.territory_manager),
		),
		move_del,
		self.data,
		self.player,
	)

	// Set strafing territories to avoid retreats
	abstract_pro_ai_set_stored_strafing_territories(
		self.ai,
		pro_territory_manager_get_strafing_territories(self.territory_manager),
	)
	pro_logger_info(
		fmt.tprintf(
			"Strafing territories: %v",
			pro_territory_manager_get_strafing_territories(self.territory_manager),
		),
	)

	// Log results
	pro_logger_info("Logging results")
	pro_combat_move_ai_log_attack_moves(self, attack_options)

	result := pro_my_move_options_get_territory_map(
		pro_territory_manager_get_attack_options(self.territory_manager),
	)
	self.territory_manager = nil
	return result
}

