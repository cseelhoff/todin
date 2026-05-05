package game

import "core:fmt"
import "core:slice"
import "core:strings"

MUST_COMPLETE_BATTLE_PREFIX :: "Must complete "

Battle_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	battle_tracker: ^Battle_Tracker,
	need_to_initialize: bool,
	need_to_scramble: bool,
	need_to_kamikaze_suicide_attacks: bool,
	need_to_clear_empty_air_battle_attacks: bool,
	need_to_add_bombardment_sources: bool,
	need_to_record_battle_statistics: bool,
	need_to_check_defending_planes_can_land: bool,
	need_to_cleanup: bool,
	need_to_create_rockets: bool,
	need_to_fire_rockets: bool,
	rocket_helper: ^Rockets_Fire_Helper,
	current_battle: ^I_Battle,
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getBattleTracker()
battle_delegate_get_battle_tracker :: proc(self: ^Battle_Delegate) -> ^Battle_Tracker {
	return self.battle_tracker
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getCurrentBattle()
battle_delegate_get_current_battle :: proc(self: ^Battle_Delegate) -> ^I_Battle {
	return self.current_battle
}

// games.strategy.triplea.delegate.battle.BattleDelegate#clearCurrentBattle(IBattle)
battle_delegate_clear_current_battle :: proc(self: ^Battle_Delegate, battle: ^I_Battle) {
	if battle == self.current_battle {
		self.current_battle = nil
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getRemoteType()
// Java returns `Class<? extends IRemote>` (IBattleDelegate.class); Odin mirrors
// IDelegate#getRemoteType and returns the corresponding `typeid`.
battle_delegate_get_remote_type :: proc(self: ^Battle_Delegate) -> typeid {
	return I_Battle_Delegate
}

// games.strategy.triplea.delegate.battle.BattleDelegate#isBattleDependencyErrorMessage(String)
battle_delegate_is_battle_dependency_error_message :: proc(message: string) -> bool {
	return strings.has_prefix(message, MUST_COMPLETE_BATTLE_PREFIX)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$getPossibleBombardingTerritories$0(Territory)
// Body of `k -> new ArrayList<>()` from getPossibleBombardingTerritories.
// No captures; static-style lambda — `self` is dropped.
battle_delegate_lambda_get_possible_bombarding_territories_0 :: proc(k: ^Territory) -> [dynamic]^I_Battle {
	return make([dynamic]^I_Battle)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$doKamikazeSuicideAttacks$6(GamePlayer)
// Body of `key -> new ArrayList<>()` from doKamikazeSuicideAttacks
// (kamikazeZonesByEnemy.computeIfAbsent). No captures; static-style — `self` dropped.
battle_delegate_lambda_do_kamikaze_suicide_attacks_6 :: proc(key: ^Game_Player) -> [dynamic]^Territory {
	return make([dynamic]^Territory)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$setupTerritoriesAbandonedToTheEnemy$1(List, Map$Entry)
// Body of `e -> abandonedToUnits.contains(e.getKey())` from setupTerritoriesAbandonedToTheEnemy.
// The captured List is passed as the first argument; the Map.Entry's key (a Unit)
// is passed directly as the second argument since only `e.getKey()` is used.
battle_delegate_lambda_setup_territories_abandoned_to_the_enemy_1 :: proc(abandoned_to_units: ^[dynamic]^Unit, entry_key: ^Unit) -> bool {
	return slice.contains(abandoned_to_units[:], entry_key)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getFightingWord(IBattle)
// Java: return battle.getBattleType().toDisplayText();
battle_delegate_get_fighting_word :: proc(battle: ^I_Battle) -> string {
	return i_battle_battle_type_to_display_text(i_battle_get_battle_type(battle))
}

// games.strategy.triplea.delegate.battle.BattleDelegate#sortUnitsToBombard(List)
// Java: units.sort(UnitComparator.getDecreasingBombardComparator());
battle_delegate_sort_units_to_bombard :: proc(units: ^[dynamic]^Unit) {
	if len(units) == 0 {
		return
	}
	slice.sort_by(units[:], proc(a, b: ^Unit) -> bool {
		return unit_comparator_decreasing_bombard_compare(a, b) < 0
	})
}

// games.strategy.triplea.delegate.battle.BattleDelegate#loadState(Serializable)
// Mirrors Java: super.loadState(s.superState) then field-by-field copy.
// Caller passes the typed Battle_Extended_Delegate_State (Java does an
// internal cast); see abstract_move_delegate_load_state for the pattern.
battle_delegate_load_state :: proc(self: ^Battle_Delegate, state: ^Battle_Extended_Delegate_State) {
	base_triple_a_delegate_load_state(&self.base_triple_a_delegate, (^Base_Delegate_State)(state.super_state))
	self.battle_tracker = state.battle_tracker
	self.need_to_initialize = state.need_to_initialize
	self.need_to_scramble = state.need_to_scramble
	self.need_to_create_rockets = state.need_to_create_rockets
	self.need_to_kamikaze_suicide_attacks = state.need_to_kamikaze_suicide_attacks
	self.need_to_clear_empty_air_battle_attacks = state.need_to_clear_empty_air_battle_attacks
	self.need_to_add_bombardment_sources = state.need_to_add_bombardment_sources
	self.need_to_fire_rockets = state.need_to_fire_rockets
	self.need_to_record_battle_statistics = state.need_to_record_battle_statistics
	self.need_to_check_defending_planes_can_land = state.need_to_check_defending_planes_can_land
	self.need_to_cleanup = state.need_to_cleanup
	self.current_battle = state.current_battle
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$doScrambling$3(Map$Entry)
// Body of the `removeIf` predicate inside doScrambling:
//   e -> { final Collection<Unit> unitsToScramble = e.getValue().getSecond();
//          unitsToScramble.retainAll(e.getKey().getUnitCollection());
//          return unitsToScramble.isEmpty(); }
// The entry key is a Territory; the entry value is a Tuple<Collection<Unit>,
// Collection<Unit>> — the second element is the to-scramble collection that
// retainAll mutates in place. No outer captures.
battle_delegate_lambda_do_scrambling_3 :: proc(entry_key: ^Territory, entry_value: ^Tuple([dynamic]^Unit, [dynamic]^Unit)) -> bool {
	territory_units := unit_collection_get_units(territory_get_unit_collection(entry_key))
	kept := make([dynamic]^Unit)
	for u in entry_value.second {
		if slice.contains(territory_units[:], u) {
			append(&kept, u)
		}
	}
	delete(entry_value.second)
	entry_value.second = kept
	return len(entry_value.second) == 0
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$doScrambling$5(GamePlayer)
// Body of `.filter(player -> !player.isNull())` inside doScrambling. No captures.
battle_delegate_lambda_do_scrambling_5 :: proc(player: ^Game_Player) -> bool {
	return !game_player_is_null(player)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#<init>()
// Java has no explicit constructor; the implicit one applies the field
// initializers: `battleTracker = new BattleTracker()`, every `needTo*`
// flag = true, and `rocketHelper`/`currentBattle` default to null. The
// embedded BaseTripleADelegate has no overridden constructor so its
// fields are zero-initialized here.
battle_delegate_new :: proc() -> ^Battle_Delegate {
	self := new(Battle_Delegate)
	self.battle_tracker = battle_tracker_new()
	self.need_to_initialize = true
	self.need_to_scramble = true
	self.need_to_kamikaze_suicide_attacks = true
	self.need_to_clear_empty_air_battle_attacks = true
	self.need_to_add_bombardment_sources = true
	self.need_to_record_battle_statistics = true
	self.need_to_check_defending_planes_can_land = true
	self.need_to_cleanup = true
	self.need_to_create_rockets = true
	self.need_to_fire_rockets = true
	return self
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getBattleListing()
// Java: return battleTracker.getBattleListingFromPendingBattles();
battle_delegate_get_battle_listing :: proc(self: ^Battle_Delegate) -> ^Battle_Listing {
	return battle_tracker_get_battle_listing_from_pending_battles(self.battle_tracker)
}

// Captured-closure record for
//   lambda$setupTerritoriesAbandonedToTheEnemy$2(GamePlayer)
// which mirrors `p -> Matches.unitIsEnemyOf(p)
//                       .and(Matches.unitIsNotAir())
//                       .and(Matches.unitIsNotInfrastructure())`.
// The three composed predicates are constructed once at lambda-creation
// time (matching Java's `.and()` semantics, which builds the chain once
// rather than per-test) and stored here so the body is allocation-free.
Battle_Delegate_Setup_Abandoned_Predicate_2_Ctx :: struct {
	enemy_of_p:         proc(rawptr, ^Unit) -> bool,
	enemy_of_c:         rawptr,
	not_air_p:          proc(rawptr, ^Unit) -> bool,
	not_air_c:          rawptr,
	not_infrastructure_p: proc(rawptr, ^Unit) -> bool,
	not_infrastructure_c: rawptr,
}

battle_delegate_pred_setup_territories_abandoned_to_the_enemy_2 :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	c := cast(^Battle_Delegate_Setup_Abandoned_Predicate_2_Ctx)ctx_ptr
	if !c.enemy_of_p(c.enemy_of_c, u) {
		return false
	}
	if !c.not_air_p(c.not_air_c, u) {
		return false
	}
	if !c.not_infrastructure_p(c.not_infrastructure_c, u) {
		return false
	}
	return true
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$setupTerritoriesAbandonedToTheEnemy$2(GamePlayer)
// Body of `p -> Matches.unitIsEnemyOf(p).and(Matches.unitIsNotAir())
//                .and(Matches.unitIsNotInfrastructure())` from
// setupTerritoriesAbandonedToTheEnemy. The captured `p` is the only
// argument; we build the three component predicates eagerly and pack
// them into a heap ctx so the returned (pred, ctx) pair behaves like
// Java's composed Predicate<Unit>.
battle_delegate_lambda_setup_territories_abandoned_to_the_enemy_2 :: proc(
	p: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Battle_Delegate_Setup_Abandoned_Predicate_2_Ctx)
	ctx.enemy_of_p, ctx.enemy_of_c = matches_unit_is_enemy_of(p)
	ctx.not_air_p, ctx.not_air_c = matches_unit_is_not_air()
	ctx.not_infrastructure_p, ctx.not_infrastructure_c = matches_unit_is_not_infrastructure()
	return battle_delegate_pred_setup_territories_abandoned_to_the_enemy_2, rawptr(ctx)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#saveState()
// Builds a Battle_Extended_Delegate_State, fills superState from the
// parent BaseTripleADelegate.saveState(), and copies every per-flag
// plus battle_tracker / current_battle. Java returns Serializable; the
// Odin port returns the concrete state pointer (loadState downcasts).
// Note: Java's saveState does not persist `rocketHelper`, so the field
// is left at its zero value here.
battle_delegate_save_state :: proc(self: ^Battle_Delegate) -> ^Battle_Extended_Delegate_State {
	state := battle_extended_delegate_state_new()
	state.super_state = base_triple_a_delegate_save_state(&self.base_triple_a_delegate)
	state.battle_tracker = self.battle_tracker
	state.need_to_initialize = self.need_to_initialize
	state.need_to_scramble = self.need_to_scramble
	state.need_to_create_rockets = self.need_to_create_rockets
	state.need_to_kamikaze_suicide_attacks = self.need_to_kamikaze_suicide_attacks
	state.need_to_clear_empty_air_battle_attacks = self.need_to_clear_empty_air_battle_attacks
	state.need_to_add_bombardment_sources = self.need_to_add_bombardment_sources
	state.need_to_fire_rockets = self.need_to_fire_rockets
	state.need_to_record_battle_statistics = self.need_to_record_battle_statistics
	state.need_to_check_defending_planes_can_land = self.need_to_check_defending_planes_can_land
	state.need_to_cleanup = self.need_to_cleanup
	state.current_battle = self.current_battle
	return state
}

// games.strategy.triplea.delegate.battle.BattleDelegate#delegateCurrentlyRequiresUserInput()
//   final BattleListing battles = getBattleListing();
//   if (battles.isEmpty()) {
//     final IBattle battle = getCurrentBattle();
//     return battle != null;
//   }
//   return true;
battle_delegate_delegate_currently_requires_user_input :: proc(self: ^Battle_Delegate) -> bool {
	battles := battle_delegate_get_battle_listing(self)
	if battle_listing_is_empty(battles) {
		return battle_delegate_get_current_battle(self) != nil
	}
	return true
}

// games.strategy.triplea.delegate.battle.BattleDelegate#clearEmptyAirBattleAttacks(BattleTracker, IDelegateBridge)
battle_delegate_clear_empty_air_battle_attacks :: proc(battle_tracker: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	// these are air battle and air raids where there is no defender, probably because no air is in
	// range to defend
	battle_tracker_clear_empty_air_battle_attacks(battle_tracker, bridge)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#fightBattle(Territory, boolean, IBattle$BattleType)
// Mirrors the Java method byte-for-byte. Returns "" on success (Java `null`)
// and a human-readable error string otherwise. The `bombing` parameter is
// declared by the IBattleDelegate remote API but the Java body, like ours,
// does not consult it — the lookup is keyed by `type` alone.
battle_delegate_fight_battle :: proc(
	self: ^Battle_Delegate,
	territory: ^Territory,
	bombing: bool,
	type: I_Battle_Battle_Type,
) -> string {
	_ = bombing
	battle := battle_tracker_get_pending_battle(self.battle_tracker, territory, type)
	if self.current_battle != nil && self.current_battle != battle {
		cur_terr := i_battle_get_territory(self.current_battle)
		return fmt.aprintf(
			"Must finish %s in %s first",
			battle_delegate_get_fighting_word(self.current_battle),
			cur_terr.named.base.name,
		)
	}
	if battle == nil {
		return fmt.aprintf("No pending battle in%s", territory.named.base.name)
	}
	all_must_precede := battle_tracker_get_dependent_on(self.battle_tracker, battle)
	defer delete(all_must_precede)
	if len(all_must_precede) > 0 {
		// CollectionUtils.getAny(allMustPrecede): pick an arbitrary element.
		first_precede: ^I_Battle = nil
		for k, _ in all_must_precede {
			first_precede = k
			break
		}
		name := i_battle_get_territory(first_precede).named.base.name
		return strings.concatenate(
			[]string{
				MUST_COMPLETE_BATTLE_PREFIX,
				battle_delegate_get_fighting_word(first_precede),
				" in ",
				name,
				" first",
			},
		)
	}
	self.current_battle = battle
	i_battle_fight(battle, self.bridge)
	return ""
}

// games.strategy.triplea.delegate.battle.BattleDelegate#getPossibleBombardingTerritories()
//   final Map<Territory, Collection<IBattle>> possibleBombardingTerritories = new HashMap<>();
//   for (IBattle battle : battleTracker.getPendingBattles(BattleType.NORMAL)) {
//     if (!(battle instanceof MustFightBattle)) continue;
//     if (!battle.isAmphibious()) continue;
//     final Map<Territory, Collection<Unit>> attackingFromMap =
//         ((MustFightBattle) battle).getAttackingFromMap();
//     for (final Territory neighbor : ((MustFightBattle) battle).getAttackingFrom()) {
//       if (battleTracker.noBombardAllowedFromHere(neighbor)) continue;
//       final Collection<Unit> neighbourUnits = attackingFromMap.get(neighbor);
//       if (!neighbourUnits.isEmpty() && neighbourUnits.stream().allMatch(Matches.unitIsAir())) continue;
//       final Collection<IBattle> battles =
//           possibleBombardingTerritories.computeIfAbsent(neighbor, k -> new ArrayList<>());
//       battles.add(battle);
//     }
//   }
//   return possibleBombardingTerritories;
battle_delegate_get_possible_bombarding_territories :: proc(
	self: ^Battle_Delegate,
) -> map[^Territory][dynamic]^I_Battle {
	possible := make(map[^Territory][dynamic]^I_Battle)
	pending := battle_tracker_get_pending_battles_of_type(self.battle_tracker, .NORMAL)
	defer delete(pending)
	for battle in pending {
		ab := cast(^Abstract_Battle)battle
		// Java: `instanceof MustFightBattle`. NonFightingBattle also extends
		// DependentBattle and FinishedBattle has its own attackingFromMap, so
		// neither battle_type nor isAmphibious is sufficient — we use the
		// is_must_fight_battle discriminator that MFB constructors set.
		if !ab.is_must_fight_battle {
			continue
		}
		if !i_battle_is_amphibious(battle) {
			continue
		}
		mfb := cast(^Must_Fight_Battle)battle
		attacking_from := dependent_battle_get_attacking_from(&mfb.dependent_battle)
		defer delete(attacking_from)
		for neighbor in attacking_from {
			if battle_tracker_no_bombard_allowed_from_here(self.battle_tracker, neighbor) {
				continue
			}
			neighbour_units, has_units := mfb.attacking_from_map[neighbor]
			if has_units && len(neighbour_units) > 0 {
				all_air := true
				for u in neighbour_units {
					if !matches_pred_unit_is_air(nil, u) {
						all_air = false
						break
					}
				}
				if all_air {
					continue
				}
			}
			bucket, exists := possible[neighbor]
			if !exists {
				bucket = battle_delegate_lambda_get_possible_bombarding_territories_0(neighbor)
			}
			append(&bucket, battle)
			possible[neighbor] = bucket
		}
	}
	return possible
}

// games.strategy.triplea.delegate.battle.BattleDelegate#airBattleCleanup()
//   private void airBattleCleanup() {
//     final GameState data = getData();
//     if (!Properties.getRaidsMayBePreceededByAirBattles(data.getProperties())) return;
//     final CompositeChange change = new CompositeChange();
//     for (final Territory t : data.getMap().getTerritories()) {
//       for (final Unit u : t.getUnitCollection().getMatches(Matches.unitWasInAirBattle())) {
//         change.add(ChangeFactory.unitPropertyChange(u, false, Unit.PropertyName.WAS_IN_AIR_BATTLE));
//       }
//     }
//     if (!change.isEmpty()) {
//       bridge.getHistoryWriter().startEvent("Cleaning up after air battles");
//       bridge.addChange(change);
//     }
//   }
battle_delegate_air_battle_cleanup :: proc(self: ^Battle_Delegate) {
	data := i_delegate_bridge_get_data(self.bridge)
	if !properties_get_raids_may_be_preceeded_by_air_battles(game_data_get_properties(data)) {
		return
	}
	change := composite_change_new()
	for t in game_map_get_territories(game_state_get_map(&data.game_state)) {
		uc := territory_get_unit_collection(t)
		for u in unit_collection_get_units(uc) {
			if !matches_pred_unit_was_in_air_battle(nil, u) {
				continue
			}
			boxed := new(bool)
			boxed^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change_property_name(
					u,
					rawptr(boxed),
					.Was_In_Air_Battle,
				),
			)
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			"Cleaning up after air battles",
		)
		i_delegate_bridge_add_change(self.bridge, &change.change)
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#resetMaxScrambleCount(IDelegateBridge)
//   private static void resetMaxScrambleCount(final IDelegateBridge bridge) {
//     final GameState data = bridge.getData();
//     if (!Properties.getScrambleRulesInEffect(data.getProperties())) return;
//     final CompositeChange change = new CompositeChange();
//     for (final Territory t : data.getMap().getTerritories()) {
//       final Collection<Unit> airbases = t.getUnitCollection().getMatches(Matches.unitIsAirBase());
//       for (final Unit airbase : airbases) {
//         final UnitAttachment ua = airbase.getUnitAttachment();
//         final int currentMax = airbase.getMaxScrambleCount();
//         final int allowedMax = ua.getMaxScrambleCount();
//         if (currentMax != allowedMax) {
//           change.add(ChangeFactory.unitPropertyChange(
//               airbase, allowedMax, Unit.PropertyName.MAX_SCRAMBLE_COUNT));
//         }
//       }
//     }
//     if (!change.isEmpty()) {
//       bridge.getHistoryWriter().startEvent("Preparing Airbases for Possible Scrambling");
//       bridge.addChange(change);
//     }
//   }
battle_delegate_reset_max_scramble_count :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_scramble_rules_in_effect(game_data_get_properties(data)) {
		return
	}
	change := composite_change_new()
	for t in game_map_get_territories(game_state_get_map(&data.game_state)) {
		uc := territory_get_unit_collection(t)
		for airbase in unit_collection_get_units(uc) {
			if !matches_pred_unit_is_air_base(nil, airbase) {
				continue
			}
			ua := unit_get_unit_attachment(airbase)
			current_max := unit_get_max_scramble_count(airbase)
			allowed_max := unit_attachment_get_max_scramble_count(ua)
			if current_max != allowed_max {
				boxed := new(i32)
				boxed^ = allowed_max
				composite_change_add(
					change,
					change_factory_unit_property_change_property_name(
						airbase,
						rawptr(boxed),
						.Max_Scramble_Count,
					),
				)
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			"Preparing Airbases for Possible Scrambling",
		)
		i_delegate_bridge_add_change(bridge, &change.change)
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#selectBombardingBattle(Unit, Territory, Collection)
//   /** Select which territory to bombard. */
//   private IBattle selectBombardingBattle(
//       final Unit u, final Territory unitTerritory, final Collection<IBattle> battles) {
//     if (battles.size() == 1) return CollectionUtils.getAny(battles);
//     final List<Territory> territories = new ArrayList<>();
//     final Map<Territory, IBattle> battleTerritories = new HashMap<>();
//     for (final IBattle battle : battles) {
//       if (!Properties.getShoreBombardPerGroundUnitRestricted(getData().getProperties())
//           || (battle.getBombardingUnits().size()
//               < battle.getAttackingUnits().stream().filter(Matches.unitWasAmphibious()).count())) {
//         territories.add(battle.getTerritory());
//       }
//       battleTerritories.put(battle.getTerritory(), battle);
//     }
//     final Player remotePlayer = bridge.getRemotePlayer();
//     Territory bombardingTerritory = null;
//     if (!territories.isEmpty()) {
//       bombardingTerritory =
//           remotePlayer.selectBombardingTerritory(u, unitTerritory, territories, true);
//     }
//     if (bombardingTerritory != null) {
//       return battleTerritories.get(bombardingTerritory);
//     }
//     return null;
//   }
battle_delegate_select_bombarding_battle :: proc(
	self: ^Battle_Delegate,
	u: ^Unit,
	unit_territory: ^Territory,
	battles: [dynamic]^I_Battle,
) -> ^I_Battle {
	if len(battles) == 1 {
		return battles[0]
	}
	territories := make([dynamic]^Territory)
	battle_territories := make(map[^Territory]^I_Battle)
	restricted := properties_get_shore_bombard_per_ground_unit_restricted(
		game_data_get_properties(i_delegate_bridge_get_data(self.bridge)),
	)
	for battle in battles {
		bombarding_units := i_battle_get_bombarding_units(battle)
		attacking_units := i_battle_get_attacking_units(battle)
		amphib_count: i32 = 0
		for au in attacking_units {
			if matches_pred_unit_was_amphibious(nil, au) {
				amphib_count += 1
			}
		}
		if !restricted || i32(len(bombarding_units)) < amphib_count {
			append(&territories, i_battle_get_territory(battle))
		}
		battle_territories[i_battle_get_territory(battle)] = battle
	}
	remote_player := i_delegate_bridge_get_remote_player(self.bridge, nil)
	bombarding_territory: ^Territory = nil
	if len(territories) > 0 {
		bombarding_territory = player_select_bombarding_territory(
			remote_player,
			u,
			unit_territory,
			territories,
			true,
		)
	}
	if bombarding_territory != nil {
		return battle_territories[bombarding_territory]
	}
	return nil
}

// games.strategy.triplea.delegate.battle.BattleDelegate#markDamaged(Collection, IDelegateBridge, Territory)
//   public static void markDamaged(
//       final Collection<Unit> damaged, final IDelegateBridge bridge, final Territory territory) {
//     if (damaged.isEmpty()) return;
//     final IntegerMap<Unit> damagedMap = new IntegerMap<>();
//     for (final Unit u : damaged) damagedMap.add(u, 1);
//     HistoryChangeFactory.damageUnits(territory, damagedMap).perform(bridge);
//   }
battle_delegate_mark_damaged :: proc(
	damaged: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	territory: ^Territory,
) {
	if len(damaged) == 0 {
		return
	}
	damaged_map := new(Integer_Map_Unit)
	damaged_map.entries = make(map[^Unit]i32)
	for u in damaged {
		damaged_map.entries[u] = damaged_map.entries[u] + 1
	}
	damage_units_history_change_perform(
		history_change_factory_damage_units(territory, damaged_map),
		bridge,
	)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#addBombardmentSources()
// Java:
//   final GamePlayer attacker = bridge.getGamePlayer();
//   final Player remotePlayer = bridge.getRemotePlayer();
//   final Predicate<Unit> ownedAndCanBombard =
//       Matches.unitCanBombard(attacker).and(Matches.unitIsOwnedBy(attacker));
//   final Map<Territory, Collection<IBattle>> adjBombardment = getPossibleBombardingTerritories();
//   for (final Territory t : adjBombardment.keySet()) {
//     if (!battleTracker.hasPendingNonBombingBattle(t)) {
//       Collection<IBattle> battles = adjBombardment.get(t);
//       if (!battles.isEmpty()) {
//         final Collection<Unit> bombardUnits =
//             t.getUnitCollection().getMatches(ownedAndCanBombard);
//         final List<Unit> listedBombardUnits = new ArrayList<>(bombardUnits);
//         sortUnitsToBombard(listedBombardUnits);
//         if (!bombardUnits.isEmpty() && !remotePlayer.selectShoreBombard(t)) continue;
//         for (final Unit u : listedBombardUnits) {
//           final IBattle battle = selectBombardingBattle(u, t, battles);
//           if (battle != null) {
//             if (Properties.getShoreBombardPerGroundUnitRestricted(getData().getProperties())
//                 && battle.getAttackingUnits().stream()
//                        .filter(Matches.unitWasAmphibious()).count()
//                     <= battle.getBombardingUnits().size()) {
//               battles.remove(battle);
//               break;
//             }
//             battle.addBombardingUnit(u);
//           }
//         }
//       }
//     }
//   }
battle_delegate_add_bombardment_sources :: proc(self: ^Battle_Delegate) {
	attacker := i_delegate_bridge_get_game_player(self.bridge)
	remote_player := i_delegate_bridge_get_remote_player(self.bridge, nil)
	can_bombard_p, can_bombard_c := matches_unit_can_bombard(attacker)
	owned_p, owned_c := matches_unit_is_owned_by(attacker)
	adj_bombardment := battle_delegate_get_possible_bombarding_territories(self)
	for t in adj_bombardment {
		if battle_tracker_has_pending_non_bombing_battle(self.battle_tracker, t) {
			continue
		}
		battles := adj_bombardment[t]
		if len(battles) == 0 {
			continue
		}
		bombard_units: [dynamic]^Unit
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if can_bombard_p(can_bombard_c, u) && owned_p(owned_c, u) {
				append(&bombard_units, u)
			}
		}
		listed_bombard_units := bombard_units
		battle_delegate_sort_units_to_bombard(&listed_bombard_units)
		if len(bombard_units) > 0 && !player_select_shore_bombard(remote_player, t) {
			continue
		}
		for u in listed_bombard_units {
			battle := battle_delegate_select_bombarding_battle(self, u, t, battles)
			if battle != nil {
				if properties_get_shore_bombard_per_ground_unit_restricted(
					game_data_get_properties(i_delegate_bridge_get_data(self.bridge)),
				) {
					attacking_units := i_battle_get_attacking_units(battle)
					amphib_count: i64 = 0
					for au in attacking_units {
						if matches_pred_unit_was_amphibious(nil, au) {
							amphib_count += 1
						}
					}
					if amphib_count <= i64(len(i_battle_get_bombarding_units(battle))) {
						for b, idx in battles {
							if b == battle {
								ordered_remove(&battles, idx)
								break
							}
						}
						adj_bombardment[t] = battles
						break
					}
				}
				i_battle_add_bombarding_unit(battle, u)
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#lambda$doScrambling$4(GameData, Territory)
// Body of `from -> AbstractBattle.findDefender(from, player, data)` inside doScrambling
// (the `.map(...)` over the scramble-from territories used to determine the defender).
// `data` is captured locally, `player` is captured via `this`. Synthetic javac signature
// enumerates `(GameData, Territory)`; the implicit receiver is the Battle_Delegate.
battle_delegate_lambda_do_scrambling_4 :: proc(
	self: ^Battle_Delegate,
	data: ^Game_Data,
	from: ^Territory,
) -> ^Game_Player {
	return abstract_battle_find_defender(from, self.player, &data.game_state)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#landParatroopers(GamePlayer, Territory, IDelegateBridge)
// Java: private static. If the player has paratroopers tech, gather all air-transports
// and air-transportable units in the battle site; for every paratroop carried by one of
// those air transports, emit a TransportTracker.unloadAirTransportChange. Commit and
// log the resulting CompositeChange when non-empty.
battle_delegate_land_paratroopers :: proc(
	player: ^Game_Player,
	battle_site: ^Territory,
	bridge: ^I_Delegate_Bridge,
) {
	if !tech_tracker_has_paratroopers(player) {
		return
	}
	site_units := unit_collection_get_units(territory_get_unit_collection(battle_site))
	air_transports := make([dynamic]^Unit)
	paratroops := make([dynamic]^Unit)
	air_pred, air_ctx := matches_unit_is_air_transport()
	para_pred, para_ctx := matches_unit_is_air_transportable()
	for u in site_units {
		if air_pred(air_ctx, u) {
			append(&air_transports, u)
		}
		if para_pred(para_ctx, u) {
			append(&paratroops, u)
		}
	}
	if len(air_transports) == 0 || len(paratroops) == 0 {
		return
	}
	change := composite_change_new()
	for paratroop in paratroops {
		transport := unit_get_transported_by(paratroop)
		if transport == nil || !slice.contains(air_transports[:], transport) {
			continue
		}
		composite_change_add(
			change,
			transport_tracker_unload_air_transport_change(paratroop, battle_site, false),
		)
	}
	if !composite_change_is_empty(change) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			fmt.aprintf(
				"%s lands units in %s",
				default_named_get_name(&player.named_attachable.default_named),
				default_named_get_name(&battle_site.named_attachable.default_named),
			),
		)
		i_delegate_bridge_add_change(bridge, &change.change)
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#moveAirAndLand(IDelegateBridge, Collection<Unit>, Collection<Unit>, Territory, Territory)
// Java: private static. Records a "<units> forced to land in <newTerritory>" history
// child, applies a ChangeFactory.moveUnits(battleSite -> newTerritory) for the moved
// air, and removes those units from defendingAirTotal so successive callers see only
// the still-undecided survivors.
battle_delegate_move_air_and_land :: proc(
	bridge: ^I_Delegate_Bridge,
	defending_air_being_moved: ^[dynamic]^Unit,
	defending_air_total: ^[dynamic]^Unit,
	new_territory: ^Territory,
	battle_site: ^Territory,
) {
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	msg := fmt.aprintf(
		"%s forced to land in %s",
		my_formatter_units_to_text(defending_air_being_moved^),
		default_named_get_name(&new_territory.named_attachable.default_named),
	)
	history_writer_add_child_to_event(history_writer, msg)
	change := change_factory_move_units(battle_site, new_territory, defending_air_being_moved^)
	i_delegate_bridge_add_change(bridge, change)
	// removeAll(defendingAirBeingMoved): rebuild defendingAirTotal without those units.
	keep := make([dynamic]^Unit)
	for u in defending_air_total {
		if !slice.contains(defending_air_being_moved[:], u) {
			append(&keep, u)
		}
	}
	delete(defending_air_total^)
	defending_air_total^ = keep
}

// games.strategy.triplea.delegate.battle.BattleDelegate#landPlanesOnCarriers(IDelegateBridge, Predicate<Unit>, Collection<Unit>, Predicate<Unit>, Predicate<Unit>, Territory, Territory)
// Java: private static. Compute the free carrier capacity in newTerritory
// (carrierCapacity(allied carriers there) - carrierCost(allied planes there)),
// then take up to that many of the still-defending air units that match
// alliedDefendingAir and hand them to moveAirAndLand for the actual landing.
// Assumes each defending air unit costs 1 carrier slot (matches Java's TODO).
battle_delegate_land_planes_on_carriers :: proc(
	bridge: ^I_Delegate_Bridge,
	allied_defending_air: proc(^Unit) -> bool,
	defending_air: ^[dynamic]^Unit,
	allied_carrier: proc(^Unit) -> bool,
	allied_plane: proc(^Unit) -> bool,
	new_territory: ^Territory,
	battle_site: ^Territory,
) {
	new_uc := territory_get_unit_collection(new_territory)
	allied_carriers_selected := unit_collection_get_matches(new_uc, allied_carrier)
	allied_planes_selected := unit_collection_get_matches(new_uc, allied_plane)
	allied_carrier_capacity_selected := air_movement_validator_carrier_capacity(
		allied_carriers_selected[:],
		new_territory,
	)
	allied_plane_cost_selected := air_movement_validator_carrier_cost(
		allied_planes_selected[:],
	)
	territory_capacity := allied_carrier_capacity_selected - allied_plane_cost_selected
	if territory_capacity > 0 {
		// CollectionUtils.getNMatches(defendingAir, territoryCapacity, alliedDefendingAir)
		moving_air := make([dynamic]^Unit)
		count: i32 = 0
		for u in defending_air {
			if count >= territory_capacity {
				break
			}
			if allied_defending_air(u) {
				append(&moving_air, u)
				count += 1
			}
		}
		battle_delegate_move_air_and_land(
			bridge,
			&moving_air,
			defending_air,
			new_territory,
			battle_site,
		)
	}
}

// File-private trampoline used to feed our rawptr-ctx Predicate<Territory>
// instances through `game_map_get_route_for_unit`, which takes a non-ctx
// `proc(^Territory) -> bool`. Same pattern as `pro_move_utils_active_cond`
// in pro_move_utils.odin: each `whereCanAirLand` call sets the holders,
// performs the synchronous route lookup, then proceeds. Single-threaded.
@(private = "file")
battle_delegate_active_route_cond: proc(rawptr, ^Territory) -> bool

@(private = "file")
battle_delegate_active_route_cond_ctx: rawptr

@(private = "file")
battle_delegate_route_cond_trampoline :: proc(t: ^Territory) -> bool {
	return battle_delegate_active_route_cond(battle_delegate_active_route_cond_ctx, t)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#whereCanAirLand(Unit, Territory, GamePlayer, GameState, BattleTracker, int)
//   Java: private static. Returns the set of allied land/sea territories
//   into which `strandedAir` can fly, given its scramble distance, the
//   current set of pending battle sites, and the carrier capacity already
//   consumed in `currentTerr`. Mirrors the Java line-by-line:
//     - maxDistance == 0 ⇒ {currentTerr}
//     - candidate territories = neighbors-by-movement-cost(currentTerr,
//       maxDistance, airCanFlyOver)
//     - filter candidates by an actual route existing within maxDistance
//     - + currentTerr
//     - keep allied-land minus pending-battle-or-enemy-units sites
//     - if strandedAir can land on a carrier, additionally union sea
//       territories whose carrier capacity (after subtracting allied air
//       already there, or carrierCostForCurrentTerr at currentTerr) is
//       large enough to receive `strandedAir`'s carrierCost
//   `Set<Territory>` is rendered as `[dynamic]^Territory` with explicit
//   no-duplicate insertion (matches HashSet semantics observed by callers
//   that only use size()/contains()/getAny()).
battle_delegate_where_can_air_land :: proc(
	stranded_air: ^Unit,
	current_terr: ^Territory,
	allied_player: ^Game_Player,
	data: ^Game_State,
	battle_tracker: ^Battle_Tracker,
	carrier_cost_for_current_terr: i32,
) -> [dynamic]^Territory {
	assert(stranded_air != nil)
	max_distance := unit_attachment_get_max_scramble_distance(unit_get_unit_attachment(stranded_air))
	if max_distance <= 0 {
		out := make([dynamic]^Territory)
		append(&out, current_terr)
		return out
	}
	props := game_state_get_properties(data)
	are_neutrals_passable_by_air :=
		properties_get_neutral_flyover_allowed(props) &&
		!properties_get_neutrals_impassable(props)
	// canNotLand = pendingBattleSitesWithoutBombing ∪ territoriesWithEnemyUnits(alliedPlayer)
	can_not_land := make(map[^Territory]struct{})
	for t in battle_tracker_get_pending_battle_sites_without_bombing(battle_tracker) {
		can_not_land[t] = {}
	}
	{
		enemy_p, enemy_c := matches_territory_has_enemy_units(allied_player)
		for t in game_map_get_territories(game_state_get_map(data)) {
			if enemy_p(enemy_c, t) {
				can_not_land[t] = {}
			}
		}
	}
	gm := game_state_get_map(data)
	fly_p, fly_c := matches_air_can_fly_over(allied_player, are_neutrals_passable_by_air)
	possible_set := game_map_get_neighbors_by_movement_cost(
		gm,
		current_terr,
		f64(max_distance),
		fly_p,
		fly_c,
	)
	// Materialise to a [dynamic] so we can drop entries while iterating
	// (Java uses an Iterator with .remove()).
	possible_terrs := make([dynamic]^Territory)
	for t in possible_set {
		append(&possible_terrs, t)
	}
	// Filter by route existence and total movement cost ≤ maxDistance.
	battle_delegate_active_route_cond = fly_p
	battle_delegate_active_route_cond_ctx = fly_c
	max_cost_f := f64(max_distance)
	kept := make([dynamic]^Territory)
	for candidate in possible_terrs {
		route := game_map_get_route_for_unit(
			gm,
			current_terr,
			candidate,
			battle_delegate_route_cond_trampoline,
			stranded_air,
			allied_player,
		)
		if route == nil {
			continue
		}
		if route_get_movement_cost(route, stranded_air) > max_cost_f {
			continue
		}
		append(&kept, candidate)
	}
	delete(possible_terrs)
	possible_terrs = kept
	// possibleTerrs.add(currentTerr)
	already_has_current := false
	for t in possible_terrs {
		if t == current_terr {
			already_has_current = true
			break
		}
	}
	if !already_has_current {
		append(&possible_terrs, current_terr)
	}
	// availableLand = possibleTerrs ∩ (alliedLand) − canNotLand
	allied_p, allied_c := matches_is_territory_allied(allied_player)
	land_p, land_c := matches_territory_is_land()
	where_can_land := make([dynamic]^Territory)
	seen := make(map[^Territory]struct{})
	defer delete(seen)
	for t in possible_terrs {
		if !allied_p(allied_c, t) {
			continue
		}
		if !land_p(land_c, t) {
			continue
		}
		if _, blocked := can_not_land[t]; blocked {
			continue
		}
		if _, dup := seen[t]; dup {
			continue
		}
		seen[t] = {}
		append(&where_can_land, t)
	}
	// Carrier-air-landing branch: only for units that can land on carriers.
	can_land_carrier_p, can_land_carrier_c := matches_unit_can_land_on_carrier()
	if can_land_carrier_p(can_land_carrier_c, stranded_air) {
		allied_carrier_p, allied_carrier_c := matches_unit_is_allied_carrier(allied_player)
		water_p, water_c := matches_territory_is_water()
		// availableWater = territories that have allied carriers and are water
		available_water := make([dynamic]^Territory)
		water_seen := make(map[^Territory]struct{})
		defer delete(water_seen)
		for t in possible_terrs {
			if !water_p(water_c, t) {
				continue
			}
			has_allied_carrier := false
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				if allied_carrier_p(allied_carrier_c, u) {
					has_allied_carrier = true
					break
				}
			}
			if !has_allied_carrier {
				continue
			}
			if _, dup := water_seen[t]; dup {
				continue
			}
			water_seen[t] = {}
			append(&available_water, t)
		}
		// availableWater.removeAll(pendingBattleSitesWithoutBombing)
		pending := battle_tracker_get_pending_battle_sites_without_bombing(battle_tracker)
		filtered_water := make([dynamic]^Territory)
		for t in available_water {
			if _, in_pending := pending[t]; in_pending {
				continue
			}
			append(&filtered_water, t)
		}
		delete(available_water)
		available_water = filtered_water
		// Carrier-capacity feasibility per water territory.
		carrier_cost := air_movement_validator_carrier_cost_unit(stranded_air)
		ally_unit_p, ally_unit_c := matches_allied_unit(allied_player)
		final_water := make([dynamic]^Territory)
		for t in available_water {
			uc := territory_get_unit_collection(t)
			carriers_here := make([dynamic]^Unit)
			for u in unit_collection_get_units(uc) {
				if allied_carrier_p(allied_carrier_c, u) {
					append(&carriers_here, u)
				}
			}
			carrier_capacity := air_movement_validator_carrier_capacity(carriers_here[:], t)
			delete(carriers_here)
			if t != current_terr {
				existing_air := make([dynamic]^Unit)
				for u in unit_collection_get_units(uc) {
					if can_land_carrier_p(can_land_carrier_c, u) && ally_unit_p(ally_unit_c, u) {
						append(&existing_air, u)
					}
				}
				carrier_capacity -= air_movement_validator_carrier_cost(existing_air[:])
				delete(existing_air)
			} else {
				carrier_capacity -= carrier_cost_for_current_terr
			}
			if carrier_capacity < carrier_cost {
				continue
			}
			append(&final_water, t)
		}
		delete(available_water)
		// whereCanLand.addAll(availableWater)
		for t in final_water {
			if _, dup := seen[t]; dup {
				continue
			}
			seen[t] = {}
			append(&where_can_land, t)
		}
		delete(final_water)
	}
	delete(possible_terrs)
	delete(can_not_land)
	return where_can_land
}

// games.strategy.triplea.delegate.battle.BattleDelegate#checkDefendingPlanesCanLand()
//   Java: private. For every battle site whose defending air "could not
//   land" (recorded by BattleTracker during the resolved battle), tries
//   to relocate the survivors to an adjacent allied land territory or a
//   sea zone with free carrier capacity. WW2v2 / "surviving air may move
//   to land" rules let the human/AI player choose; otherwise we only
//   move air onto single-hex islands. Anything still stranded at the end
//   is destroyed and a history child records the loss.
//
//   The Java code mutates `defendingAir` in-place via Iterator.remove
//   inside `moveAirAndLand` and shared-Collection retainAll; we mirror
//   that with `^[dynamic]^Unit` parameters and an explicit retain-pass
//   against `battleSite.getUnitCollection()`.
//
//   landPlanesOnCarriers is intentionally inlined here: the existing
//   `battle_delegate_land_planes_on_carriers` helper consumes non-ctx
//   `proc(^Unit) -> bool` predicates, but the predicates needed here
//   (`alliedDefendingAir`, `alliedCarrier`, `alliedPlane`) all capture
//   `defender`, so they are constructed fresh per battle-site and the
//   capacity / cost calculation is performed in line.
battle_delegate_check_defending_planes_can_land :: proc(self: ^Battle_Delegate) {
	data := i_delegate_bridge_get_data(self.bridge)
	defending_air_that_can_not_land := battle_tracker_get_defending_air_that_can_not_land(self.battle_tracker)
	props := game_data_get_properties(data)
	is_ww2v2_or_surviving_air :=
		properties_get_ww2_v2(props) || properties_get_surviving_air_move_to_land(props)
	air_p, air_c := matches_unit_is_air()
	scrambled_p, scrambled_c := matches_unit_was_scrambled()
	for battle_site, defending_air_orig in defending_air_that_can_not_land {
		if defending_air_orig == nil || len(defending_air_orig) == 0 {
			continue
		}
		// retainAll(battleSite.getUnitCollection())
		bs_uc := territory_get_unit_collection(battle_site)
		bs_units := unit_collection_get_units(bs_uc)
		defending_air := make([dynamic]^Unit)
		for u in defending_air_orig {
			if slice.contains(bs_units[:], u) {
				append(&defending_air, u)
			}
		}
		if len(defending_air) == 0 {
			continue
		}
		defender := abstract_battle_find_defender(battle_site, self.player, &data.game_state)
		neighbors := game_map_get_neighbors(game_state_get_map(&data.game_state), battle_site)
		// canLandHere = neighbors filtered by airCanLandOnThisAlliedNonConqueredLandTerritory(defender)
		ald_p, ald_c := matches_air_can_land_on_this_allied_non_conquered_land_territory(defender)
		can_land_here := make([dynamic]^Territory)
		for t in neighbors {
			if ald_p(ald_c, t) {
				append(&can_land_here, t)
			}
		}
		// areSeaNeighbors = neighbors filtered by water AND territoryHasAlliedUnits(defender)
		water_p, water_c := matches_territory_is_water()
		has_allied_p, has_allied_c := matches_territory_has_allied_units(defender)
		are_sea_neighbors := make([dynamic]^Territory)
		for t in neighbors {
			if water_p(water_c, t) && has_allied_p(has_allied_c, t) {
				append(&are_sea_neighbors, t)
			}
		}
		// alliedCarrier = unitIsCarrier ∧ alliedUnit(defender)
		// alliedPlane   = unitIsAir     ∧ alliedUnit(defender)
		carrier_p, carrier_c := matches_unit_is_carrier()
		ally_unit_p, ally_unit_c := matches_allied_unit(defender)
		// Augment canLandHere with sea zones that have free carrier capacity.
		for current_territory in are_sea_neighbors {
			uc := territory_get_unit_collection(current_territory)
			allied_carriers := make([dynamic]^Unit)
			allied_planes := make([dynamic]^Unit)
			for u in unit_collection_get_units(uc) {
				if carrier_p(carrier_c, u) && ally_unit_p(ally_unit_c, u) {
					append(&allied_carriers, u)
				}
				if air_p(air_c, u) && ally_unit_p(ally_unit_c, u) {
					append(&allied_planes, u)
				}
			}
			capacity := air_movement_validator_carrier_capacity(allied_carriers[:], current_territory)
			cost := air_movement_validator_carrier_cost(allied_planes[:])
			delete(allied_carriers)
			delete(allied_planes)
			if capacity - cost >= 1 {
				append(&can_land_here, current_territory)
			}
		}
		delete(are_sea_neighbors)
		if is_ww2v2_or_surviving_air {
			for len(can_land_here) > 1 && len(defending_air) > 0 {
				remote := i_delegate_bridge_get_remote_player(self.bridge, defender)
				prompt := fmt.aprintf(
					"Select territory for air units to land. (Current territory is %s): %s",
					default_named_get_name(&battle_site.named_attachable.default_named),
					my_formatter_units_to_text(defending_air),
				)
				territory := player_select_territory_for_air_to_land(
					remote,
					can_land_here,
					battle_site,
					prompt,
				)
				if territory == nil {
					territory = can_land_here[0]
				}
				if territory_is_water(territory) {
					battle_delegate_check_defending_planes_land_on_carriers(
						self.bridge,
						defender,
						&defending_air,
						territory,
						battle_site,
					)
				} else {
					battle_delegate_move_air_and_land(
						self.bridge,
						&defending_air,
						&defending_air,
						territory,
						battle_site,
					)
					continue
				}
				// canLandHere.remove(territory)
				for i in 0 ..< len(can_land_here) {
					if can_land_here[i] == territory {
						ordered_remove(&can_land_here, i)
						break
					}
				}
			}
			// Land in the last remaining territory.
			if len(can_land_here) > 0 && len(defending_air) > 0 {
				territory := can_land_here[0]
				if territory_is_water(territory) {
					battle_delegate_check_defending_planes_land_on_carriers(
						self.bridge,
						defender,
						&defending_air,
						territory,
						battle_site,
					)
				} else {
					battle_delegate_move_air_and_land(
						self.bridge,
						&defending_air,
						&defending_air,
						territory,
						battle_site,
					)
				}
			}
		} else if len(can_land_here) > 0 {
			// Look for an island in this sea zone (single-neighbor land).
			for current_territory in can_land_here {
				if len(game_map_get_neighbors(game_state_get_map(&data.game_state), current_territory)) == 1 {
					battle_delegate_move_air_and_land(
						self.bridge,
						&defending_air,
						&defending_air,
						current_territory,
						battle_site,
					)
				}
			}
		}
		delete(can_land_here)
		if len(defending_air) > 0 {
			// Nowhere to go, they must die.
			history_writer := i_delegate_bridge_get_history_writer(self.bridge)
			msg := fmt.aprintf(
				"%s could not land and were killed",
				my_formatter_units_to_text(defending_air),
			)
			i_delegate_history_writer_start_event(history_writer, msg)
			change := change_factory_remove_units(cast(^Unit_Holder)battle_site, defending_air)
			i_delegate_bridge_add_change(self.bridge, change)
		}
	}
}

// File-private helper invoked from `battle_delegate_check_defending_planes_can_land`
// to land planes on allied carriers in `new_territory`. Mirrors Java's
// `landPlanesOnCarriers` but the predicates close over `defender`, so we
// build them here from the `matches_*` factories rather than reusing
// `battle_delegate_land_planes_on_carriers` (which takes non-ctx procs).
@(private = "file")
battle_delegate_check_defending_planes_land_on_carriers :: proc(
	bridge: ^I_Delegate_Bridge,
	defender: ^Game_Player,
	defending_air: ^[dynamic]^Unit,
	new_territory: ^Territory,
	battle_site: ^Territory,
) {
	air_p, air_c := matches_unit_is_air()
	scrambled_p, scrambled_c := matches_unit_was_scrambled()
	carrier_p, carrier_c := matches_unit_is_carrier()
	ally_unit_p, ally_unit_c := matches_allied_unit(defender)
	new_uc := territory_get_unit_collection(new_territory)
	allied_carriers := make([dynamic]^Unit)
	allied_planes := make([dynamic]^Unit)
	for u in unit_collection_get_units(new_uc) {
		if carrier_p(carrier_c, u) && ally_unit_p(ally_unit_c, u) {
			append(&allied_carriers, u)
		}
		if air_p(air_c, u) && ally_unit_p(ally_unit_c, u) {
			append(&allied_planes, u)
		}
	}
	capacity := air_movement_validator_carrier_capacity(allied_carriers[:], new_territory)
	cost := air_movement_validator_carrier_cost(allied_planes[:])
	delete(allied_carriers)
	delete(allied_planes)
	territory_capacity := capacity - cost
	if territory_capacity > 0 {
		// CollectionUtils.getNMatches(defendingAir, territoryCapacity, alliedDefendingAir)
		moving_air := make([dynamic]^Unit)
		count: i32 = 0
		for u in defending_air {
			if count >= territory_capacity {
				break
			}
			if air_p(air_c, u) && !scrambled_p(scrambled_c, u) {
				append(&moving_air, u)
				count += 1
			}
		}
		battle_delegate_move_air_and_land(
			bridge,
			&moving_air,
			defending_air,
			new_territory,
			battle_site,
		)
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#fireKamikazeSuicideAttacks(
//   Unit, IntegerMap<Resource>, IntegerMap<Resource>, GamePlayer, Territory)
//
// Faithful port of the private instance method. Rolls dice (low-luck or
// normal) for one attacked unit, applies hits as damage or removal,
// charges the firing player's resources, blocks bombarding from the sea
// zone for the rest of the turn, and broadcasts the result to the two
// players involved.
battle_delegate_fire_kamikaze_suicide_attacks :: proc(
	self: ^Battle_Delegate,
	unit_under_fire: ^Unit,
	number_of_attacks: Integer_Map_Resource,
	resources_and_attack_values: Integer_Map_Resource,
	firing_enemy: ^Game_Player,
	location: ^Territory,
) {
	// TODO: find a way to autosave after each dice roll. (Java comment carried over)
	data := i_delegate_bridge_get_data(self.bridge)
	dice_sides := data.dice_sides
	change := composite_change_new()
	hits: i32 = 0
	rolls: [dynamic]i32
	rolls_present := false
	if properties_get_low_luck(game_data_get_properties(data)) {
		power: i32 = 0
		for r, num in number_of_attacks {
			composite_change_add(
				change,
				change_factory_change_resources_change(firing_enemy, r, -num),
			)
			power += num * resources_and_attack_values[r]
		}
		if power > 0 {
			hits = power / dice_sides
			remainder := power % dice_sides
			if remainder > 0 {
				annotation := fmt.aprintf(
					"Rolling for remainder in Kamikaze Suicide Attack on unit: %s",
					unit_get_type(unit_under_fire).named.base.name,
				)
				rolls = i_delegate_bridge_get_random(
					self.bridge,
					dice_sides,
					1,
					firing_enemy,
					I_Random_Stats_Dice_Type.COMBAT,
					annotation,
				)
				rolls_present = true
				if remainder > rolls[0] {
					hits += 1
				}
			}
		}
	} else {
		// avoid multiple calls of getRandom, so just do it once at the beginning
		num_tokens: i32 = 0
		for _, n in number_of_attacks {
			num_tokens += n
		}
		annotation := fmt.aprintf(
			"Rolling for Kamikaze Suicide Attack on unit: %s",
			unit_get_type(unit_under_fire).named.base.name,
		)
		rolls = i_delegate_bridge_get_random(
			self.bridge,
			dice_sides,
			num_tokens,
			firing_enemy,
			I_Random_Stats_Dice_Type.COMBAT,
			annotation,
		)
		rolls_present = true
		power_of_tokens := make([]i32, num_tokens)
		defer delete(power_of_tokens)
		j: i32 = 0
		for r, n in number_of_attacks {
			composite_change_add(
				change,
				change_factory_change_resources_change(firing_enemy, r, -n),
			)
			power := resources_and_attack_values[r]
			num := n
			for num > 0 {
				power_of_tokens[j] = power
				j += 1
				num -= 1
			}
		}
		for i in 0 ..< len(rolls) {
			if power_of_tokens[i] > rolls[i] {
				hits += 1
			}
		}
	}
	// title: Set.of(unitUnderFire) → single-element collection.
	one_unit := make([dynamic]^Unit)
	defer delete(one_unit)
	append(&one_unit, unit_under_fire)
	title := fmt.aprintf(
		"Kamikaze Suicide Attack attacks %s",
		my_formatter_units_to_text(one_unit),
	)
	rolls_slice: []i32 = nil
	if rolls_present {
		rolls_slice = rolls[:]
	}
	dice_str := fmt.aprintf(
		" scoring %d hits.  Rolls: %s",
		hits,
		my_formatter_as_dice_ints(rolls_slice),
	)
	full_msg := fmt.aprintf("%s%s", title, dice_str)
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		full_msg,
		rawptr(unit_under_fire),
	)
	if hits > 0 {
		ua := unit_get_unit_attachment(unit_under_fire)
		current_hits := unit_get_hits(unit_under_fire)
		if unit_attachment_get_hit_points(ua) <= current_hits + hits {
			killed := make([dynamic]^Unit)
			append(&killed, unit_under_fire)
			remove_units_history_change_perform(
				history_change_factory_remove_units_from_territory(location, killed),
				self.bridge,
			)
		} else {
			damage_map := new(Integer_Map_Unit)
			damage_map.entries = make(map[^Unit]i32)
			damage_map.entries[unit_under_fire] = hits
			damage_units_history_change_perform(
				history_change_factory_damage_units(location, damage_map),
				self.bridge,
			)
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(self.bridge, &change.change)
	}
	// kamikaze suicide attacks, even if unsuccessful, deny the ability to
	// bombard from this sea zone.
	battle_tracker_add_no_bombard_allowed_from_here(self.battle_tracker, location)
	// TODO: display this as actual dice for both players (Java comment carried over)
	players_involved := make([dynamic]^Game_Player)
	append(&players_involved, self.player)
	append(&players_involved, firing_enemy)
	excluded := make([dynamic]^Game_Player)
	display := i_delegate_bridge_get_display_channel_broadcaster(self.bridge)
	i_display_report_message_to_players(
		display,
		players_involved,
		excluded,
		full_msg,
		title,
	)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#setupTerritoriesAbandonedToTheEnemy(
//   BattleTracker, IDelegateBridge)
//
// Set up the battles where we have abandoned a contested territory during
// combat move to the enemy. The enemy then takes over the territory in
// question. Faithful port of the private static method.
battle_delegate_setup_territories_abandoned_to_the_enemy :: proc(
	battle_tracker: ^Battle_Tracker,
	bridge: ^I_Delegate_Bridge,
) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_abandoned_territories_may_be_taken_over_immediately(
		game_data_get_properties(data),
	) {
		return
	}
	player := i_delegate_bridge_get_game_player(bridge)
	not_unowned_p, not_unowned_c := matches_territory_is_not_unowned_water()
	can_capture_p, can_capture_c :=
		matches_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy(player)
	// CollectionUtils.getMatches(territories, p1.and(p2)).
	battle_territories := make([dynamic]^Territory)
	defer delete(battle_territories)
	for t in game_map_get_territories(game_state_get_map(&data.game_state)) {
		if not_unowned_p(not_unowned_c, t) && can_capture_p(can_capture_c, t) {
			append(&battle_territories, t)
		}
	}
	// all territories that contain enemy units, where the territory is owned
	// by an enemy of these units.
	for territory in battle_territories {
		// abandonedToUnits = territory.getUnitCollection().getMatches(Matches.enemyUnit(player))
		en_p, en_c := matches_enemy_unit(player)
		territory_units := unit_collection_get_units(territory_get_unit_collection(territory))
		abandoned_to_units := make([dynamic]^Unit)
		for u in territory_units {
			if en_p(en_c, u) {
				append(&abandoned_to_units, u)
			}
		}
		abandoned_to_player := unit_utils_find_player_with_most_units(abandoned_to_units)

		// Add transport-dependents: for any abandoned-to unit that is itself a
		// transport, include the units it carries (deduped, skipping any
		// already present in the abandoned-to list).
		transport_map := transport_tracker_transporting(territory_units)
		to_add := make(map[^Unit]struct{})
		defer delete(to_add)
		for transport, transported in transport_map {
			in_abandoned := false
			for au in abandoned_to_units {
				if au == transport {
					in_abandoned = true
					break
				}
			}
			if !in_abandoned {
				continue
			}
			for tu in transported {
				already := false
				for au in abandoned_to_units {
					if au == tu {
						already = true
						break
					}
				}
				if !already {
					to_add[tu] = struct{}{}
				}
			}
		}
		for u, _ in to_add {
			append(&abandoned_to_units, u)
		}

		// either we have abandoned the territory (no more enemy units of our
		// enemy units) or we are possibly bombing the territory (so we may
		// have units there still).
		enemy_units_of_abandoned := make(map[^Unit]struct{})
		defer delete(enemy_units_of_abandoned)
		for au in abandoned_to_units {
			p := unit_get_owner(au)
			eo_p, eo_c := matches_unit_is_enemy_of(p)
			na_p, na_c := matches_unit_is_not_air()
			ni_p, ni_c := matches_unit_is_not_infrastructure()
			for u in territory_units {
				if eo_p(eo_c, u) && na_p(na_c, u) && ni_p(ni_c, u) {
					enemy_units_of_abandoned[u] = struct{}{}
				}
			}
		}
		// only look at bombing battles, because otherwise the normal attack
		// will determine the ownership of the territory.
		bombing_battle := battle_tracker_get_pending_bombing_battle(battle_tracker, territory)
		if bombing_battle != nil {
			for u in i_battle_get_attacking_units(bombing_battle) {
				delete_key(&enemy_units_of_abandoned, u)
			}
		}
		if len(enemy_units_of_abandoned) != 0 {
			continue
		}
		non_fighting_battle := battle_tracker_get_pending_battle(
			battle_tracker,
			territory,
			.NORMAL,
		)
		if non_fighting_battle != nil {
			fmt.panicf(
				"Should not be possible to have a normal battle in: %s and have abandoned or only bombing there too.",
				territory.named.base.name,
			)
		}
		history_writer := i_delegate_bridge_get_history_writer(bridge)
		msg := fmt.aprintf(
			"%s has abandoned %s to %s",
			player.named.base.name,
			territory.named.base.name,
			abandoned_to_player.named.base.name,
		)
		i_delegate_history_writer_start_event(history_writer, msg, rawptr(&abandoned_to_units))
		battle_tracker_take_over(
			battle_tracker,
			territory,
			abandoned_to_player,
			bridge,
			nil,
			abandoned_to_units,
		)
		// TODO: if there are multiple defending unit owners, allow picking
		// which one takes over the territory. (Java comment carried over.)
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#doKamikazeSuicideAttacks()
// KamikazeSuicideAttacks: enemies of the current player decide attacks against
// the current player's units in any kamikaze-zone territory whose owner is an
// enemy of the current player; resources from PlayerAttachment fund the
// targeted attacks. Faithful port of the Java instance method.
battle_delegate_do_kamikaze_suicide_attacks :: proc(self: ^Battle_Delegate) {
	data := i_delegate_bridge_get_data(self.bridge)
	properties := game_data_get_properties(data)
	if !properties_get_use_kamikaze_suicide_attacks(properties) {
		return
	}
	// the current player is not the one who is doing these attacks; it is the
	// enemies of this player who will do attacks.
	is_at_war_pred, is_at_war_ctx := matches_is_at_war(self.player)
	enemies: [dynamic]^Game_Player
	for p in player_list_get_players(game_data_get_player_list(data)) {
		if is_at_war_pred(is_at_war_ctx, p) {
			append(&enemies, p)
		}
	}
	if len(enemies) == 0 {
		return
	}
	// canBeAttackedDefault = unitIsOwnedBy(player) AND unitIsSea() AND
	//   unitIsNotSeaTransportButCouldBeCombatSeaTransport() AND unitCanEvade().negate()
	owned_pred, owned_ctx := matches_unit_is_owned_by(self.player)
	sea_pred, sea_ctx := matches_unit_is_sea()
	not_st_pred, not_st_ctx := matches_unit_is_not_sea_transport_but_could_be_combat_sea_transport()
	evade_pred, evade_ctx := matches_unit_can_evade()

	only_where_battles := properties_get_kamikaze_suicide_attacks_only_where_battles_are(
		properties,
	)
	pending_battles := battle_tracker_get_pending_battle_sites_without_bombing(
		self.battle_tracker,
	)
	done_by_current_owner := properties_get_kamikaze_suicide_attacks_done_by_current_territory_owner(
		properties,
	)

	// kamikazeZonesByEnemy: enemy → list of kamikaze territories.
	kamikaze_zones_by_enemy := make(map[^Game_Player][dynamic]^Territory)
	game_map := game_data_get_map(data)
	for t in game_map_get_territories(game_map) {
		ta := territory_attachment_get(t)
		if ta == nil || !territory_attachment_get_kamikaze_zone(ta) {
			continue
		}
		owner: ^Game_Player
		if !done_by_current_owner {
			owner = territory_attachment_get_original_owner(ta)
		} else {
			owner = territory_get_owner(t)
		}
		if owner == nil {
			continue
		}
		is_enemy := false
		for e in enemies {
			if e == owner {
				is_enemy = true
				break
			}
		}
		if !is_enemy {
			continue
		}
		// require at least one current-player-owned unit in the territory
		any_player_owned := false
		for u in unit_collection_get_units(territory_get_unit_collection(t)) {
			if owned_pred(owned_ctx, u) {
				any_player_owned = true
				break
			}
		}
		if !any_player_owned {
			continue
		}
		// if no battle or amphibious from here, ignore it
		if only_where_battles {
			_, in_pending := pending_battles[t]
			if !in_pending {
				water_pred, water_ctx := matches_territory_is_water()
				if !water_pred(water_ctx, t) {
					continue
				}
				amphib := false
				land_pred, land_ctx := matches_territory_is_land()
				land_neighbors := game_map_get_neighbors_predicate(
					game_map,
					t,
					land_pred,
					land_ctx,
				)
				for neighbor in land_neighbors {
					battle := battle_tracker_get_pending_battle(
						self.battle_tracker,
						neighbor,
						.NORMAL,
					)
					if battle == nil {
						finished := battle_tracker_get_finished_battles_unit_attack_from_map(
							self.battle_tracker,
						)
						if where_from, ok := finished[neighbor]; ok {
							if _, has_t := where_from[t]; has_t {
								amphib = true
								break
							}
						}
						continue
					}
					if i_battle_is_amphibious(battle) {
						// MustFightBattle / NonFightingBattle both extend
						// DependentBattle (see scramble_logic.odin for the
						// same unchecked-cast pattern).
						db := cast(^Dependent_Battle)battle
						amphib_terrs := dependent_battle_get_amphibious_attack_territories(db)
						for at in amphib_terrs {
							if at == t {
								amphib = true
								break
							}
						}
						if amphib {
							break
						}
					}
				}
				if !amphib {
					continue
				}
			}
		}
		list, ok := kamikaze_zones_by_enemy[owner]
		if !ok {
			list = make([dynamic]^Territory)
		}
		append(&list, t)
		kamikaze_zones_by_enemy[owner] = list
	}
	if len(kamikaze_zones_by_enemy) == 0 {
		return
	}
	for current_enemy, kamikaze_zones in kamikaze_zones_by_enemy {
		pa := player_attachment_get(current_enemy)
		if pa == nil {
			continue
		}
		suicide_attack_targets := player_attachment_get_suicide_attack_targets(pa)
		use_targets := len(suicide_attack_targets) > 0
		of_types_pred: proc(rawptr, ^Unit) -> bool
		of_types_ctx: rawptr
		if use_targets {
			of_types_pred, of_types_ctx = matches_unit_is_of_types(suicide_attack_targets)
		}
		// See if the player has any attack tokens.
		resources_and_attack_values := player_attachment_get_suicide_attack_resources(pa)
		if len(resources_and_attack_values) == 0 {
			continue
		}
		player_resource_collection := resource_collection_get_resources_copy(
			game_player_get_resources(current_enemy),
		)
		attack_tokens := make(Integer_Map_Resource)
		for possible, _ in resources_and_attack_values {
			amount := player_resource_collection[possible]
			if amount > 0 {
				attack_tokens[possible] = amount
			}
		}
		if len(attack_tokens) == 0 {
			continue
		}
		// Now let the enemy decide if they will do attacks.
		possible_units_to_attack := make(map[^Territory][dynamic]^Unit)
		for t in kamikaze_zones {
			valid_targets: [dynamic]^Unit
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				if use_targets {
					if !owned_pred(owned_ctx, u) {
						continue
					}
					if !of_types_pred(of_types_ctx, u) {
						continue
					}
				} else {
					if !owned_pred(owned_ctx, u) {
						continue
					}
					if !sea_pred(sea_ctx, u) {
						continue
					}
					if !not_st_pred(not_st_ctx, u) {
						continue
					}
					if evade_pred(evade_ctx, u) {
						continue
					}
				}
				append(&valid_targets, u)
			}
			if len(valid_targets) > 0 {
				possible_units_to_attack[t] = valid_targets
			}
		}
		remote := i_delegate_bridge_get_remote_player(self.bridge, current_enemy)
		attacks := player_select_kamikaze_suicide_attacks(remote, possible_units_to_attack)
		if len(attacks) == 0 {
			continue
		}
		// Validate: chosen units must be in possibleUnitsToAttack and resource
		// totals must remain positive.
		for t, unit_map in attacks {
			possible, has_t := possible_units_to_attack[t]
			if !has_t {
				fmt.panicf("Player has chosen illegal units during Kamikaze Suicide Attacks")
			}
			for u, _ in unit_map {
				contained := false
				for pu in possible {
					if pu == u {
						contained = true
						break
					}
				}
				if !contained {
					fmt.panicf(
						"Player has chosen illegal units during Kamikaze Suicide Attacks",
					)
				}
			}
			for _, resource_map in unit_map {
				// IntegerMap.subtract: subtract value-by-value.
				for r, n in resource_map {
					attack_tokens[r] = attack_tokens[r] - n
				}
			}
		}
		// IntegerMap.isPositive(): all values strictly > 0.
		all_positive := true
		for _, v in attack_tokens {
			if v <= 0 {
				all_positive = false
				break
			}
		}
		if !all_positive {
			fmt.panicf("Player has chosen illegal resource during Kamikaze Suicide Attacks")
		}
		for t, unit_map in attacks {
			location := t
			for unit_under_fire, number_of_attacks in unit_map {
				if len(number_of_attacks) == 0 {
					continue
				}
				total_values: i32 = 0
				for _, v in number_of_attacks {
					total_values += v
				}
				if total_values > 0 {
					battle_delegate_fire_kamikaze_suicide_attacks(
						self,
						unit_under_fire,
						number_of_attacks,
						resources_and_attack_values,
						current_enemy,
						location,
					)
				}
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#scramblingCleanup()
//   Returns scrambled units to their origin or to a player-selected
//   landing territory. Mirrors the Java private void method one-to-one.
battle_delegate_scrambling_cleanup :: proc(self: ^Battle_Delegate) {
	data := i_delegate_bridge_get_data(self.bridge)
	if !properties_get_scramble_rules_in_effect(game_data_get_properties(data)) {
		return
	}
	must_return_to_base := properties_get_scrambled_units_return_to_base(
		game_data_get_properties(data),
	)
	for t in game_map_get_territories(game_data_get_map(data)) {
		carrier_cost_of_current_terr: i32 = 0
		uc := territory_get_unit_collection(t)
		was_scrambled := make([dynamic]^Unit)
		for u in unit_collection_get_units(uc) {
			if matches_pred_unit_was_scrambled(nil, u) {
				append(&was_scrambled, u)
			}
		}
		for u in was_scrambled {
			owner := unit_get_owner(u)
			change := composite_change_new()
			landing_terr: ^Territory = nil
			history_text: string
			ally_p, ally_c := matches_is_territory_allied(unit_get_owner(u))
			if !must_return_to_base ||
			   !ally_p(ally_c, unit_get_originated_from(u)) {
				possible := battle_delegate_where_can_air_land(
					u,
					t,
					owner,
					&data.game_state,
					self.battle_tracker,
					carrier_cost_of_current_terr,
				)
				if len(possible) > 1 {
					unit_list := make([dynamic]^Unit)
					append(&unit_list, u)
					text := fmt.aprintf(
						"Select territory for air units to land. (Current territory is %s): %s",
						default_named_get_name(&t.named_attachable.default_named),
						my_formatter_units_to_text(unit_list),
					)
					remote := i_delegate_bridge_get_remote_player(self.bridge, owner)
					landing_terr = player_select_territory_for_air_to_land(
						remote,
						possible,
						t,
						text,
					)
				} else if len(possible) == 1 {
					landing_terr = possible[0]
				}
				if landing_terr == nil || landing_terr == t {
					carrier_cost_of_current_terr += air_movement_validator_carrier_cost(
						[]^Unit{u},
					)
					history_text = strings.concatenate(
						{
							"Scrambled unit stays in territory ",
							default_named_get_name(&t.named_attachable.default_named),
						},
					)
				} else {
					history_text = fmt.aprintf(
						"Moving scrambled unit from %s to %s",
						default_named_get_name(&t.named_attachable.default_named),
						default_named_get_name(&landing_terr.named_attachable.default_named),
					)
				}
			} else {
				landing_terr = unit_get_originated_from(u)
				history_text = fmt.aprintf(
					"Moving scrambled unit from %s  back to originating territory: %s",
					default_named_get_name(&t.named_attachable.default_named),
					default_named_get_name(&landing_terr.named_attachable.default_named),
				)
			}
			if landing_terr != nil && landing_terr != t {
				move_units := make([dynamic]^Unit)
				append(&move_units, u)
				composite_change_add(
					change,
					change_factory_move_units(t, landing_terr, move_units),
				)
				route := route_new_from_start_and_steps(t, landing_terr)
				composite_change_add(
					change,
					route_get_fuel_changes([]^Unit{u}, route, owner, data),
				)
			}
			composite_change_add(
				change,
				change_factory_unit_property_change_property_name(
					u,
					nil,
					.Originated_From,
				),
			)
			boxed_false := new(bool)
			boxed_false^ = false
			composite_change_add(
				change,
				change_factory_unit_property_change_property_name(
					u,
					rawptr(boxed_false),
					.Was_Scrambled,
				),
			)
			if !composite_change_is_empty(change) {
				i_delegate_history_writer_start_event(
					i_delegate_bridge_get_history_writer(self.bridge),
					history_text,
					rawptr(u),
				)
				i_delegate_bridge_add_change(self.bridge, &change.change)
			}
		}
	}
}


// games.strategy.triplea.delegate.battle.BattleDelegate#setupUnitsInSameTerritoryBattles(BattleTracker, IDelegateBridge)
//
// Set up the battles where the battle occurs because units are in the
// same territory. Faithful port of the Java private static method.
battle_delegate_setup_units_in_same_territory_battles :: proc(
	battle_tracker: ^Battle_Tracker,
	bridge: ^I_Delegate_Bridge,
) {
	player := i_delegate_bridge_get_game_player(bridge)
	data := i_delegate_bridge_get_data(bridge)
	ignore_transports := properties_get_ignore_transport_in_movement(
		game_data_get_properties(data),
	)
	st_pred, st_ctx := matches_unit_is_sea_transport_but_not_combat_sea_transport()
	sea_pred, sea_ctx := matches_unit_is_sea()
	evade_pred, evade_ctx := matches_unit_can_evade()
	hou_p, hou_c := matches_territory_has_units_owned_by(player)
	heu_p, heu_c := matches_territory_has_enemy_units(player)
	enemy_terr_p, enemy_terr_c := matches_is_territory_enemy_and_not_unowned_water(player)
	owned_p, owned_c := matches_unit_is_owned_by(player)
	en_unit_p, en_unit_c := matches_enemy_unit(player)
	infra_p, infra_c := matches_unit_is_infrastructure()

	battle_territories := make([dynamic]^Territory)
	defer delete(battle_territories)
	for t in game_map_get_territories(game_data_get_map(data)) {
		any_own_enemy := hou_p(hou_c, t) && heu_p(heu_c, t)
		enemy_and_own := enemy_terr_p(enemy_terr_c, t) && hou_p(hou_c, t)
		if any_own_enemy || enemy_and_own {
			append(&battle_territories, t)
		}
	}

	for territory in battle_territories {
		territory_units := unit_collection_get_units(territory_get_unit_collection(territory))
		attacking_units := make([dynamic]^Unit)
		for u in territory_units {
			if owned_p(owned_c, u) {
				append(&attacking_units, u)
			}
		}
		transport_map := transport_tracker_transporting(territory_units)
		dependants := make(map[^Unit]struct{})
		defer delete(dependants)
		for transport, transported in transport_map {
			in_attack := false
			for au in attacking_units {
				if au == transport {
					in_attack = true
					break
				}
			}
			if !in_attack {
				continue
			}
			for tu in transported {
				dependants[tu] = {}
			}
		}
		for au in attacking_units {
			delete_key(&dependants, au)
		}
		for u in dependants {
			append(&attacking_units, u)
		}
		enemy_units := make([dynamic]^Unit)
		for u in territory_units {
			if en_unit_p(en_unit_c, u) {
				append(&enemy_units, u)
			}
		}
		bombing_battle := battle_tracker_get_pending_bombing_battle(battle_tracker, territory)
		if bombing_battle != nil {
			bombing_attackers := i_battle_get_attacking_units(bombing_battle)
			kept := make([dynamic]^Unit)
			for u in attacking_units {
				if !slice.contains(bombing_attackers[:], u) {
					append(&kept, u)
				}
			}
			delete(attacking_units)
			attacking_units = kept
		}
		all_infra := len(attacking_units) > 0
		for u in attacking_units {
			if !infra_p(infra_c, u) {
				all_infra = false
				break
			}
		}
		if all_infra {
			continue
		}
		battle := battle_tracker_get_pending_battle(battle_tracker, territory, .NORMAL)
		if battle == nil {
			all_enemy_infra := true
			for u in enemy_units {
				if !infra_p(infra_c, u) {
					all_enemy_infra = false
					break
				}
			}
			if all_enemy_infra {
				battle_delegate_land_paratroopers(player, territory, bridge)
			}
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				strings.concatenate(
					{
						player.named.base.name,
						" creates battle in territory ",
						territory.named.base.name,
					},
				),
			)
			battle_tracker_add_battle_6(
				battle_tracker,
				cast(^Route)route_scripted_new(territory),
				attacking_units,
				player,
				bridge,
				nil,
				nil,
			)
			battle = battle_tracker_get_pending_battle(battle_tracker, territory, .NORMAL)
		}
		if battle == nil {
			continue
		}
		if bombing_battle != nil {
			battle_tracker_add_dependency(battle_tracker, battle, bombing_battle)
		}
		if i_battle_is_empty(battle) {
			i_battle_add_attack_change(
				battle,
				cast(^Route)route_scripted_new(territory),
				attacking_units,
				nil,
			)
		}
		battle_attackers := i_battle_get_attacking_units(battle)
		all_present := true
		for u in attacking_units {
			if !slice.contains(battle_attackers[:], u) {
				all_present = false
				break
			}
		}
		if !all_present {
			need := make([dynamic]^Unit)
			for u in attacking_units {
				if !slice.contains(battle_attackers[:], u) {
					append(&need, u)
				}
			}
			dep_of_attackers := i_battle_get_dependent_units(battle, battle_attackers)
			defer delete(dep_of_attackers)
			filtered_need := make([dynamic]^Unit)
			for u in need {
				if !slice.contains(dep_of_attackers[:], u) {
					append(&filtered_need, u)
				}
			}
			delete(need)
			need = filtered_need
			if territory_is_water(territory) {
				land_p, land_c := matches_unit_is_land()
				kept := make([dynamic]^Unit)
				for u in need {
					if !land_p(land_c, u) {
						append(&kept, u)
					}
				}
				delete(need)
				need = kept
			} else {
				kept := make([dynamic]^Unit)
				for u in need {
					if !sea_pred(sea_ctx, u) {
						append(&kept, u)
					}
				}
				delete(need)
				need = kept
			}
			if len(need) > 0 {
				i_battle_add_attack_change(
					battle,
					cast(^Route)route_scripted_new(territory),
					need,
					nil,
				)
			}
		}
		// Stalemate detection.
		all_attackers_st := len(attacking_units) > 0
		for u in attacking_units {
			if !(st_pred(st_ctx, u) && sea_pred(sea_ctx, u)) {
				all_attackers_st = false
				break
			}
		}
		all_enemies_st := len(enemy_units) > 0
		for u in enemy_units {
			if !(st_pred(st_ctx, u) && sea_pred(sea_ctx, u)) {
				all_enemies_st = false
				break
			}
		}
		atk1_p, atk1_c := matches_unit_has_attack_value_of_at_least(1)
		def1_p, def1_c := matches_unit_has_defend_value_of_at_least(1)
		all_attackers_no_attack := len(attacking_units) > 0
		for u in attacking_units {
			if atk1_p(atk1_c, u) {
				all_attackers_no_attack = false
				break
			}
		}
		all_enemies_no_def := len(enemy_units) > 0
		for u in enemy_units {
			if def1_p(def1_c, u) {
				all_enemies_no_def = false
				break
			}
		}
		stalemate :=
			(ignore_transports && all_attackers_st && all_enemies_st) ||
			(all_attackers_no_attack && all_enemies_no_def)
		if stalemate {
			results := battle_results_new_with_who_won(battle, .DRAW, data)
			battle_records_add_result_to_battle(
				battle_tracker_get_battle_records(battle_tracker),
				player,
				i_battle_get_battle_id(battle),
				nil,
				0,
				0,
				.STALEMATE,
				results,
			)
			i_battle_cancel_battle(battle, bridge)
			battle_tracker_remove_battle(battle_tracker, battle, data)
			continue
		}
		if len(attacking_units) > 0 {
			remote_player := i_delegate_bridge_get_remote_player(bridge)
			is_water := territory_is_water(territory)
			props := game_data_get_properties(data)
			if (is_water && properties_get_sea_battles_may_be_ignored(props)) ||
			   (!is_water && properties_get_land_battles_may_be_ignored(props)) {
				if !player_select_attack_units(remote_player, territory) {
					results := battle_results_new_with_who_won(battle, .NOT_FINISHED, data)
					battle_records_add_result_to_battle(
						battle_tracker_get_battle_records(battle_tracker),
						player,
						i_battle_get_battle_id(battle),
						nil,
						0,
						0,
						.NO_BATTLE,
						results,
					)
					i_battle_cancel_battle(battle, bridge)
					battle_tracker_remove_battle(battle_tracker, battle, data)
				}
				continue
			}
			all_enemies_st_only := len(enemy_units) > 0
			for u in enemy_units {
				if !(st_pred(st_ctx, u) && sea_pred(sea_ctx, u)) {
					all_enemies_st_only = false
					break
				}
			}
			if ignore_transports && all_enemies_st_only {
				if !player_select_attack_transports(remote_player, territory) {
					results := battle_results_new_with_who_won(battle, .NOT_FINISHED, data)
					battle_records_add_result_to_battle(
						battle_tracker_get_battle_records(battle_tracker),
						player,
						i_battle_get_battle_id(battle),
						nil,
						0,
						0,
						.NO_BATTLE,
						results,
					)
					i_battle_cancel_battle(battle, bridge)
					battle_tracker_remove_battle(battle_tracker, battle, data)
				}
				continue
			}
			can_passthrough_p, can_passthrough_c := matches_unit_can_be_moved_through_by_enemies()
			all_enemies_passthrough := len(enemy_units) > 0
			for u in enemy_units {
				if !can_passthrough_p(can_passthrough_c, u) {
					all_enemies_passthrough = false
					break
				}
			}
			if all_enemies_passthrough {
				if !player_select_attack_subs(remote_player, territory) {
					results := battle_results_new_with_who_won(battle, .NOT_FINISHED, data)
					battle_records_add_result_to_battle(
						battle_tracker_get_battle_records(battle_tracker),
						player,
						i_battle_get_battle_id(battle),
						nil,
						0,
						0,
						.NO_BATTLE,
						results,
					)
					i_battle_cancel_battle(battle, bridge)
					battle_tracker_remove_battle(battle_tracker, battle, data)
				}
				continue
			}
			all_enemies_ts := len(enemy_units) > 0
			for u in enemy_units {
				is_st_or_sub :=
					(st_pred(st_ctx, u) && sea_pred(sea_ctx, u)) || evade_pred(evade_ctx, u)
				if !is_st_or_sub {
					all_enemies_ts = false
					break
				}
			}
			if ignore_transports && all_enemies_ts {
				if !player_select_attack_units(remote_player, territory) {
					results := battle_results_new_with_who_won(battle, .NOT_FINISHED, data)
					battle_records_add_result_to_battle(
						battle_tracker_get_battle_records(battle_tracker),
						player,
						i_battle_get_battle_id(battle),
						nil,
						0,
						0,
						.NO_BATTLE,
						results,
					)
					i_battle_cancel_battle(battle, bridge)
					battle_tracker_remove_battle(battle_tracker, battle, data)
				}
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#doScrambling()
//
// Faithful port of the private void method. Looks at every territory the
// scramble logic determines is a viable scramble destination, prompts the
// defender for which units to scramble, validates max-count and fuel, then
// applies the resulting unit moves and battle creations / dependencies.
battle_delegate_do_scrambling :: proc(self: ^Battle_Delegate) {
	data := i_delegate_bridge_get_data(self.bridge)
	if !properties_get_scramble_rules_in_effect(game_data_get_properties(data)) {
		return
	}
	pending_battle_sites := battle_tracker_get_battle_listing_from_pending_battles(self.battle_tracker)
	territories_with_battles := battle_listing_get_normal_battles_including_air_battles(pending_battle_sites)
	if properties_get_can_scramble_into_air_battles(game_data_get_properties(data)) {
		extra := battle_listing_get_strategic_bombing_raids_including_air_battles(pending_battle_sites)
		for t in extra {
			territories_with_battles[t] = {}
		}
	}
	scramble_logic := scramble_logic_new(
		&data.game_state,
		self.player,
		territories_with_battles,
		self.battle_tracker,
	)
	all_dest := scramble_logic_get_units_that_can_scramble_by_destination(scramble_logic)
	for to, scramblers in all_dest {
		// scramblers.entrySet().removeIf(...)
		drop_keys := make([dynamic]^Territory)
		defer delete(drop_keys)
		for from, tup in scramblers {
			from_units := unit_collection_get_units(territory_get_unit_collection(from))
			kept := make([dynamic]^Unit)
			for u in tup.second {
				if slice.contains(from_units[:], u) {
					append(&kept, u)
				}
			}
			delete(tup.second)
			tup.second = kept
			if len(tup.second) == 0 {
				append(&drop_keys, from)
			}
		}
		for from in drop_keys {
			delete_key(&scramblers, from)
		}

		scrambled_here := false
		defender := player_list_get_null_player(game_data_get_player_list(data))
		if len(scramblers) > 0 {
			if battle_tracker_has_pending_non_bombing_battle(self.battle_tracker, to) {
				defender = abstract_battle_find_defender(to, self.player, &data.game_state)
			}
			if game_player_is_null(defender) {
				for from in scramblers {
					candidate := abstract_battle_find_defender(from, self.player, &data.game_state)
					if !game_player_is_null(candidate) {
						defender = candidate
						break
					}
				}
				if game_player_is_null(defender) {
					defender = player_list_get_null_player(game_data_get_player_list(data))
				}
			}
			if game_player_is_null(defender) {
				continue
			}
			remote := i_delegate_bridge_get_remote_player(self.bridge, defender)
			to_scramble := player_scramble_units_query(remote, to, scramblers)
			if to_scramble == nil {
				continue
			}
			for k, _ in to_scramble {
				if _, ok := scramblers[k]; !ok {
					fmt.panicf("Trying to scramble from illegal territory")
				}
			}
			for from, _ in scramblers {
				units, has_units := to_scramble[from]
				if !has_units {
					continue
				}
				max_allowed := scramble_logic_get_max_scramble_count(scramblers[from].first)
				if i32(len(units)) > max_allowed {
					fmt.panicf(
						"Trying to scramble %d out of %s, but max allowed is %d",
						len(units),
						from.named.base.name,
						max_allowed,
					)
				}
			}
			player_fuel_cost := make(map[^Game_Player]^Resource_Collection)
			defer delete(player_fuel_cost)
			for from, units in to_scramble {
				cost_map := route_get_scramble_fuel_cost_charge(units[:], from, to, data)
				for p, cost in cost_map {
					if existing, has := player_fuel_cost[p]; has {
						resource_collection_add(existing, cost)
					} else {
						player_fuel_cost[p] = cost
					}
				}
			}
			for p, cost in player_fuel_cost {
				copy_im := resource_collection_get_resources_copy(cost)
				if !resource_collection_has(game_player_get_resources(p), &copy_im) {
					fmt.panicf("Not enough fuel to scramble, player: %s", p.named.base.name)
				}
			}

			change := composite_change_new()
			for t, scrambling in to_scramble {
				if len(scrambling) == 0 {
					continue
				}
				number_scrambled := i32(len(scrambling))
				airbase_pred, airbase_ctx := scramble_logic_get_airbase_that_can_scramble_predicate(scramble_logic)
				airbases := make([dynamic]^Unit)
				for u in unit_collection_get_units(territory_get_unit_collection(t)) {
					if airbase_pred(airbase_ctx, u) {
						append(&airbases, u)
					}
				}
				max_can_scramble := scramble_logic_get_max_scramble_count(airbases)
				if max_can_scramble != max(i32) {
					for airbase in airbases {
						allowed_scramble := unit_get_max_scramble_count(airbase)
						if allowed_scramble > 0 {
							new_allowed: i32
							if allowed_scramble >= number_scrambled {
								new_allowed = allowed_scramble - number_scrambled
								number_scrambled = 0
							} else {
								new_allowed = 0
								number_scrambled -= allowed_scramble
							}
							boxed := new(i32)
							boxed^ = new_allowed
							composite_change_add(
								change,
								change_factory_unit_property_change_property_name(
									airbase,
									rawptr(boxed),
									.Max_Scramble_Count,
								),
							)
						}
						if number_scrambled <= 0 {
							break
						}
					}
				}
				delete(airbases)
				for u in scrambling {
					composite_change_add(
						change,
						change_factory_unit_property_change_property_name(
							u,
							rawptr(t),
							.Originated_From,
						),
					)
					boxed_true := new(bool)
					boxed_true^ = true
					composite_change_add(
						change,
						change_factory_unit_property_change_property_name(
							u,
							rawptr(boxed_true),
							.Was_Scrambled,
						),
					)
					route := route_new_from_start_and_steps(t, to)
					composite_change_add(
						change,
						route_get_fuel_changes([]^Unit{u}, route, unit_get_owner(u), data),
					)
				}
				composite_change_add(
					change,
					change_factory_move_units(t, to, scrambling),
				)
				history_writer := i_delegate_bridge_get_history_writer(self.bridge)
				event := fmt.aprintf(
					"%s scrambles %d units out of %s to defend against the attack in %s",
					defender.named.base.name,
					len(scrambling),
					t.named.base.name,
					to.named.base.name,
				)
				i_delegate_history_writer_start_event(history_writer, event, rawptr(&scrambling))
				scrambled_here = true
			}
			if !composite_change_is_empty(change) {
				i_delegate_bridge_add_change(self.bridge, &change.change)
			}
		}
		if !scrambled_here {
			continue
		}
		bombing := battle_tracker_get_pending_bombing_battle(self.battle_tracker, to)
		battle := battle_tracker_get_pending_battle(self.battle_tracker, to, .NORMAL)
		if battle == nil {
			to_uc := territory_get_unit_collection(to)
			owned_p2, owned_c2 := matches_unit_is_owned_by(self.player)
			attacking_units := make([dynamic]^Unit)
			for u in unit_collection_get_units(to_uc) {
				if owned_p2(owned_c2, u) {
					append(&attacking_units, u)
				}
			}
			if bombing != nil {
				bombing_attackers := i_battle_get_attacking_units(bombing)
				kept := make([dynamic]^Unit)
				for u in attacking_units {
					if !slice.contains(bombing_attackers[:], u) {
						append(&kept, u)
					}
				}
				delete(attacking_units)
				attacking_units = kept
			}
			if len(attacking_units) == 0 {
				continue
			}
			history_writer := i_delegate_bridge_get_history_writer(self.bridge)
			event := strings.concatenate(
				{
					defender.named.base.name,
					" scrambles to create a battle in territory ",
					to.named.base.name,
				},
			)
			i_delegate_history_writer_start_event(history_writer, event)
			battle_tracker_add_battle_6(
				self.battle_tracker,
				cast(^Route)route_scripted_new(to),
				attacking_units,
				self.player,
				self.bridge,
				nil,
				nil,
			)
			battle = battle_tracker_get_pending_battle(self.battle_tracker, to, .NORMAL)
			if battle != nil && (cast(^Abstract_Battle)battle).is_must_fight_battle {
				mfb := cast(^Must_Fight_Battle)battle
				transport_p, transport_c := matches_unit_is_sea_transport()
				any_transport := false
				for u in attacking_units {
					if transport_p(transport_c, u) {
						any_transport = true
						break
					}
				}
				if any_transport {
					reload_change := composite_change_new()
					transport_tracker_reload_transports(attacking_units, reload_change)
					if !composite_change_is_empty(reload_change) {
						i_delegate_bridge_add_change(self.bridge, &reload_change.change)
					}
				}
				air_p, air_c := matches_unit_is_air()
				any_non_air := false
				for u in attacking_units {
					if !air_p(air_c, u) {
						any_non_air = true
						break
					}
				}
				if any_non_air {
					attacking_from_map := make(map[^Territory][dynamic]^Unit)
					predicate_pair: proc(rawptr, ^Territory) -> bool
					predicate_ctx: rawptr
					if territory_is_water(to) {
						predicate_pair, predicate_ctx = matches_territory_is_water()
					} else {
						predicate_pair, predicate_ctx = matches_territory_is_land()
					}
					neighbors := game_map_get_neighbors_predicate(
						game_data_get_map(data),
						to,
						predicate_pair,
						predicate_ctx,
					)
					for nbr in neighbors {
						copy_units := make([dynamic]^Unit)
						for u in attacking_units {
							append(&copy_units, u)
						}
						attacking_from_map[nbr] = copy_units
					}
					must_fight_battle_set_attacking_from_map(mfb, attacking_from_map)
				}
			}
		} else if (cast(^Abstract_Battle)battle).is_must_fight_battle {
			must_fight_battle_reset_defending_units(cast(^Must_Fight_Battle)battle, self.player)
		}
		if territory_is_water(to) {
			land_p, land_c := matches_territory_is_land()
			neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(data),
				to,
				land_p,
				land_c,
			)
			amphib_p, amphib_c := matches_battle_is_amphibious_with_units_attacking_from(to)
			for nbr in neighbors {
				adjacent_battle := battle_tracker_get_pending_battle(
					self.battle_tracker,
					nbr,
					.NORMAL,
				)
				if adjacent_battle == nil {
					continue
				}
				if amphib_p(amphib_c, adjacent_battle) {
					battle_tracker_add_dependency(self.battle_tracker, adjacent_battle, battle)
				}
				if (cast(^Abstract_Battle)adjacent_battle).is_must_fight_battle {
					must_fight_battle_reset_defending_units(
						cast(^Must_Fight_Battle)adjacent_battle,
						self.player,
					)
				}
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.BattleDelegate#doInitialize(BattleTracker, IDelegateBridge)
// Java:
//   setupUnitsInSameTerritoryBattles(battleTracker, bridge);
//   setupTerritoriesAbandonedToTheEnemy(battleTracker, bridge);
//   battleTracker.clearFinishedBattles(bridge);
//   resetMaxScrambleCount(bridge);
battle_delegate_do_initialize :: proc(battle_tracker: ^Battle_Tracker, bridge: ^I_Delegate_Bridge) {
	battle_delegate_setup_units_in_same_territory_battles(battle_tracker, bridge)
	battle_delegate_setup_territories_abandoned_to_the_enemy(battle_tracker, bridge)
	battle_tracker_clear_finished_battles(battle_tracker, bridge)
	battle_delegate_reset_max_scramble_count(bridge)
}

// games.strategy.triplea.delegate.battle.BattleDelegate#end()
// Renamed from `end` (Java identifier) to `battle_delegate_end` since `end`
// is reserved-ish in Odin contexts and to follow the file's naming scheme.
battle_delegate_end :: proc(self: ^Battle_Delegate) {
	if self.need_to_record_battle_statistics {
		battle_tracker_send_battle_records_to_game_data(battle_delegate_get_battle_tracker(self), self.bridge)
		self.need_to_record_battle_statistics = false
	}
	if self.need_to_cleanup {
		battle_tracker_clear_battle_records(battle_delegate_get_battle_tracker(self))
		battle_delegate_scrambling_cleanup(self)
		battle_delegate_air_battle_cleanup(self)
		self.need_to_cleanup = false
	}
	if self.need_to_check_defending_planes_can_land {
		battle_delegate_check_defending_planes_can_land(self)
		self.need_to_check_defending_planes_can_land = false
	}
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	self.need_to_initialize = true
	self.need_to_scramble = true
	self.need_to_create_rockets = true
	self.need_to_kamikaze_suicide_attacks = true
	self.need_to_clear_empty_air_battle_attacks = true
	self.need_to_add_bombardment_sources = true
	self.need_to_fire_rockets = true
	self.need_to_record_battle_statistics = true
	self.need_to_cleanup = true
	self.need_to_check_defending_planes_can_land = true
}

// games.strategy.triplea.delegate.battle.BattleDelegate#start()
battle_delegate_start :: proc(self: ^Battle_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	// we may start multiple times due to loading after saving
	// only initialize once
	if self.need_to_initialize {
		battle_delegate_do_initialize(self.battle_tracker, self.bridge)
		self.need_to_initialize = false
	}
	// do pre-combat stuff, like scrambling, after we have set up all battles, but before we have
	// bombardment, etc.
	// the order of all of this stuff matters quite a bit.
	if self.need_to_scramble {
		battle_delegate_do_scrambling(self)
		self.need_to_scramble = false
	}
	if self.need_to_create_rockets {
		self.rocket_helper = rockets_fire_helper_set_up_rockets(self.bridge)
		self.need_to_create_rockets = false
	}
	if self.need_to_kamikaze_suicide_attacks {
		battle_delegate_do_kamikaze_suicide_attacks(self)
		self.need_to_kamikaze_suicide_attacks = false
	}
	if self.need_to_clear_empty_air_battle_attacks {
		battle_delegate_clear_empty_air_battle_attacks(self.battle_tracker, self.bridge)
		self.need_to_clear_empty_air_battle_attacks = false
	}
	if self.need_to_add_bombardment_sources {
		battle_delegate_add_bombardment_sources(self)
		self.need_to_add_bombardment_sources = false
	}
	battle_tracker_fight_air_raids_and_strategic_bombing_simple(self.battle_tracker, self.bridge)
	if self.need_to_fire_rockets {
		// If we are loading a save-game created during battle and after the
		// 'needToCreateRockets' phase, rocketHelper can be null here.
		if self.rocket_helper == nil {
			self.rocket_helper = rockets_fire_helper_set_up_rockets(self.bridge)
		}
		rockets_fire_helper_fire_rockets(self.rocket_helper, self.bridge)
		self.need_to_fire_rockets = false
	}
	battle_tracker_fight_defenseless_battles(self.battle_tracker, self.bridge)
	battle_tracker_fight_battle_if_only_one(self.battle_tracker, self.bridge)
}
