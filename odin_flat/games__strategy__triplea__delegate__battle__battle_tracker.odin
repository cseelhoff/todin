package game

Battle_Tracker :: struct {
	pending_battles:                       map[^I_Battle]struct{},
	dependencies:                          map[^I_Battle]map[^I_Battle]struct{},
	conquered:                             map[^Territory]struct{},
	blitzed:                               map[^Territory]struct{},
	fought_battles:                        map[^Territory]struct{},
	finished_battles_unit_attack_from_map: map[^Territory]map[^Territory][dynamic]^Unit,
	no_bombard_allowed:                    map[^Territory]struct{},
	defending_air_that_can_not_land:       map[^Territory][dynamic]^Unit,
	battle_records:                        ^Battle_Records,
	relationship_changes_this_turn:        [dynamic]^Tuple(rawptr, rawptr),
}

BOMBING_DEPENDENCY_ERROR :: "Bombing Raids should be dealt with first! Be sure the battle has dependencies set correctly!"

// games.strategy.triplea.delegate.battle.BattleTracker#<init>()
battle_tracker_new :: proc() -> ^Battle_Tracker {
	self := new(Battle_Tracker)
	self.pending_battles = make(map[^I_Battle]struct{})
	self.dependencies = make(map[^I_Battle]map[^I_Battle]struct{})
	self.conquered = make(map[^Territory]struct{})
	self.blitzed = make(map[^Territory]struct{})
	self.fought_battles = make(map[^Territory]struct{})
	self.finished_battles_unit_attack_from_map = make(map[^Territory]map[^Territory][dynamic]^Unit)
	self.no_bombard_allowed = make(map[^Territory]struct{})
	self.defending_air_that_can_not_land = make(map[^Territory][dynamic]^Unit)
	self.battle_records = nil
	self.relationship_changes_this_turn = make([dynamic]^Tuple(rawptr, rawptr))
	return self
}

// games.strategy.triplea.delegate.battle.BattleTracker#addToConquered(Territory)
battle_tracker_add_to_conquered :: proc(self: ^Battle_Tracker, territory: ^Territory) {
	self.conquered[territory] = {}
}

// games.strategy.triplea.delegate.battle.BattleTracker#wasConquered(Territory)
battle_tracker_was_conquered :: proc(self: ^Battle_Tracker, t: ^Territory) -> bool {
	return t in self.conquered
}

// games.strategy.triplea.delegate.battle.BattleTracker#wasBlitzed(Territory)
battle_tracker_was_blitzed :: proc(self: ^Battle_Tracker, t: ^Territory) -> bool {
	return t in self.blitzed
}

// games.strategy.triplea.delegate.battle.BattleTracker#wasBattleFought(Territory)
battle_tracker_was_battle_fought :: proc(self: ^Battle_Tracker, t: ^Territory) -> bool {
	return t in self.fought_battles
}

// games.strategy.triplea.delegate.battle.BattleTracker#noBombardAllowedFromHere(Territory)
battle_tracker_no_bombard_allowed_from_here :: proc(self: ^Battle_Tracker, t: ^Territory) -> bool {
	return t in self.no_bombard_allowed
}

// games.strategy.triplea.delegate.battle.BattleTracker#addNoBombardAllowedFromHere(Territory)
battle_tracker_add_no_bombard_allowed_from_here :: proc(self: ^Battle_Tracker, t: ^Territory) {
	self.no_bombard_allowed[t] = {}
}

// games.strategy.triplea.delegate.battle.BattleTracker#getConquered()
battle_tracker_get_conquered :: proc(self: ^Battle_Tracker) -> map[^Territory]struct{} {
	return self.conquered
}

// games.strategy.triplea.delegate.battle.BattleTracker#getDefendingAirThatCanNotLand()
battle_tracker_get_defending_air_that_can_not_land :: proc(self: ^Battle_Tracker) -> map[^Territory][dynamic]^Unit {
	return self.defending_air_that_can_not_land
}

// games.strategy.triplea.delegate.battle.BattleTracker#getFinishedBattlesUnitAttackFromMap()
battle_tracker_get_finished_battles_unit_attack_from_map :: proc(self: ^Battle_Tracker) -> map[^Territory]map[^Territory][dynamic]^Unit {
	return self.finished_battles_unit_attack_from_map
}

// games.strategy.triplea.delegate.battle.BattleTracker#addDependency(IBattle, IBattle)
// Java: dependencies.computeIfAbsent(blocked, k -> new HashSet<>()).add(blocking);
battle_tracker_add_dependency :: proc(self: ^Battle_Tracker, blocked: ^I_Battle, blocking: ^I_Battle) {
	if blocked not_in self.dependencies {
		self.dependencies[blocked] = battle_tracker_lambda_add_dependency_13(blocked)
	}
	inner := self.dependencies[blocked]
	inner[blocking] = {}
	self.dependencies[blocked] = inner
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$addDependency$13(IBattle)
// Body of `k -> new HashSet<>()` from addDependency.computeIfAbsent. No captures.
battle_tracker_lambda_add_dependency_13 :: proc(k: ^I_Battle) -> map[^I_Battle]struct{} {
	return make(map[^I_Battle]struct{})
}

// games.strategy.triplea.delegate.battle.BattleTracker#removeDependency(IBattle, IBattle)
battle_tracker_remove_dependency :: proc(self: ^Battle_Tracker, blocked: ^I_Battle, blocking: ^I_Battle) {
	dependencies_of_blocked := self.dependencies[blocked]
	delete_key(&dependencies_of_blocked, blocking)
	if len(dependencies_of_blocked) == 0 {
		delete_key(&self.dependencies, blocked)
	} else {
		self.dependencies[blocked] = dependencies_of_blocked
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#clear()
battle_tracker_clear :: proc(self: ^Battle_Tracker) {
	clear(&self.finished_battles_unit_attack_from_map)
	clear(&self.pending_battles)
	clear(&self.blitzed)
	clear(&self.fought_battles)
	clear(&self.conquered)
	clear(&self.dependencies)
	clear(&self.defending_air_that_can_not_land)
	clear(&self.no_bombard_allowed)
	clear(&self.relationship_changes_this_turn)
}

// games.strategy.triplea.delegate.battle.BattleTracker#addToDefendingAirThatCanNotLand(Collection, Territory)
battle_tracker_add_to_defending_air_that_can_not_land :: proc(self: ^Battle_Tracker, units: [dynamic]^Unit, sz_territory_they_are_in: ^Territory) {
	current, exists := self.defending_air_that_can_not_land[sz_territory_they_are_in]
	if !exists {
		current = make([dynamic]^Unit)
	}
	for u in units {
		append(&current, u)
	}
	self.defending_air_that_can_not_land[sz_territory_they_are_in] = current
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$takeOver$1(TerritoryAttachment$CaptureOwnershipChange)
// Body of `co -> !co.capturingPlayer.equals(co.receivingPlayer)`. No captures.
battle_tracker_lambda_take_over_1 :: proc(capture_ownership_change: ^Territory_Attachment_Capture_Ownership_Change) -> bool {
	return capture_ownership_change.capturing_player != capture_ownership_change.receiving_player
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$takeOver$2(GamePlayer, TerritoryAttachment$CaptureOwnershipChange)
// Body of `co -> co.capturingPlayer.equals(gamePlayer)`. Captures gamePlayer (passed as first arg).
battle_tracker_lambda_take_over_2 :: proc(game_player: ^Game_Player, capture_ownership_change: ^Territory_Attachment_Capture_Ownership_Change) -> bool {
	return capture_ownership_change.capturing_player == game_player
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$takeOver$3(TerritoryAttachment$CaptureOwnershipChange)
// Body of `co -> co.receivingPlayer` (mapper). No captures.
battle_tracker_lambda_take_over_3 :: proc(capture_ownership_change: ^Territory_Attachment_Capture_Ownership_Change) -> ^Game_Player {
	return capture_ownership_change.receiving_player
}

// games.strategy.triplea.delegate.battle.BattleTracker#getBlocked(IBattle)
// Java: dependencies.keySet().stream()
//         .filter(current -> getDependentOn(current).contains(blocking))
//         .collect(Collectors.toList());
// getDependentOn filters dependencies[current] by !battleIsEmpty, so the
// `blocking` battle must be present in dependencies[current] AND non-empty.
battle_tracker_get_blocked :: proc(self: ^Battle_Tracker, blocking: ^I_Battle) -> map[^I_Battle]struct{} {
	result := make(map[^I_Battle]struct{})
	if i_battle_is_empty(blocking) {
		return result
	}
	for current, deps in self.dependencies {
		if blocking in deps {
			result[current] = {}
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattle(Territory, IBattle$BattleType)
battle_tracker_get_pending_battle :: proc(self: ^Battle_Tracker, t: ^Territory, type: I_Battle_Battle_Type) -> ^I_Battle {
	for b, _ in self.pending_battles {
		if i_battle_get_battle_type(b) == type && i_battle_get_territory(b) == t {
			return b
		}
	}
	return nil
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattle(UUID)
// Java treats a null UUID as "no match"; in Odin Uuid is [16]u8, so we
// just compare value-for-value (the zero Uuid will simply not match any
// battle's id under the AI snapshot harness, which assigns real ids).
battle_tracker_get_pending_battle_by_id :: proc(self: ^Battle_Tracker, id: Uuid) -> ^I_Battle {
	for b, _ in self.pending_battles {
		if i_battle_get_battle_id(b) == id {
			return b
		}
	}
	return nil
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattleSites(boolean)
// Java: pendingBattles.stream()
//         .filter(b -> !b.isEmpty() && b.getBattleType().isBombingRun() == bombing)
//         .map(IBattle::getTerritory)
//         .collect(Collectors.toSet());
// BattleType.isBombingRun() is true for AIR_RAID and BOMBING_RAID only.
battle_tracker_get_pending_battle_sites :: proc(self: ^Battle_Tracker, bombing: bool) -> map[^Territory]struct{} {
	result := make(map[^Territory]struct{})
	for b, _ in self.pending_battles {
		if i_battle_is_empty(b) {
			continue
		}
		bt := i_battle_get_battle_type(b)
		is_bombing_run := bt == .AIR_RAID || bt == .BOMBING_RAID
		if is_bombing_run == bombing {
			result[i_battle_get_territory(b)] = {}
		}
	}
	return result
}

