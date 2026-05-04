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

