package game

Finished_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	amphibious_attack_from: [dynamic]^Territory,
	attacking_from_map: map[^Territory][dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.FinishedBattle

// games.strategy.triplea.delegate.battle.FinishedBattle#<init>(
//     Territory, GamePlayer, BattleTracker, BattleType, GameData,
//     BattleResultDescription, WhoWon)
//
//   super(battleSite, attacker, battleTracker, battleType, data);
//   this.battleResultDescription = battleResultDescription;
//   this.whoWon = whoWon;
//
// Sets the is_finished_battle discriminator on Abstract_Battle so
// BattleTracker#clearFinishedBattles (and other callers that Java
// expressed via `FinishedBattle.class.equals(b.getClass())`) can
// distinguish a FinishedBattle from MustFightBattle / NonFightingBattle
// (all three share I_Battle_Battle_Type.NORMAL).
finished_battle_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	battle_type: I_Battle_Battle_Type,
	data: ^Game_Data,
	battle_result_description: Battle_Record_Battle_Result_Description,
	who_won: I_Battle_Who_Won,
) -> ^Finished_Battle {
	self := new(Finished_Battle)
	self.battle_site = battle_site
	self.attacker = attacker
	self.battle_tracker = battle_tracker
	self.battle_type = battle_type
	self.game_data = data
	self.battle_result_description = battle_result_description
	self.who_won = who_won
	self.is_finished_battle = true
	return self
}

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

// games.strategy.triplea.delegate.battle.FinishedBattle#fight
//
//   isOver = true;
//   battleTracker.removeBattle(this, bridge.getData());
//   if (headless) {
//     return;
//   }
//   clearTransportedBy(bridge);
//   battleTracker
//       .getBattleRecords()
//       .addResultToBattle(
//           attacker,
//           battleId,
//           defender,
//           attackerLostTuv,
//           defenderLostTuv,
//           battleResultDescription,
//           new BattleResults(this, gameData));
finished_battle_fight :: proc(self: ^Finished_Battle, bridge: ^I_Delegate_Bridge) {
	self.is_over = true
	battle_tracker_remove_battle(
		self.battle_tracker,
		cast(^I_Battle)&self.abstract_battle,
		i_delegate_bridge_get_data(bridge),
	)
	if self.headless {
		return
	}
	abstract_battle_clear_transported_by(&self.abstract_battle, bridge)
	battle_records_add_result_to_battle(
		battle_tracker_get_battle_records(self.battle_tracker),
		self.attacker,
		self.battle_id,
		self.defender,
		self.attacker_lost_tuv,
		self.defender_lost_tuv,
		self.battle_result_description,
		battle_results_new(cast(^I_Battle)&self.abstract_battle, self.game_data),
	)
}

