package game

// Java: games.strategy.triplea.odds.calculator.precache.StoredScenario
//
// One row recovered from Sqlite_Battle_Precache_Store. Holds enough
// information to reconstruct a fully-functional Aggregate_Results via
// Cached_Aggregate_Results.

// Java: enum WhoWon { ATTACKER, DEFENDER, DRAW, NOT_FINISHED }
Stored_Scenario_Who_Won :: enum {
	ATTACKER,
	DEFENDER,
	DRAW,
	NOT_FINISHED,
}

// Java: record StoredResult(int battleRoundsFought, WhoWon whoWon,
//                            UnitComposition remainingAttackers,
//                            UnitComposition remainingDefenders)
Stored_Scenario_Result :: struct {
	battle_rounds_fought:  i32,
	who_won:               Stored_Scenario_Who_Won,
	remaining_attackers:   ^Unit_Composition,
	remaining_defenders:   ^Unit_Composition,
}

// Java: record StoredScenario(String cacheKey, int storedRunCount,
//                              int schemaVersion, long createdAtEpochMillis,
//                              List<StoredResult> results)
Stored_Scenario :: struct {
	cache_key:                string,
	stored_run_count:         i32,
	schema_version:           i32,
	created_at_epoch_millis:  i64,
	results:                  [dynamic]Stored_Scenario_Result,
}
