package game

// Java: games.strategy.triplea.odds.calculator.precache.BattlePrecacheConfig
//
// Resolves the runtime configuration of the battle-precache feature.
//
// Precedence (first non-empty wins):
//   1. Environment variable (TRIPLEA_BATTLE_PRECACHE_*)
//   2. Compile-time `#config` defaults (`BATTLE_PRECACHE_ENABLED`, etc.)
//
// The Odin port has no `ClientSetting` framework — env-vars take the
// place of Java's persisted user-settings layer.

import "core:os"
import "core:strconv"
import "core:strings"

// Compile-time gate. When false, the entire SQLite-backed precache code
// path stays out of the binary at the dispatch site (`when
// BATTLE_PRECACHE_ENABLED { ... }`). Default OFF.
BATTLE_PRECACHE_ENABLED :: #config(BATTLE_PRECACHE_ENABLED, true)

// Compile-time defaults; the env-vars below override them at runtime.
BATTLE_PRECACHE_DEFAULT_RUN_COUNT :: 1000
BATTLE_PRECACHE_DEFAULT_DB_FILE   :: "battle_precalc.sqlite"

// Java: SYS_PROP_ENABLED   "triplea.battle.precache.enabled"
//       SYS_PROP_DB_PATH   "triplea.battle.precache.dbPath"
//       SYS_PROP_RUN_COUNT "triplea.battle.precache.runCount"
ENV_VAR_ENABLED   :: "TRIPLEA_BATTLE_PRECACHE_ENABLED"
ENV_VAR_DB_PATH   :: "TRIPLEA_BATTLE_PRECACHE_DB_PATH"
ENV_VAR_RUN_COUNT :: "TRIPLEA_BATTLE_PRECACHE_RUN_COUNT"

// Java: BattlePrecacheConfig.isEnabled()
//   sysProp first, then ClientSetting, defaulting false.
battle_precache_config_is_enabled :: proc() -> bool {
	when !BATTLE_PRECACHE_ENABLED {
		// Compile-time hard-off. No matter what the env says, no FFI is
		// pulled in, so we cannot safely call into the store.
		return false
	} else {
		v := os.get_env(ENV_VAR_ENABLED, context.temp_allocator)
		if v == "" {
			return true // compile-flag is on; default to enabled.
		}
		lower := strings.to_lower(v, context.temp_allocator)
		switch lower {
		case "1", "true", "yes", "on":
			return true
		case "0", "false", "no", "off":
			return false
		}
		return false
	}
}

// Java: BattlePrecacheConfig.dbPath()
//   sysProp -> ClientSetting -> $userRootFolder/battle_precalc.sqlite
//
// Java ClientFileSystemHelper.getUserRootFolder():
//   Path rootDir = userHome/Documents/triplea
//   return Files.exists(rootDir) ? rootDir : userHome/triplea
// USER_ROOT_FOLDER_NAME = "triplea" (no leading dot).
battle_precache_config_db_path :: proc(allocator := context.allocator) -> string {
	v := os.get_env(ENV_VAR_DB_PATH, context.temp_allocator)
	if v != "" {
		return strings.clone(v, allocator)
	}
	home := os.get_env("HOME", context.temp_allocator)
	if home == "" {
		// Last-resort fallback: pwd. Caller treats empty as "do not enable".
		return strings.clone(BATTLE_PRECACHE_DEFAULT_DB_FILE, allocator)
	}
	documents_root := strings.concatenate({home, "/Documents/triplea"}, context.temp_allocator)
	if os.is_dir(documents_root) {
		return strings.concatenate({documents_root, "/", BATTLE_PRECACHE_DEFAULT_DB_FILE}, allocator)
	}
	return strings.concatenate({home, "/triplea/", BATTLE_PRECACHE_DEFAULT_DB_FILE}, allocator)
}

// Java: BattlePrecacheConfig.runCount()
//   sysProp -> ClientSetting -> 1000.
battle_precache_config_run_count :: proc() -> i32 {
	v := os.get_env(ENV_VAR_RUN_COUNT, context.temp_allocator)
	if v == "" {
		return BATTLE_PRECACHE_DEFAULT_RUN_COUNT
	}
	parsed, ok := strconv.parse_i64(strings.trim_space(v))
	if !ok || parsed <= 0 {
		return BATTLE_PRECACHE_DEFAULT_RUN_COUNT
	}
	return i32(parsed)
}
