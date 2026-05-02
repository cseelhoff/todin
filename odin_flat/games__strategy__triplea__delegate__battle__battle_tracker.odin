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

// games.strategy.triplea.delegate.battle.BattleTracker#addChange(IDelegateBridge, UndoableMove, Change)
// Java: bridge.addChange(change); if (changeTracker != null) changeTracker.addChange(change);
// AbstractUndoableMove.addChange(Change c) appends to its embedded CompositeChange.
battle_tracker_add_change :: proc(bridge: ^I_Delegate_Bridge, change_tracker: ^Undoable_Move, change: ^Change) {
	i_delegate_bridge_add_change(bridge, change)
	if change_tracker != nil {
		composite_change_add(change_tracker.change, change)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#clearBattleRecords()
battle_tracker_clear_battle_records :: proc(self: ^Battle_Tracker) {
	if self.battle_records != nil {
		battle_records_clear(self.battle_records)
		self.battle_records = nil
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#didThesePlayersJustGoToWarThisTurn(GamePlayer, GamePlayer)
// Iterates relationship_changes_this_turn looking for a change involving p1 and p2
// where the old relationship was not war and the new one is.
battle_tracker_did_these_players_just_go_to_war_this_turn :: proc(self: ^Battle_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_at_war()
	for tuple in self.relationship_changes_this_turn {
		players := cast(^Tuple(^Game_Player, ^Game_Player))tuple_get_first(tuple)
		first := tuple_get_first(players)
		second := tuple_get_second(players)
		if first == p1 {
			if second != p2 {
				continue
			}
		} else if second == p1 {
			if first != p2 {
				continue
			}
		} else {
			continue
		}
		relations := cast(^Tuple(^Relationship_Type, ^Relationship_Type))tuple_get_second(tuple)
		old_rel := tuple_get_first(relations)
		new_rel := tuple_get_second(relations)
		if !pred(ctx, old_rel) && pred(ctx, new_rel) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.BattleTracker#fightAirRaidsAndStrategicBombing(IDelegateBridge, Supplier, BiFunction)
// Two waves: first AIR_RAID battles, then BOMBING_RAID. The supplier is called twice
// because finishing an air raid can spawn new bombing raids.
battle_tracker_fight_air_raids_and_strategic_bombing :: proc(
	self: ^Battle_Tracker,
	delegate_bridge: ^I_Delegate_Bridge,
	pending_battle_site_supplier: proc(rawptr) -> map[^Territory]struct{},
	pending_battle_site_supplier_ctx: rawptr,
	pending_battle_function: proc(rawptr, ^Territory, I_Battle_Battle_Type) -> ^I_Battle,
	pending_battle_function_ctx: rawptr,
) {
	sites_air := pending_battle_site_supplier(pending_battle_site_supplier_ctx)
	for t, _ in sites_air {
		air_raid := pending_battle_function(pending_battle_function_ctx, t, .AIR_RAID)
		if air_raid != nil {
			i_battle_fight(air_raid, delegate_bridge)
		}
	}
	sites_sbr := pending_battle_site_supplier(pending_battle_site_supplier_ctx)
	for t, _ in sites_sbr {
		bombing_raid := pending_battle_function(pending_battle_function_ctx, t, .BOMBING_RAID)
		if bombing_raid != nil {
			i_battle_fight(bombing_raid, delegate_bridge)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#fixUpNullPlayers(GamePlayer)
battle_tracker_fix_up_null_players :: proc(self: ^Battle_Tracker, null_player: ^Game_Player) {
	for b, _ in self.pending_battles {
		i_battle_fix_up_null_player(b, null_player)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#getBattleListingFromPendingBattles()
battle_tracker_get_battle_listing_from_pending_battles :: proc(self: ^Battle_Tracker) -> ^Battle_Listing {
	return battle_listing_new(self.pending_battles)
}

// games.strategy.triplea.delegate.battle.BattleTracker#getBattleRecords()
// Lazy-init: returns a non-null BattleRecords, creating one on first call.
battle_tracker_get_battle_records :: proc(self: ^Battle_Tracker) -> ^Battle_Records {
	if self.battle_records == nil {
		self.battle_records = battle_records_new()
	}
	return self.battle_records
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattleSitesWithBombing()
battle_tracker_get_pending_battle_sites_with_bombing :: proc(self: ^Battle_Tracker) -> map[^Territory]struct{} {
	return battle_tracker_get_pending_battle_sites(self, true)
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattleSitesWithoutBombing()
battle_tracker_get_pending_battle_sites_without_bombing :: proc(self: ^Battle_Tracker) -> map[^Territory]struct{} {
	return battle_tracker_get_pending_battle_sites(self, false)
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$fightDefenselessBattles$15(IDelegateBridge, IBattle)
// Body of `battle -> battle.fight(bridge)` from fightDefenselessBattles. Captures bridge.
battle_tracker_lambda_fight_defenseless_battles_15 :: proc(bridge: ^I_Delegate_Bridge, battle: ^I_Battle) {
	i_battle_fight(battle, bridge)
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBattle$10(UUID, IBattle)
// Body of `b -> b.getBattleId().equals(uuid)` from getPendingBattle(UUID). Captures uuid.
battle_tracker_lambda_get_pending_battle_10 :: proc(uuid: Uuid, b: ^I_Battle) -> bool {
	return i_battle_get_battle_id(b) == uuid
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBattle$9(IBattle$BattleType, Territory, IBattle)
// Body of `b -> b.getBattleType().equals(type) && b.getTerritory().equals(t)` from getPendingBattle(Territory,BattleType).
battle_tracker_lambda_get_pending_battle_9 :: proc(type: I_Battle_Battle_Type, t: ^Territory, b: ^I_Battle) -> bool {
	return i_battle_get_battle_type(b) == type && i_battle_get_territory(b) == t
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBattleSites$11(boolean, IBattle)
// Body of `b -> !b.isEmpty() && b.getBattleType().isBombingRun() == bombing`.
battle_tracker_lambda_get_pending_battle_sites_11 :: proc(bombing: bool, b: ^I_Battle) -> bool {
	if i_battle_is_empty(b) {
		return false
	}
	return i_battle_battle_type_is_bombing_run(i_battle_get_battle_type(b)) == bombing
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBattles$6(IBattle$BattleType, IBattle)
// Body of `b -> !b.isEmpty() && b.getBattleType() == type`. Captures type.
battle_tracker_lambda_get_pending_battles_6 :: proc(type: I_Battle_Battle_Type, b: ^I_Battle) -> bool {
	return !i_battle_is_empty(b) && i_battle_get_battle_type(b) == type
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBattles$7(Territory, IBattle)
// Body of `b -> b.getTerritory().equals(t)`. Captures t.
battle_tracker_lambda_get_pending_battles_7 :: proc(t: ^Territory, b: ^I_Battle) -> bool {
	return i_battle_get_territory(b) == t
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingBombingBattle$5(Territory, IBattle$BattleType)
// Body of `type -> getPendingBattle(t, type)` mapper from getPendingBombingBattle.
// Captures `this` (self) and `t`.
battle_tracker_lambda_get_pending_bombing_battle_5 :: proc(self: ^Battle_Tracker, t: ^Territory, type: I_Battle_Battle_Type) -> ^I_Battle {
	return battle_tracker_get_pending_battle(self, t, type)
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getPendingNonBombingBattle$8(Territory, IBattle$BattleType)
// Body of `type -> getPendingBattle(t, type)` mapper from getPendingNonBombingBattle.
// Captures `this` (self) and `t`.
battle_tracker_lambda_get_pending_non_bombing_battle_8 :: proc(self: ^Battle_Tracker, t: ^Territory, type: I_Battle_Battle_Type) -> ^I_Battle {
	return battle_tracker_get_pending_battle(self, t, type)
}

// games.strategy.triplea.delegate.battle.BattleTracker#addRelationshipChangesThisTurn(GamePlayer, GamePlayer, RelationshipType, RelationshipType)
// Java: relationshipChangesThisTurn.add(Tuple.of(Tuple.of(p1, p2), Tuple.of(oldRelation, newRelation)));
// Stored as ^Tuple(rawptr, rawptr); inner tuples are typed Tuples cast through rawptr.
battle_tracker_add_relationship_changes_this_turn :: proc(
	self: ^Battle_Tracker,
	p1: ^Game_Player,
	p2: ^Game_Player,
	old_relation: ^Relationship_Type,
	new_relation: ^Relationship_Type,
) {
	players := tuple_new(^Game_Player, ^Game_Player, p1, p2)
	relations := tuple_new(^Relationship_Type, ^Relationship_Type, old_relation, new_relation)
	append(&self.relationship_changes_this_turn, tuple_of(rawptr(players), rawptr(relations)))
}

// games.strategy.triplea.delegate.battle.BattleTracker#didAllThesePlayersJustGoToWarThisTurn(GamePlayer, Collection)
// Java: collect distinct owners of enemy_units that are enemies of p1, then check each
// went to war this turn against p1.
battle_tracker_did_all_these_players_just_go_to_war_this_turn :: proc(
	self: ^Battle_Tracker,
	p1: ^Game_Player,
	enemy_units: [dynamic]^Unit,
) -> bool {
	enemies := make(map[^Game_Player]struct{})
	defer delete(enemies)
	pred, ctx := matches_unit_is_enemy_of(p1)
	for u in enemy_units {
		if pred(ctx, u) {
			enemies[unit_get_owner(u)] = {}
		}
	}
	for e, _ in enemies {
		if !battle_tracker_did_these_players_just_go_to_war_this_turn(self, p1, e) {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.battle.BattleTracker#fightAirRaidsAndStrategicBombing(IDelegateBridge)
// One-arg version: delegates to the (Supplier, BiFunction) form using
// this::getPendingBattleSitesWithBombing and this::getPendingBattle. Inlined here
// rather than wiring rawptr ctx adapters.
battle_tracker_fight_air_raids_and_strategic_bombing_simple :: proc(self: ^Battle_Tracker, delegate_bridge: ^I_Delegate_Bridge) {
	sites_air := battle_tracker_get_pending_battle_sites_with_bombing(self)
	for t, _ in sites_air {
		air_raid := battle_tracker_get_pending_battle(self, t, .AIR_RAID)
		if air_raid != nil {
			i_battle_fight(air_raid, delegate_bridge)
		}
	}
	sites_sbr := battle_tracker_get_pending_battle_sites_with_bombing(self)
	for t, _ in sites_sbr {
		bombing_raid := battle_tracker_get_pending_battle(self, t, .BOMBING_RAID)
		if bombing_raid != nil {
			i_battle_fight(bombing_raid, delegate_bridge)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#getDependentAmphibiousAssault(Route)
// Java: if (!route.isUnload()) return null; return getPendingBattle(route.getStart(), NORMAL);
battle_tracker_get_dependent_amphibious_assault :: proc(self: ^Battle_Tracker, route: ^Route) -> ^I_Battle {
	if !route_is_unload(route) {
		return nil
	}
	return battle_tracker_get_pending_battle(self, route_get_start(route), .NORMAL)
}

// games.strategy.triplea.delegate.battle.BattleTracker#getDependentOn(IBattle)
// Java: dependencies.get(blocked) filtered by !battleIsEmpty; absent key → empty.
battle_tracker_get_dependent_on :: proc(self: ^Battle_Tracker, blocked: ^I_Battle) -> map[^I_Battle]struct{} {
	result := make(map[^I_Battle]struct{})
	deps, ok := self.dependencies[blocked]
	if !ok {
		return result
	}
	for d, _ in deps {
		if !i_battle_is_empty(d) {
			result[d] = {}
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattles(Territory)
// Java: CollectionUtils.getMatches(pendingBattles, b -> b.getTerritory().equals(t)).
battle_tracker_get_pending_battles_at_territory :: proc(self: ^Battle_Tracker, t: ^Territory) -> [dynamic]^I_Battle {
	result := make([dynamic]^I_Battle)
	for b, _ in self.pending_battles {
		if i_battle_get_territory(b) == t {
			append(&result, b)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBattles(IBattle$BattleType)
// Java: CollectionUtils.getMatches(pendingBattles, b -> !b.isEmpty() && b.getBattleType() == type).
battle_tracker_get_pending_battles_of_type :: proc(self: ^Battle_Tracker, type: I_Battle_Battle_Type) -> [dynamic]^I_Battle {
	result := make([dynamic]^I_Battle)
	for b, _ in self.pending_battles {
		if !i_battle_is_empty(b) && i_battle_get_battle_type(b) == type {
			append(&result, b)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingBombingBattle(Territory)
// Java: BattleType.bombingBattleTypes().stream().map(t -> getPendingBattle(t, type))
//         .filter(Objects::nonNull).findAny().orElse(null);
battle_tracker_get_pending_bombing_battle :: proc(self: ^Battle_Tracker, t: ^Territory) -> ^I_Battle {
	types := i_battle_battle_type_bombing_battle_types()
	defer delete(types)
	for bt in types {
		b := battle_tracker_get_pending_battle(self, t, bt)
		if b != nil {
			return b
		}
	}
	return nil
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPendingNonBombingBattle(Territory)
// Java: BattleType.nonBombingBattleTypes().stream().map(t -> getPendingBattle(t, type))
//         .filter(Objects::nonNull).findAny().orElse(null);
battle_tracker_get_pending_non_bombing_battle :: proc(self: ^Battle_Tracker, t: ^Territory) -> ^I_Battle {
	types := i_battle_battle_type_non_bombing_battle_types()
	defer delete(types)
	for bt in types {
		b := battle_tracker_get_pending_battle(self, t, bt)
		if b != nil {
			return b
		}
	}
	return nil
}

