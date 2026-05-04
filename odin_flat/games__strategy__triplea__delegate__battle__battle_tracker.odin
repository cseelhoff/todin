package game

import "core:fmt"
import "core:strings"

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

// games.strategy.triplea.delegate.battle.BattleTracker#hasPendingNonBombingBattle(Territory)
battle_tracker_has_pending_non_bombing_battle :: proc(self: ^Battle_Tracker, t: ^Territory) -> bool {
	return battle_tracker_get_pending_non_bombing_battle(self, t) != nil
}

// games.strategy.triplea.delegate.battle.BattleTracker#removeBattle(IBattle, GameData)
// Java: remove battle from pending list, dependencies, mark its territory as fought,
// and clear the battle on BattleDelegate. The Java try/catch IllegalStateException
// (no battle delegate) maps to a nil-check here.
battle_tracker_remove_battle :: proc(self: ^Battle_Tracker, battle: ^I_Battle, data: ^Game_Data) {
	if battle == nil {
		return
	}
	blocked := battle_tracker_get_blocked(self, battle)
	defer delete(blocked)
	for current, _ in blocked {
		battle_tracker_remove_dependency(self, current, battle)
	}
	delete_key(&self.pending_battles, battle)
	self.fought_battles[i_battle_get_territory(battle)] = {}
	bd := game_data_get_battle_delegate(data)
	if bd != nil {
		battle_delegate_clear_current_battle(bd, battle)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#getPossibleDefendingUnits(Territory, Collection)
// Java: CollectionUtils.getMatches(defenders, Matches.unitCanBeInBattle(false, !territory.isWater(), 1, true)).
battle_tracker_get_possible_defending_units :: proc(territory: ^Territory, defenders: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	p, c := matches_unit_can_be_in_battle_no_firing_units(false, !territory_is_water(territory), 1, true)
	for u in defenders {
		if p(c, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.BattleTracker#fightBattleIfOnlyOne(IDelegateBridge)
// Java: if there's exactly one pending NORMAL battle with no dependencies, fight it.
battle_tracker_fight_battle_if_only_one :: proc(self: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	battles := battle_tracker_get_pending_battles_of_type(self, .NORMAL)
	defer delete(battles)
	if len(battles) == 1 {
		battle := battles[0]
		deps := battle_tracker_get_dependent_on(self, battle)
		defer delete(deps)
		if len(deps) == 0 {
			i_battle_fight(battle, bridge)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$fightDefenselessBattles$14(IBattle)
// Body of `battle -> getDependentOn(battle).isEmpty()`. Captures `this` (self).
battle_tracker_lambda_fight_defenseless_battles_14 :: proc(self: ^Battle_Tracker, battle: ^I_Battle) -> bool {
	deps := battle_tracker_get_dependent_on(self, battle)
	defer delete(deps)
	return len(deps) == 0
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$getBlocked$12(IBattle, IBattle)
// Body of `current -> getDependentOn(current).contains(blocking)`. Captures `this` (self) and `blocking`.
battle_tracker_lambda_get_blocked_12 :: proc(self: ^Battle_Tracker, blocking: ^I_Battle, current: ^I_Battle) -> bool {
	deps := battle_tracker_get_dependent_on(self, current)
	defer delete(deps)
	_, ok := deps[blocking]
	return ok
}

// games.strategy.triplea.delegate.battle.BattleTracker#addChangeChangeOwnership(Territory, GamePlayer, TerritoryAttachment, GamePlayer, IDelegateBridge, UndoableMove, Collection<Unit>)
// Java: build an OwnerChange, log it, apply it, mark the territory as conquered on
// the undoable move (if present), and play the appropriate capture sound.
battle_tracker_add_change_change_ownership :: proc(
	self: ^Battle_Tracker,
	territory: ^Territory,
	new_owner: ^Game_Player,
	territory_attachment: ^Territory_Attachment,
	game_player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
	arrived_units: [dynamic]^Unit,
) {
	oc := owner_change_new(territory, new_owner)
	take_over := &oc.change
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	history_writer_add_child_to_event(history_writer, owner_change_to_string(oc))
	battle_tracker_add_change(bridge, change_tracker, take_over)
	territory_notify_changed(territory)
	if change_tracker != nil {
		undoable_move_add_to_conquered(change_tracker, territory)
	}
	broadcaster := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	if territory_is_water(territory) {
		headless_sound_channel_play_sound_for_all(broadcaster, "territory_capture_sea", game_player)
	} else if territory_attachment_get_capital(territory_attachment) != "" {
		headless_sound_channel_play_sound_for_all(broadcaster, "territory_capture_capital", game_player)
	} else {
		is_blitz := false
		if _, in_blitzed := self.blitzed[territory]; in_blitzed {
			p, c := matches_unit_can_blitz()
			for u in arrived_units {
				if p(c, u) {
					is_blitz = true
					break
				}
			}
		}
		if is_blitz {
			headless_sound_channel_play_sound_for_all(broadcaster, "territory_capture_blitz", game_player)
		} else {
			headless_sound_channel_play_sound_for_all(broadcaster, "territory_capture_land", game_player)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#addChangeChargeForEnteringNeutrals(Territory, GamePlayer, IDelegateBridge, UndoableMove)
// Java: charge gamePlayer the (positive) neutralCharge property in PUs (clamped
// at -player.PUs so we cannot dip below zero). Logs an error if we could not
// charge the full ideal amount; in either case writes a history child entry.
battle_tracker_add_change_charge_for_entering_neutrals :: proc(
	territory: ^Territory,
	game_player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
) {
	data := i_delegate_bridge_get_data(bridge)
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
	pu_charge_ideal := -properties_get_neutral_charge(game_data_get_properties(data))
	have_neg := -resource_collection_get_quantity(game_player_get_resources(game_player), pus)
	pu_charge_real := min(i32(0), max(pu_charge_ideal, have_neg))
	neutral_fee := change_factory_change_resources_change(game_player, pus, pu_charge_real)
	battle_tracker_add_change(bridge, change_tracker, neutral_fee)
	if pu_charge_ideal == pu_charge_real {
		msg := fmt.aprintf(
			"%s loses %d %s for violating %ss neutrality.",
			game_player.name,
			-pu_charge_real,
			my_formatter_pluralize_quantity("PU", -pu_charge_real),
			territory.name,
		)
		history_writer_add_child_to_event(history_writer, msg)
	} else {
		fmt.eprintln(
			"Player,",
			game_player.name,
			"attacks a Neutral territory, and should have had to pay",
			pu_charge_ideal,
			", but did not have enough PUs to pay! This is a bug.",
		)
		msg := fmt.aprintf(
			"%s loses %d %s for violating %ss neutrality.  Correct amount to charge is: %d.  Player should not have been able to make this attack!",
			game_player.name,
			-pu_charge_real,
			my_formatter_pluralize_quantity("PU", -pu_charge_real),
			territory.name,
			pu_charge_ideal,
		)
		history_writer_add_child_to_event(history_writer, msg)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#getAllAttachingSeaUnits(Collection<Unit>, GameData)
// Java: total = arrived - land - air - submerged
//       - (transports that cannot control sea zones, if property disabled)
//       - (subs that can be moved through by enemies, if property enabled).
battle_tracker_get_all_attaching_sea_units :: proc(arrived_units: [dynamic]^Unit, data: ^Game_Data) -> i32 {
	total := i32(len(arrived_units))
	lp, lc := matches_unit_is_land()
	ap, ac := matches_unit_is_air()
	sp, sc := matches_unit_is_submerged()
	for u in arrived_units {
		if lp(lc, u) { total -= 1 }
	}
	for u in arrived_units {
		if ap(ac, u) { total -= 1 }
	}
	for u in arrived_units {
		if sp(sc, u) { total -= 1 }
	}
	props := game_data_get_properties(data)
	if !properties_get_transport_control_sea_zone(props) {
		t1p, t1c := matches_unit_is_sea_transport_and_not_destroyer()
		t2p, t2c := matches_unit_is_sea_transport_but_not_combat_sea_transport()
		for u in arrived_units {
			if t1p(t1c, u) && t2p(t2c, u) {
				total -= 1
			}
		}
	}
	if properties_get_sub_control_sea_zone_restricted(props) {
		mp, mc := matches_unit_can_be_moved_through_by_enemies()
		for u in arrived_units {
			if mp(mc, u) { total -= 1 }
		}
	}
	return total
}

// games.strategy.triplea.delegate.battle.BattleTracker#getNewOwnerForTakeOver(Territory, GamePlayer, GamePlayer, GameData)
// Java: if terrOrigOwner still controls any of its capitals, give the territory back
// to terrOrigOwner. Otherwise, if any of terrOrigOwner's capitals is the territory
// being taken over, or is currently neutral, give it back as well; else give it to
// gamePlayer.
battle_tracker_get_new_owner_for_take_over :: proc(
	territory: ^Territory,
	game_player: ^Game_Player,
	terr_orig_owner: ^Game_Player,
	data: ^Game_Data,
) -> ^Game_Player {
	new_owner := game_player
	game_map := game_data_get_map(data)
	capitals_owned := territory_attachment_get_all_currently_owned_capitals(terr_orig_owner, game_map)
	defer delete(capitals_owned)
	if len(capitals_owned) != 0 {
		new_owner = terr_orig_owner
	} else {
		all_caps := territory_attachment_get_all_capitals(terr_orig_owner, game_map)
		defer delete(all_caps)
		for current in all_caps {
			if territory == current || game_player_is_null(territory_get_owner(current)) {
				new_owner = terr_orig_owner
				break
			}
		}
	}
	return new_owner
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$takeOver$0(RelationshipTracker, GamePlayer, GamePlayer)
// Body of `player -> relationshipTracker.isAllied(player, gamePlayer)` from
// optionalTerrOrigOwner.filter(...). Captures relationshipTracker, gamePlayer.
battle_tracker_lambda_take_over_0 :: proc(
	relationship_tracker: ^Relationship_Tracker,
	game_player: ^Game_Player,
	player: ^Game_Player,
) -> bool {
	return relationship_tracker_is_allied(relationship_tracker, player, game_player)
}

// games.strategy.triplea.delegate.battle.BattleTracker#lambda$writeHistoryOnTakeOverForConvoyRoute$4(
//     RelationshipTracker, GamePlayer, IDelegateHistoryWriter, Territory, Territory)
// Body of the `attachedConvoyTo.forEach(convoy -> { ... })` lambda inside
// writeHistoryOnTakeOverForConvoyRoute. Captures relationshipTracker, newOwner,
// historyWriter, territory; lambda param is convoy.
battle_tracker_lambda_write_history_on_take_over_for_convoy_route_4 :: proc(
	relationship_tracker: ^Relationship_Tracker,
	new_owner: ^Game_Player,
	history_writer: ^I_Delegate_History_Writer,
	territory: ^Territory,
	convoy: ^Territory,
) {
	cta := territory_attachment_get(convoy)
	if cta == nil {
		return
	}
	if !territory_attachment_get_convoy_route(cta) {
		return
	}
	convoy_owner := territory_get_owner(convoy)
	if relationship_tracker_is_allied(relationship_tracker, new_owner, convoy_owner) {
		convoy_attached := territory_attachment_get_convoy_attached(cta)
		any_allied := false
		ap, ac := matches_is_territory_allied(convoy_owner)
		for t, _ in convoy_attached {
			if ap(ac, t) {
				any_allied = true
				break
			}
		}
		if !any_allied {
			msg := fmt.aprintf(
				"%s gains %d production in %s for the liberation the convoy route in %s",
				convoy_owner.name,
				territory_attachment_get_production(cta),
				convoy.name,
				territory.name,
			)
			history_writer_add_child_to_event(history_writer, msg)
		}
	} else if relationship_tracker_is_at_war(relationship_tracker, new_owner, convoy_owner) {
		convoy_attached := territory_attachment_get_convoy_attached(cta)
		count := i32(0)
		ap, ac := matches_is_territory_allied(convoy_owner)
		for t, _ in convoy_attached {
			if ap(ac, t) {
				count += 1
			}
		}
		if count == 1 {
			msg := fmt.aprintf(
				"%s loses %d production in %s due to the capture of the convoy route in %s",
				convoy_owner.name,
				territory_attachment_get_production(cta),
				convoy.name,
				territory.name,
			)
			history_writer_add_child_to_event(history_writer, msg)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#markWasInCombat(Collection<Unit>, IDelegateBridge, UndoableMove)
// Java: if units == null, return. Else build a CompositeChange of one
// `unit.wasInCombat = true` ObjectPropertyChange per unit and add it.
battle_tracker_mark_was_in_combat :: proc(
	units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
) {
	if units == nil {
		return
	}
	cc := composite_change_new()
	for unit in units {
		boxed := new(bool)
		boxed^ = true
		composite_change_add(
			cc,
			change_factory_unit_property_change_property_name(unit, rawptr(boxed), .Was_In_Combat),
		)
	}
	battle_tracker_add_change(bridge, change_tracker, &cc.change)
}

// games.strategy.triplea.delegate.battle.BattleTracker#sendBattleRecordsToGameData(IDelegateBridge)
// Java: if battleRecords != null and not empty, write a "Recording Battle Statistics"
// history event and add an AddBattleRecords change carrying the current records.
battle_tracker_send_battle_records_to_game_data :: proc(self: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	if self.battle_records != nil && !battle_records_is_empty(self.battle_records) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			"Recording Battle Statistics",
		)
		i_delegate_bridge_add_change(
			bridge,
			change_factory_add_battle_records(self.battle_records, &i_delegate_bridge_get_data(bridge).game_state),
		)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#writeHistoryOnTakeOverForConvoyRoute(Territory, GamePlayer, IDelegateBridge)
// Java: for each territory whose convoy route runs through `territory`, write a
// history child entry indicating the new owner has either liberated or captured the
// convoy route. The forEach body is split out as
// `battle_tracker_lambda_write_history_on_take_over_for_convoy_route_4`.
battle_tracker_write_history_on_take_over_for_convoy_route :: proc(
	territory: ^Territory,
	new_owner: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	data := i_delegate_bridge_get_data(bridge)
	relationship_tracker := game_data_get_relationship_tracker(i_delegate_bridge_get_data(bridge))
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	attached_convoy_to := territory_attachment_get_what_territories_this_is_used_in_convoys_for(
		territory,
		&data.game_state,
	)
	defer delete(attached_convoy_to)
	for convoy, _ in attached_convoy_to {
		battle_tracker_lambda_write_history_on_take_over_for_convoy_route_4(
			relationship_tracker,
			new_owner,
			history_writer,
			territory,
			convoy,
		)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#addChangesOnTakeOverAlliedCapitol
//
// Java:
//   private static void addChangesOnTakeOverAlliedCapitol(
//       GamePlayer terrOrigOwner, IDelegateBridge bridge, @Nullable UndoableMove changeTracker) {
//     final GameData data = bridge.getData();
//     final Collection<Territory> originallyOwned =
//         OriginalOwnerTracker.getOriginallyOwned(data, terrOrigOwner);
//     final List<Territory> alliedTerritories =
//         CollectionUtils.getMatches(originallyOwned, Matches.isTerritoryAllied(terrOrigOwner));
//     for (final Territory alliedTerritory : alliedTerritories) {
//       if (alliedTerritory.isOwnedBy(terrOrigOwner)) continue;
//       final Change takeOverFriendlyTerritories =
//           ChangeFactory.changeOwner(alliedTerritory, terrOrigOwner);
//       addChange(bridge, changeTracker, takeOverFriendlyTerritories);
//       bridge.getHistoryWriter().addChildToEvent(takeOverFriendlyTerritories.toString());
//       final Collection<Unit> infrastructureUnits =
//           CollectionUtils.getMatches(alliedTerritory.getUnits(), Matches.unitIsInfrastructure());
//       if (!infrastructureUnits.isEmpty()) {
//         final Change takeOverNonComUnits =
//             ChangeFactory.changeOwner(infrastructureUnits, terrOrigOwner, alliedTerritory);
//         addChange(bridge, changeTracker, takeOverNonComUnits);
//       }
//     }
//   }
battle_tracker_add_changes_on_take_over_allied_capitol :: proc(
	terr_orig_owner: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
) {
	data := i_delegate_bridge_get_data(bridge)
	// give it back to the original owner, if ally
	originally_owned := original_owner_tracker_get_originally_owned(&data.game_state, terr_orig_owner)
	allied_pred, allied_ctx := matches_is_territory_allied(terr_orig_owner)
	allied_territories := make([dynamic]^Territory)
	for terr in originally_owned {
		if allied_pred(allied_ctx, terr) {
			append(&allied_territories, terr)
		}
	}
	infra_pred, infra_ctx := matches_unit_is_infrastructure()
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	for allied_territory in allied_territories {
		if territory_is_owned_by(allied_territory, terr_orig_owner) {
			continue
		}
		take_over_friendly_territories := change_factory_change_owner(allied_territory, terr_orig_owner)
		battle_tracker_add_change(bridge, change_tracker, take_over_friendly_territories)
		oc := cast(^Owner_Change)take_over_friendly_territories
		history_writer_add_child_to_event(history_writer, owner_change_to_string(oc))
		// give back the factories as well
		uc := territory_get_unit_collection(allied_territory)
		infrastructure_units := make([dynamic]^Unit)
		for u in uc.units {
			if infra_pred(infra_ctx, u) {
				append(&infrastructure_units, u)
			}
		}
		if len(infrastructure_units) > 0 {
			take_over_non_com_units := change_factory_change_owner_3(
				infrastructure_units,
				terr_orig_owner,
				allied_territory,
			)
			battle_tracker_add_change(bridge, change_tracker, take_over_non_com_units)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#clearFinishedBattles(IDelegateBridge)
//
//   for (final IBattle battle : List.copyOf(pendingBattles)) {
//     if (FinishedBattle.class.isAssignableFrom(battle.getClass())) {
//       final FinishedBattle finished = (FinishedBattle) battle;
//       finishedBattlesUnitAttackFromMap.put(
//           finished.getTerritory(), finished.getAttackingFromMap());
//       finished.fight(bridge);
//     }
//   }
//
// Java distinguishes FinishedBattle via runtime class identity. The
// Odin port uses the `is_finished_battle` discriminator on the
// embedded Abstract_Battle (set by finished_battle_new). A snapshot
// of the pending_battles keys is taken before iterating because
// finished_battle_fight removes entries from the tracker.
battle_tracker_clear_finished_battles :: proc(self: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	snapshot := make([dynamic]^I_Battle, 0, len(self.pending_battles))
	defer delete(snapshot)
	for b, _ in self.pending_battles {
		append(&snapshot, b)
	}
	for battle in snapshot {
		ab := cast(^Abstract_Battle)battle
		if ab.is_finished_battle {
			finished := cast(^Finished_Battle)battle
			self.finished_battles_unit_attack_from_map[abstract_battle_get_territory(ab)] =
				finished_battle_get_attacking_from_map(finished)
			finished_battle_fight(finished, bridge)
		}
	}
}

// Java: private static void addChangesOnTakeOverCapitol(
//   Territory, TerritoryAttachment, GamePlayer, IDelegateBridge, @Nullable UndoableMove)
battle_tracker_add_changes_on_take_over_capitol :: proc(
	territory: ^Territory,
	territory_attachment: ^Territory_Attachment,
	game_player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
) {
	data := i_delegate_bridge_get_data(bridge)
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	whose_capital := player_list_get_player_id(
		game_data_get_player_list(data),
		territory_attachment_get_capital_or_throw(territory_attachment),
	)
	pa := player_attachment_get(game_player)
	pa_whose_capital := player_attachment_get(whose_capital)
	capitals_list := territory_attachment_get_all_currently_owned_capitals(
		whose_capital,
		game_data_get_map(data),
	)
	if pa_whose_capital != nil &&
	   player_attachment_get_retain_capital_number(pa_whose_capital) < i32(len(capitals_list)) {
		msg := fmt.aprintf(
			"%s captures one of %s capitals",
			game_player.name,
			whose_capital.name,
		)
		history_writer_add_child_to_event(history_writer, msg)
	} else if whose_capital == territory_get_owner(territory) {
		pus := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "PUs")
		captured_pu_count := resource_collection_get_quantity(
			game_player_get_resources(whose_capital),
			pus,
		)
		if pa != nil && properties_get_pacific_theater(game_data_get_properties(data)) {
			new_value := new(i32)
			new_value^ = captured_pu_count + player_attachment_get_capture_vps(pa)
			change_vp := change_factory_attachment_property_change(
				cast(^I_Attachment)rawptr(pa),
				rawptr(new_value),
				"captureVps",
			)
			battle_tracker_add_change(bridge, change_tracker, change_vp)
		}
		remove := change_factory_change_resources_change(whose_capital, pus, -captured_pu_count)
		battle_tracker_add_change(bridge, change_tracker, remove)
		if pa_whose_capital != nil && player_attachment_get_destroys_pus(pa_whose_capital) {
			msg := fmt.aprintf(
				"%s destroys %d%s while taking %s capital",
				game_player.name,
				captured_pu_count,
				my_formatter_pluralize_quantity("PU", captured_pu_count),
				whose_capital.name,
			)
			history_writer_add_child_to_event(history_writer, msg)
		} else {
			msg := fmt.aprintf(
				"%s captures %d%s while taking %s capital",
				game_player.name,
				captured_pu_count,
				my_formatter_pluralize_quantity("PU", captured_pu_count),
				whose_capital.name,
			)
			history_writer_add_child_to_event(history_writer, msg)
			add := change_factory_change_resources_change(game_player, pus, captured_pu_count)
			battle_tracker_add_change(bridge, change_tracker, add)
		}
		if resource_list_get_resource_optional(game_data_get_resource_list(data), "techTokens") != nil {
			tokens := resource_list_get_resource_or_throw(game_data_get_resource_list(data), "techTokens")
			curr_tokens := resource_collection_get_quantity_by_name(
				game_player_get_resources(whose_capital),
				"techTokens",
			)
			remove_tokens := change_factory_change_resources_change(whose_capital, tokens, -curr_tokens)
			battle_tracker_add_change(bridge, change_tracker, remove_tokens)
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#captureOrDestroyUnits(
//   Territory, GamePlayer, GamePlayer, IDelegateBridge, UndoableMove)
//
// Java static. Walks the territory's units, removing destroy-on-capture
// targets, retiring disabled enemy combat units, optionally swapping
// noncombatant units to a different unit type, then transferring the
// remaining noncombatants to the new owner with bookkeeping for capture
// damage and units that die at max damage.
battle_tracker_capture_or_destroy_units :: proc(
	territory: ^Territory,
	game_player: ^Game_Player,
	new_owner: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
) {
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	data := i_delegate_bridge_get_data(bridge)
	properties := game_data_get_properties(data)
	unit_collection := territory_get_unit_collection(territory)
	territory_holder := cast(^Unit_Holder)territory

	// destroy any units that should be destroyed on capture
	if properties_get_units_can_be_destroyed_instead_of_captured(properties) {
		eu_p, eu_c := matches_enemy_unit(game_player)
		du_p, du_c := matches_unit_destroyed_when_captured_by_or_from(game_player)
		destroyed: [dynamic]^Unit
		for u in unit_collection.units {
			if eu_p(eu_c, u) && du_p(du_c, u) {
				append(&destroyed, u)
			}
		}
		if len(destroyed) > 0 {
			history_writer_add_child_to_event(history_writer, "Some non-combat units are destroyed: ")
			battle_tracker_add_change(
				bridge,
				change_tracker,
				change_factory_remove_units(territory_holder, destroyed),
			)
		}
	}

	// destroy any capture-on-entering units, IF the property to destroy them
	// instead of capture is turned on
	if properties_get_on_entering_units_destroyed_instead_of_captured(properties) {
		ce_p, ce_c := matches_unit_can_be_captured_on_entering_this_territory(game_player, territory)
		destroyed: [dynamic]^Unit
		for u in unit_collection.units {
			if ce_p(ce_c, u) {
				append(&destroyed, u)
			}
		}
		if len(destroyed) > 0 {
			msg := fmt.aprintf(
				"%s destroys some units instead of capturing them",
				game_player.name,
			)
			history_writer_add_child_to_event(history_writer, msg)
			battle_tracker_add_change(
				bridge,
				change_tracker,
				change_factory_remove_units(territory_holder, destroyed),
			)
		}
	}

	// destroy any disabled units owned by the enemy that are NOT
	// infrastructure or factories
	{
		eu_p, eu_c := matches_enemy_unit(game_player)
		dis_p, dis_c := matches_unit_is_disabled()
		inf_p, inf_c := matches_unit_is_infrastructure()
		destroyed: [dynamic]^Unit
		for u in unit_collection.units {
			if eu_p(eu_c, u) && dis_p(dis_c, u) && !inf_p(inf_c, u) {
				append(&destroyed, u)
			}
		}
		if len(destroyed) > 0 {
			msg := fmt.aprintf("%s destroys some disabled combat units", game_player.name)
			history_writer_add_child_to_event(history_writer, msg)
			battle_tracker_add_change(
				bridge,
				change_tracker,
				change_factory_remove_units(territory_holder, destroyed),
			)
		}
	}

	// take over non-combatants
	non_com: [dynamic]^Unit
	{
		eu_p, eu_c := matches_enemy_unit(game_player)
		inf_p, inf_c := matches_unit_is_infrastructure()
		ce_p, ce_c := matches_unit_can_be_captured_on_entering_this_territory(game_player, territory)
		for u in unit_collection.units {
			enemy_non_com := eu_p(eu_c, u) && inf_p(inf_c, u)
			if enemy_non_com || ce_p(ce_c, u) {
				append(&non_com, u)
			}
		}
	}

	// change any units that change unit types on capture
	if properties_get_units_can_be_changed_on_capture(properties) {
		wc_p, wc_c := matches_unit_when_captured_changes_into_different_unit_type()
		to_replace: [dynamic]^Unit
		for u in non_com {
			if wc_p(wc_c, u) {
				append(&to_replace, u)
			}
		}
		for u in to_replace {
			capture_map := unit_attachment_get_when_captured_changes_into(unit_get_unit_attachment(u))
			current_owner := unit_get_owner(u)
			for key, to_create in capture_map {
				parts := strings.split(key, ":")
				defer delete(parts)
				if len(parts) < 2 {
					continue
				}
				if !(parts[0] == "any" ||
					   player_list_get_player_id(game_data_get_player_list(data), parts[0]) ==
						   current_owner) {
					continue
				}
				// we could use "id" or "newOwner" here... not sure which to use
				if !(parts[1] == "any" ||
					   player_list_get_player_id(game_data_get_player_list(data), parts[1]) ==
						   game_player) {
					continue
				}
				changes := composite_change_new()
				to_add: [dynamic]^Unit
				translate_attributes :=
					strings.equal_fold(tuple_get_first(to_create), "true")
				ut_to_count := tuple_get_second(to_create)
				for ut, qty in ut_to_count {
					created := unit_type_create_2(ut, qty, new_owner)
					for c in created {
						append(&to_add, c)
					}
					delete(created)
				}
				if len(to_add) > 0 {
					if translate_attributes {
						translate := unit_utils_translate_attributes_to_other_units(
							u,
							to_add,
							territory,
						)
						if !change_is_empty(translate) {
							composite_change_add(changes, translate)
						}
					}
					single: [dynamic]^Unit
					append(&single, u)
					composite_change_add(
						changes,
						change_factory_remove_units(territory_holder, single),
					)
					composite_change_add(
						changes,
						change_factory_add_units(territory_holder, to_add),
					)
					composite_change_add(
						changes,
						change_factory_mark_no_movement_change_collection(to_add),
					)
					msg := fmt.aprintf(
						"%s converts %s into different units",
						game_player.name,
						unit_to_string_no_owner(u),
					)
					history_writer_add_child_to_event(history_writer, msg)
					battle_tracker_add_change(bridge, change_tracker, &changes.change)
					// don't forget to remove this unit from the list
					for cand, idx in non_com {
						if cand == u {
							ordered_remove(&non_com, idx)
							break
						}
					}
					break
				}
			}
		}
	}

	if len(non_com) > 0 {
		// FYI: a dummy delegate will not do anything with this change,
		// meaning that the battle calculator will think this unit lived,
		// even though it died or was captured, etc.!
		battle_tracker_add_change(
			bridge,
			change_tracker,
			change_factory_change_owner_3(non_com, new_owner, territory),
		)
		battle_tracker_add_change(
			bridge,
			change_tracker,
			change_factory_mark_no_movement_change_collection(non_com),
		)
		damage_map := new(Integer_Map_Unit)
		damage_map.entries = make(map[^Unit]i32)
		ws_p, ws_c := matches_unit_when_captured_sustains_damage()
		for unit in non_com {
			if !ws_p(ws_c, unit) {
				continue
			}
			damage_limit := unit_get_how_much_more_damage_can_this_unit_take(unit, territory)
			sustained_damage :=
				unit_attachment_get_when_captured_sustains_damage(unit_get_unit_attachment(unit))
			actual_damage := max(i32(0), min(sustained_damage, damage_limit))
			total_damage := unit_get_unit_damage(unit) + actual_damage
			damage_map.entries[unit] = total_damage
		}
		if len(damage_map.entries) > 0 {
			single_terr: [dynamic]^Territory
			append(&single_terr, territory)
			damage_change := change_factory_bombing_unit_damage(damage_map, single_terr)
			battle_tracker_add_change(bridge, change_tracker, damage_change)
			// Kill any units that can die if they have reached max damage
			can_die_p, can_die_c := matches_unit_can_die_from_reaching_max_damage()
			max_p, max_c := matches_unit_is_at_max_damage_or_not_can_be_damaged(territory)
			units_can_die: [dynamic]^Unit
			for unit, _ in damage_map.entries {
				if can_die_p(can_die_c, unit) && max_p(max_c, unit) {
					append(&units_can_die, unit)
				}
			}
			if len(units_can_die) > 0 {
				battle_tracker_add_change(
					bridge,
					change_tracker,
					change_factory_remove_units(territory_holder, units_can_die),
				)
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#addAirBattle(Route, Collection<Unit>, GamePlayer, GameData, IBattle$BattleType)
//
// Java:
//   if (units.isEmpty()) return;
//   IBattle battle = getPendingBattle(route.getEnd(), battleType);
//   if (battle == null) {
//     battle = new AirBattle(route.getEnd(), battleType, data, attacker, this);
//     pendingBattles.add(battle);
//     getBattleRecords().addBattle(attacker, battle.getBattleId(), route.getEnd(), battle.getBattleType());
//   }
//   final Change change = battle.addAttackChange(route, units, null);
//   if (!change.isEmpty()) throw new IllegalStateException("Non empty change");
//   if (battleType.isBombingRun()) {
//     final IBattle dependentAirBattle = getPendingBattle(route.getEnd(), AIR_BATTLE);
//     if (dependentAirBattle != null) addDependency(dependentAirBattle, battle);
//   } else {
//     final IBattle airRaid = getPendingBattle(route.getEnd(), AIR_RAID);
//     if (airRaid != null) addDependency(battle, airRaid);
//     final IBattle raid = getPendingBattle(route.getEnd(), BOMBING_RAID);
//     if (raid != null) addDependency(battle, raid);
//   }
//   final IBattle dependent = getPendingBattle(route.getEnd(), NORMAL);
//   if (dependent != null) addDependency(dependent, battle);
battle_tracker_add_air_battle :: proc(
	self: ^Battle_Tracker,
	route: ^Route,
	units: [dynamic]^Unit,
	attacker: ^Game_Player,
	data: ^Game_Data,
	battle_type: I_Battle_Battle_Type,
) {
	if len(units) == 0 {
		return
	}
	end := route_get_end(route)
	battle := battle_tracker_get_pending_battle(self, end, battle_type)
	if battle == nil {
		new_air := air_battle_new(end, battle_type, data, attacker, self)
		battle = cast(^I_Battle)new_air
		self.pending_battles[battle] = {}
		battle_records_add_battle(
			battle_tracker_get_battle_records(self),
			attacker,
			i_battle_get_battle_id(battle),
			end,
			i_battle_get_battle_type(battle),
		)
	}
	change := air_battle_add_attack_change(cast(^Air_Battle)battle, route, units, nil)
	if !change_is_empty(change) {
		panic("Non empty change")
	}
	if i_battle_battle_type_is_bombing_run(battle_type) {
		dependent_air_battle := battle_tracker_get_pending_battle(self, end, .AIR_BATTLE)
		if dependent_air_battle != nil {
			battle_tracker_add_dependency(self, dependent_air_battle, battle)
		}
	} else {
		air_raid := battle_tracker_get_pending_battle(self, end, .AIR_RAID)
		if air_raid != nil {
			battle_tracker_add_dependency(self, battle, air_raid)
		}
		raid := battle_tracker_get_pending_battle(self, end, .BOMBING_RAID)
		if raid != nil {
			battle_tracker_add_dependency(self, battle, raid)
		}
	}
	dependent := battle_tracker_get_pending_battle(self, end, .NORMAL)
	if dependent != nil {
		battle_tracker_add_dependency(self, dependent, battle)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#addBombingBattle(Route, Collection<Unit>, GamePlayer, GameData, Map<Unit,Set<Unit>>)
//
// Java:
//   IBattle battle = getPendingBattle(route.getEnd(), BOMBING_RAID);
//   if (battle == null) {
//     battle = new StrategicBombingRaidBattle(route.getEnd(), data, attacker, this);
//     pendingBattles.add(battle);
//     getBattleRecords().addBattle(attacker, battle.getBattleId(), route.getEnd(), battle.getBattleType());
//   }
//   final Change change = battle.addAttackChange(route, units, targets);
//   if (!change.isEmpty()) throw new IllegalStateException("Non empty change");
//   final IBattle dependent = getPendingBattle(route.getEnd(), NORMAL);
//   if (dependent != null) addDependency(dependent, battle);
//   final IBattle dependentAirBattle = getPendingBattle(route.getEnd(), AIR_BATTLE);
//   if (dependentAirBattle != null) addDependency(dependentAirBattle, battle);
battle_tracker_add_bombing_battle :: proc(
	self: ^Battle_Tracker,
	route: ^Route,
	units: [dynamic]^Unit,
	attacker: ^Game_Player,
	data: ^Game_Data,
	targets: ^map[^Unit]map[^Unit]struct{},
) {
	end := route_get_end(route)
	battle := battle_tracker_get_pending_battle(self, end, .BOMBING_RAID)
	if battle == nil {
		new_sbr := strategic_bombing_raid_battle_new(end, data, attacker, self)
		battle = cast(^I_Battle)new_sbr
		self.pending_battles[battle] = {}
		battle_records_add_battle(
			battle_tracker_get_battle_records(self),
			attacker,
			i_battle_get_battle_id(battle),
			end,
			i_battle_get_battle_type(battle),
		)
	}
	change := strategic_bombing_raid_battle_add_attack_change(
		cast(^Strategic_Bombing_Raid_Battle)battle,
		route,
		units,
		targets,
	)
	if !change_is_empty(change) {
		panic("Non empty change")
	}
	dependent := battle_tracker_get_pending_battle(self, end, .NORMAL)
	if dependent != nil {
		battle_tracker_add_dependency(self, dependent, battle)
	}
	dependent_air_battle := battle_tracker_get_pending_battle(self, end, .AIR_BATTLE)
	if dependent_air_battle != nil {
		battle_tracker_add_dependency(self, dependent_air_battle, battle)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#fightDefenselessBattles(IDelegateBridge)
//
// Java: walk every pending NORMAL battle whose dependencies are clear and
// whose defenders have zero total power; auto-fight each. Then auto-fight
// every NonFightingBattle whose dependencies are clear. Java distinguishes
// NonFightingBattle via runtime class identity; the Odin port discriminates
// by `is_must_fight_battle == false && is_finished_battle == false` on the
// embedded Abstract_Battle (the only NORMAL pending battles that are
// neither MustFightBattle nor FinishedBattle are NonFightingBattles —
// FinishedBattles are removed earlier by clearFinishedBattles).
battle_tracker_fight_defenseless_battles :: proc(self: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	properties := game_data_get_properties(data)
	support_rules_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(data))
	support_attachments: [dynamic]^Unit_Support_Attachment
	defer delete(support_attachments)
	for usa, _ in support_rules_map {
		append(&support_attachments, usa)
	}
	normals := battle_tracker_get_pending_battles_of_type(self, .NORMAL)
	defer delete(normals)
	for battle in normals {
		territory := i_battle_get_territory(battle)
		defenders := i_battle_get_defending_units(battle)
		possible_defenders := battle_tracker_get_possible_defending_units(territory, defenders)
		deps := battle_tracker_get_dependent_on(self, battle)
		if len(deps) == 0 {
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
												defenders,
											),
											possible_defenders,
										),
										.DEFENSE,
									),
									game_data_get_sequence(data),
								),
								support_attachments,
							),
							properties_get_lhtr_heavy_bombers(properties),
						),
						int(game_data_get_dice_sides(data)),
					),
					territory_effect_helper_get_effects(territory),
				),
			)
			psar := power_strength_and_rolls_build(possible_defenders, cv)
			if power_strength_and_rolls_calculate_total_power(psar) == 0 {
				i_battle_fight(battle, bridge)
			}
		}
		delete(deps)
		delete(possible_defenders)
	}
	normals2 := battle_tracker_get_pending_battles_of_type(self, .NORMAL)
	defer delete(normals2)
	for battle in normals2 {
		ab := cast(^Abstract_Battle)battle
		if ab.is_must_fight_battle || ab.is_finished_battle {
			continue
		}
		deps := battle_tracker_get_dependent_on(self, battle)
		if len(deps) == 0 {
			i_battle_fight(battle, bridge)
		}
		delete(deps)
	}
}

// games.strategy.triplea.delegate.battle.BattleTracker#takeOver(Territory, GamePlayer, IDelegateBridge, UndoableMove, Collection<Unit>)
//
// Faithful port of the Java method. Optional<TerritoryAttachment> is mirrored
// by a nil-check on territory_attachment_get; Optional<GamePlayer> from
// OriginalOwnerTracker.getOriginalOwner is similarly nil-vs-non-nil.
battle_tracker_take_over :: proc(
	self: ^Battle_Tracker,
	territory: ^Territory,
	game_player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	change_tracker: ^Undoable_Move,
	arriving_units: [dynamic]^Unit,
) {
	territory_attachment := territory_attachment_get(territory)
	if territory_attachment == nil {
		// TODO: allow capture/destroy of infrastructure on unowned water (Java comment)
		return
	}
	data := i_delegate_bridge_get_data(bridge)
	arrived_units: [dynamic]^Unit
	arrived_present := arriving_units != nil
	if arrived_present {
		arrived_units = make([dynamic]^Unit, 0, len(arriving_units))
		for u in arriving_units {
			append(&arrived_units, u)
		}
	}
	defer if arrived_present {
		delete(arrived_units)
	}
	relationship_tracker := game_data_get_relationship_tracker(data)
	is_territory_owner_an_enemy := relationship_tracker_can_take_over_owned_territory(
		relationship_tracker,
		game_player,
		territory_get_owner(territory),
	)
	// If this is a convoy (we wouldn't be in this method otherwise) check that
	// attackers have more than just transports. If they don't, exit here.
	if territory_is_water(territory) &&
	   arrived_present &&
	   battle_tracker_get_all_attaching_sea_units(arrived_units, data) == 0 {
		return
	}
	// If it was a Convoy Route - write history.
	if territory_attachment_get_convoy_route(territory_attachment) {
		battle_tracker_write_history_on_take_over_for_convoy_route(territory, game_player, bridge)
	}
	// If neutral, we may charge money to enter.
	if game_player_is_null(territory_get_owner(territory)) &&
	   !territory_is_water(territory) &&
	   properties_get_neutral_charge(game_data_get_properties(data)) >= 0 {
		battle_tracker_add_change_charge_for_entering_neutrals(
			territory,
			game_player,
			bridge,
			change_tracker,
		)
	}
	// If it's a capital we take the money.
	if is_territory_owner_an_enemy && territory_attachment_is_capital(territory_attachment) {
		battle_tracker_add_changes_on_take_over_capitol(
			territory,
			territory_attachment,
			game_player,
			bridge,
			change_tracker,
		)
	}
	// Is this an allied territory? Revert to original owner if it is.
	terr_orig_owner := original_owner_tracker_get_original_owner(territory)
	is_territory_orig_owner_allied :=
		terr_orig_owner != nil &&
		relationship_tracker_is_allied(relationship_tracker, terr_orig_owner, game_player)
	new_owner: ^Game_Player
	if is_territory_owner_an_enemy &&
	   is_territory_orig_owner_allied &&
	   terr_orig_owner != territory_get_owner(territory) {
		new_owner = battle_tracker_get_new_owner_for_take_over(
			territory,
			game_player,
			terr_orig_owner,
			data,
		)
	} else {
		new_owner = game_player
	}
	// whenCapturedByGoesTo override.
	{
		coc_pred, coc_ctx := matches_territory_has_capture_ownership_changes()
		if is_territory_owner_an_enemy && new_owner == game_player && coc_pred(coc_ctx, territory) {
			changes := territory_attachment_get_capture_ownership_changes(territory_attachment)
			defer delete(changes)
			for co in changes {
				if co.capturing_player == co.receiving_player {
					continue
				}
				if co.capturing_player != game_player {
					continue
				}
				new_owner = co.receiving_player
				break
			}
		}
	}
	if is_territory_owner_an_enemy {
		battle_tracker_add_change_change_ownership(
			self,
			territory,
			new_owner,
			territory_attachment,
			game_player,
			bridge,
			change_tracker,
			arrived_units,
		)
	}
	// Remove any bombing raids against captured territory: error if non-empty.
	{
		uc := territory_get_unit_collection(territory)
		eu_p, eu_c := matches_unit_is_enemy_of(game_player)
		dmg_p, dmg_c := matches_unit_can_be_damaged()
		any_match := false
		for u in uc.units {
			if eu_p(eu_c, u) && dmg_p(dmg_c, u) {
				any_match = true
				break
			}
		}
		if any_match {
			bombing_battle := battle_tracker_get_pending_bombing_battle(self, territory)
			if bombing_battle != nil && !i_battle_is_empty(bombing_battle) {
				panic(BOMBING_DEPENDENCY_ERROR)
			}
		}
	}
	battle_tracker_capture_or_destroy_units(territory, game_player, new_owner, bridge, change_tracker)
	// Is this our capitol or a capitol of our ally?
	if is_territory_owner_an_enemy &&
	   is_territory_orig_owner_allied &&
	   territory_attachment_is_capital(territory_attachment) {
		all_caps := territory_attachment_get_all_capitals(terr_orig_owner, game_data_get_map(data))
		defer delete(all_caps)
		contains := false
		for capital in all_caps {
			if capital == territory {
				contains = true
				break
			}
		}
		if contains {
			battle_tracker_add_changes_on_take_over_allied_capitol(
				terr_orig_owner,
				bridge,
				change_tracker,
			)
		}
	}
	// say they were in combat — if water territory, drop land units first.
	if arrived_present && territory_is_water(territory) {
		lp, lc := matches_unit_is_land()
		filtered: [dynamic]^Unit
		for u in arrived_units {
			if !lp(lc, u) {
				append(&filtered, u)
			}
		}
		clear(&arrived_units)
		for u in filtered {
			append(&arrived_units, u)
		}
		delete(filtered)
	}
	battle_tracker_mark_was_in_combat(arrived_units, bridge, change_tracker)
}

