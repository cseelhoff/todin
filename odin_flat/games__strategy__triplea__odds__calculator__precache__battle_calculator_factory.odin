package game

// Java: games.strategy.triplea.odds.calculator.precache.BattleCalculatorFactory
//
// Lazy-singleton store + dispatch helper.
//
// Wrap target — by design only the AI hot path goes through this; the
// Java BattleCalculatorPanel / LanchesterDebugAction sites use per-instance
// mutable settings (amphibious, OOL strings, retreat thresholds) NOT in the
// Battle_Scenario_Key, so wrapping them would silently return wrong cached
// results when those settings change between calls. The Odin port has no
// UI calculator equivalent today, so this comment is forward-looking.

import "core:log"
import "core:sync"

@(private="file") shared_store: ^Sqlite_Battle_Precache_Store
@(private="file") shared_caching_calc: ^Caching_Battle_Calculator
@(private="file") store_lock: sync.Mutex

// Java: maybeCachingWrap(IBattleCalculator inner). Returns inner unchanged
// when caching is disabled or the store cannot open. The return type is
// the wrapper pointer; callers route through `precache_dispatch_calculate`
// which handles both wrapped and unwrapped paths.
battle_calculator_factory_maybe_caching_wrap :: proc(
	inner: ^Concurrent_Battle_Calculator,
) -> ^Caching_Battle_Calculator {
	when !BATTLE_PRECACHE_ENABLED {
		return nil
	} else {
		if inner == nil { return nil }
		if !battle_precache_config_is_enabled() { return nil }
		store := battle_calculator_factory_ensure_shared_store()
		if store == nil { return nil }

		sync.mutex_lock(&store_lock)
		defer sync.mutex_unlock(&store_lock)
		if shared_caching_calc == nil {
			run_count := battle_precache_config_run_count()
			log.infof("Battle precache enabled (runCount=%d, db=%s)",
				run_count, battle_precache_config_db_path(context.temp_allocator))
			shared_caching_calc = caching_battle_calculator_new(inner, store, run_count)
		}
		return shared_caching_calc
	}
}

// Single dispatch point. Called from pro_odds_calculator after it has the
// concrete delegate pointer. When the precache is disabled, this collapses
// to a direct call into the concurrent calculator (zero overhead).
precache_dispatch_calculate :: proc(
	delegate: ^Concurrent_Battle_Calculator,
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
	when BATTLE_PRECACHE_ENABLED {
		if wrapper := battle_calculator_factory_maybe_caching_wrap(delegate); wrapper != nil {
			return caching_battle_calculator_calculate(
				wrapper, attacker, defender, location, attacking,
				defending, bombarding, territory_effects,
				retreat_when_only_air_left, run_count,
			)
		}
	}
	return concurrent_battle_calculator_calculate(
		delegate, attacker, defender, location, attacking,
		defending, bombarding, territory_effects,
		retreat_when_only_air_left, run_count,
	)
}

@(private="file")
battle_calculator_factory_ensure_shared_store :: proc() -> ^Sqlite_Battle_Precache_Store {
	when !BATTLE_PRECACHE_ENABLED {
		return nil
	} else {
		sync.mutex_lock(&store_lock)
		defer sync.mutex_unlock(&store_lock)
		if shared_store != nil { return shared_store }

		db_path := battle_precache_config_db_path(context.temp_allocator)
		if db_path == "" {
			log.warn("Battle precache cannot resolve a db path; caching disabled")
			return nil
		}
		store, ok := sqlite_battle_precache_store_open_at_file(db_path)
		if !ok {
			log.warnf("Battle precache could not open db at %s; caching disabled", db_path)
			return nil
		}
		shared_store = store
		return shared_store
	}
}

// Optional cleanup hook for tests / app shutdown.
battle_calculator_factory_shutdown :: proc() {
	when BATTLE_PRECACHE_ENABLED {
		sync.mutex_lock(&store_lock)
		defer sync.mutex_unlock(&store_lock)
		if shared_store != nil {
			sqlite_battle_precache_store_close(shared_store)
			shared_store = nil
			shared_caching_calc = nil
		}
	}
}
