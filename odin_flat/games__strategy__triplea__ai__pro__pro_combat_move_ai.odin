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

