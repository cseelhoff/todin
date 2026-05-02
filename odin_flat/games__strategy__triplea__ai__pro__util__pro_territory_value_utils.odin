package game

Pro_Territory_Value_Utils :: struct {}

// Java: ProTerritoryValueUtils.lambda$findMaxLandMassSize$1(
//   HashSet<Territory> visited, int[] landMassSize, Territory territory, int distance)
//   -> { visited.add(territory); landMassSize[0]++; return true; }
//
// Captures `visited` (HashSet<Territory>) and `landMassSize` (int[1]) from
// findMaxLandMassSize. Both are mutable captures, so they're passed as pointers.
pro_territory_value_utils_lambda_find_max_land_mass_size_1 :: proc(
	visited: ^map[^Territory]struct {},
	land_mass_size: ^[1]i32,
	territory: ^Territory,
	distance: i32,
) -> bool {
	visited[territory] = {}
	land_mass_size[0] += 1
	return true
}

// Java: ProTerritoryValueUtils.lambda$findSeaTerritoryValues$0(GamePlayer player, Territory targetTerritory) -> int
//   from findSeaTerritoryValues:
//     targetTerritory ->
//         targetTerritory.getUnitCollection().countMatches(Matches.unitIsEnemyOf(player))
//
// Captures `player` from the enclosing method (passed as the first synthetic
// parameter). The Java return type is `int` (ToIntFunction<Territory>); the
// "-> bool" hint in the orchestrator template is a generic default that does
// not match this lambda's actual return type. We emit the faithful `i32`
// version so the callsite in calculateTerritoryValueToTargets type-checks.
//
// Body: count units in `t.getUnitCollection()` whose owner is at war with
// `player`. We inline the Matches.unitIsEnemyOf(player) predicate rather than
// allocating a (proc, ctx) pair just to feed unit_collection_count_matches,
// which expects a context-free `proc(^Unit) -> bool`.
pro_territory_value_utils_lambda_find_sea_territory_values_0 :: proc(player: ^Game_Player, t: ^Territory) -> i32 {
	uc := territory_get_unit_collection(t)
	count: i32 = 0
	for u in uc.units {
		if game_player_is_at_war(player, unit_get_owner(u)) {
			count += 1
		}
	}
	return count
}

