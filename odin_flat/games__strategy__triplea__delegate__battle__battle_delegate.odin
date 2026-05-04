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

