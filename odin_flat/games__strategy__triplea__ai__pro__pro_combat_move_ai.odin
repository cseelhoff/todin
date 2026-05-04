package game

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

