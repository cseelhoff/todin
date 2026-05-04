package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.NonFightingBattle

Non_Fighting_Battle :: struct {
	using dependent_battle: Dependent_Battle,
}

// NonFightingBattle(Territory, GamePlayer, BattleTracker, GameData)
//   super(battleSite, attacker, battleTracker, data);
non_fighting_battle_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	data: ^Game_Data,
) -> ^Non_Fighting_Battle {
	base := dependent_battle_new(battle_site, attacker, battle_tracker, data)
	self := new(Non_Fighting_Battle)
	self.dependent_battle = base^
	free(base)
	return self
}

// games.strategy.triplea.delegate.battle.NonFightingBattle#lambda$addAttackChange$0(Territory)
//   `attackingFromMap.computeIfAbsent(attackingFrom, k -> new ArrayList<>())`.
non_fighting_battle_lambda_add_attack_change_0 :: proc(k: ^Territory) -> [dynamic]^Unit {
	_ = k
	return make([dynamic]^Unit)
}

// games.strategy.triplea.delegate.battle.NonFightingBattle#addAttackChange(Route, Collection<Unit>, Map<Unit,Set<Unit>>)
//
//   final Territory attackingFrom = route.getTerritoryBeforeEnd();
//   attackingUnits.addAll(units);
//   attackingFromMap.computeIfAbsent(attackingFrom, k -> new ArrayList<>()).addAll(units);
//   if (route.getStart().isWater()
//       && !route.getEnd().isWater()
//       && units.stream().anyMatch(Matches.unitIsLand())) {
//     getAmphibiousAttackTerritories().add(route.getTerritoryBeforeEnd());
//     isAmphibious = true;
//   }
//   return ChangeFactory.EMPTY_CHANGE;
//
// The `targets` parameter is required by the IBattle override
// signature but is unused in NonFightingBattle's implementation.
non_fighting_battle_add_attack_change :: proc(
	self: ^Non_Fighting_Battle,
	route: ^Route,
	units: [dynamic]^Unit,
	targets: map[^Unit]map[^Unit]struct{},
) -> ^Change {
	_ = targets
	attacking_from := route_get_territory_before_end(route)
	for u in units {
		append(&self.attacking_units, u)
	}
	bucket, has_bucket := self.attacking_from_map[attacking_from]
	if !has_bucket {
		bucket = non_fighting_battle_lambda_add_attack_change_0(attacking_from)
	}
	for u in units {
		append(&bucket, u)
	}
	self.attacking_from_map[attacking_from] = bucket
	if territory_is_water(route_get_start(route)) && !territory_is_water(route_get_end(route)) {
		land_pred, land_ctx := matches_unit_is_land()
		any_land := false
		for u in units {
			if land_pred(land_ctx, u) {
				any_land = true
				break
			}
		}
		if any_land {
			append(&self.amphibious_attack_from, route_get_territory_before_end(route))
			self.is_amphibious = true
		}
	}
	empty := change_factory_1_new()
	return &empty.change
}
