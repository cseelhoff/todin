package game

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

