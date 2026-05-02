package game

Finished_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	amphibious_attack_from: [dynamic]^Territory,
	attacking_from_map: map[^Territory][dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.FinishedBattle

finished_battle_get_attacking_from_map :: proc(self: ^Finished_Battle) -> map[^Territory][dynamic]^Unit {
	return self.attacking_from_map
}

finished_battle_is_empty :: proc(self: ^Finished_Battle) -> bool {
	return len(self.attacking_units) == 0
}

finished_battle_lambda_add_attack_change_0 :: proc(k: ^Territory) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// games.strategy.triplea.delegate.battle.FinishedBattle#addAttackChange
//
//   final Territory attackingFrom = route.getTerritoryBeforeEnd();
//   attackingUnits.addAll(units);
//   final Collection<Unit> attackingFromMapUnits =
//       attackingFromMap.computeIfAbsent(attackingFrom, k -> new ArrayList<>());
//   attackingFromMapUnits.addAll(units);
//   if (route.getStart().isWater()
//       && !route.getEnd().isWater()
//       && units.stream().anyMatch(Matches.unitIsLand())) {
//     amphibiousAttackFrom.add(route.getTerritoryBeforeEnd());
//     isAmphibious = true;
//   }
//   return ChangeFactory.EMPTY_CHANGE;
finished_battle_add_attack_change :: proc(
	self: ^Finished_Battle,
	route: ^Route,
	units: [dynamic]^Unit,
	targets: ^map[^Unit]map[^Unit]struct{},
) -> ^Change {
	_ = targets
	attacking_from := route_get_territory_before_end(route)
	for u in units {
		append(&self.attacking_units, u)
	}
	bucket, has_bucket := self.attacking_from_map[attacking_from]
	if !has_bucket {
		bucket = finished_battle_lambda_add_attack_change_0(attacking_from)
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

