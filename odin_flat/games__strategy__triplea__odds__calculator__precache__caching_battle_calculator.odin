package game

// Java: games.strategy.triplea.odds.calculator.precache.CachingBattleCalculator
//
// SQLite-backed memoising decorator. Holds a delegate Concurrent_Battle_Calculator,
// the shared store, and the configured run count. On `calculate(...)`:
//
//   1. Build a Battle_Scenario_Key + cache key.
//   2. Look up the store. If the row exists with `>= runCount` simulations,
//      reconstruct and return.
//   3. Otherwise call the delegate with `max(runCount, configuredRunCount)`,
//      persist, and return.
//
// All errors fall through to the delegate — caching is best-effort.

import "core:log"

Caching_Battle_Calculator :: struct {
	delegate:             ^Concurrent_Battle_Calculator,
	store:                ^Sqlite_Battle_Precache_Store,
	configured_run_count: i32,
}

caching_battle_calculator_new :: proc(
	delegate: ^Concurrent_Battle_Calculator,
	store: ^Sqlite_Battle_Precache_Store,
	configured_run_count: i32,
	allocator := context.allocator,
) -> ^Caching_Battle_Calculator {
	self := new(Caching_Battle_Calculator, allocator)
	self.delegate             = delegate
	self.store                = store
	self.configured_run_count = max(1, configured_run_count)
	return self
}

// Same signature as concurrent_battle_calculator_calculate.
caching_battle_calculator_calculate :: proc(
	self: ^Caching_Battle_Calculator,
	attacker:                 ^Game_Player,
	defender:                 ^Game_Player,
	location:                 ^Territory,
	attacking:                [dynamic]^Unit,
	defending:                [dynamic]^Unit,
	bombarding:               [dynamic]^Unit,
	territory_effects:        [dynamic]^Territory_Effect,
	retreat_when_only_air_left: bool,
	run_count:                i32,
) -> ^Aggregate_Results {
	data := caching_battle_calculator_derive_data(
		location, attacker, defender, attacking, defending)
	if data == nil {
		return concurrent_battle_calculator_calculate(
			self.delegate, attacker, defender, location, attacking,
			defending, bombarding, territory_effects,
			retreat_when_only_air_left, run_count,
		)
	}

	key := battle_scenario_key_build(
		attacker, defender, location, attacking, defending, bombarding,
		territory_effects, retreat_when_only_air_left, data,
	)
	cache_key := battle_scenario_key_to_cache_key(key)

	if self.store != nil {
		if stored, ok := sqlite_battle_precache_store_lookup(self.store, cache_key); ok {
			if stored.stored_run_count >= run_count {
				if reconstructed, recon_ok :=
					cached_aggregate_results_from_stored(stored, data); recon_ok {
					return reconstructed
				}
				// Reconstruction failed (unit type / player no longer present).
				// Fall through to re-simulate; the upcoming store() overwrites
				// the now-stale row.
				log.warnf("Battle precache reconstruction failed for %s; resimulating", cache_key)
			}
		}
	}

	simulation_count := max(run_count, self.configured_run_count)
	fresh := concurrent_battle_calculator_calculate(
		self.delegate, attacker, defender, location, attacking,
		defending, bombarding, territory_effects,
		retreat_when_only_air_left, simulation_count,
	)
	if self.store != nil && fresh != nil && len(fresh.results) > 0 {
		stored := cached_aggregate_results_to_stored_results(fresh)
		canonical := battle_scenario_key_to_canonical_string(key)
		sqlite_battle_precache_store_store(
			self.store, cache_key, i32(len(fresh.results)),
			stored[:], canonical,
		)
	}
	return fresh
}

// Java: deriveGameData(...) — try location, attacker, defender, then
// scan unit lists. Returns nil if none yield a Game_Data.
@(private = "file")
caching_battle_calculator_derive_data :: proc(
	location: ^Territory,
	attacker, defender: ^Game_Player,
	attacking, defending: [dynamic]^Unit,
) -> ^Game_Data {
	if location != nil {
		if d := game_data_component_get_data(
			&location.named_attachable.default_named.game_data_component); d != nil {
			return d
		}
	}
	if attacker != nil {
		if d := game_data_component_get_data(
			&attacker.named_attachable.default_named.game_data_component); d != nil {
			return d
		}
	}
	if defender != nil {
		if d := game_data_component_get_data(
			&defender.named_attachable.default_named.game_data_component); d != nil {
			return d
		}
	}
	for u in attacking {
		if u == nil { continue }
		if d := game_data_component_get_data(&u.game_data_component); d != nil {
			return d
		}
	}
	for u in defending {
		if u == nil { continue }
		if d := game_data_component_get_data(&u.game_data_component); d != nil {
			return d
		}
	}
	return nil
}
