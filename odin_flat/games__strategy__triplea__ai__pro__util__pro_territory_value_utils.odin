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

// Java: ProTerritoryValueUtils.lambda$findLandValue$2(GamePlayer player, Territory t1, Territory t2) -> boolean
//   from findLandValue:
//     final BiPredicate<Territory, Territory> routeCond =
//         (t1, t2) ->
//             ProMatches.territoryCanPotentiallyMoveLandUnits(player).test(t2)
//                 && ProMatches.noCanalsBetweenTerritories(player).test(t1, t2);
//
// Captures `player` from the enclosing method. Both inner predicates only
// depend on `player`, so we construct stack-local ctx structs and invoke the
// existing `_pred_` callbacks directly rather than allocating heap ctx pairs.
pro_territory_value_utils_lambda_find_land_value_2 :: proc(
	player: ^Game_Player,
	t1: ^Territory,
	t2: ^Territory,
) -> bool {
	land_ctx := Pro_Matches_Ctx_territory_can_potentially_move_land_units{
		player = player,
	}
	if !pro_matches_pred_territory_can_potentially_move_land_units(rawptr(&land_ctx), t2) {
		return false
	}
	canal_ctx := Pro_Matches_Ctx_no_canals_between_territories{
		player = player,
	}
	return pro_matches_pred_no_canals_between_territories(rawptr(&canal_ctx), t1, t2)
}

// Visitor type embedding the BFS Visitor base. Replaces the Java
// `(territory, distance) -> { visited.add(territory); landMassSize[0]++; return true; }`
// lambda by reifying the captured `visited` and `landMassSize` references as
// pointers held by the visitor struct.
Pro_Territory_Value_Utils_Find_Max_Land_Mass_Size_Visitor :: struct {
	using visitor:  Breadth_First_Search_Visitor,
	visited:        ^map[^Territory]struct {},
	land_mass_size: ^i32,
}

pro_territory_value_utils_find_max_land_mass_size_visit :: proc(
	self: ^Breadth_First_Search_Visitor,
	territory: ^Territory,
	distance: i32,
) -> bool {
	this := cast(^Pro_Territory_Value_Utils_Find_Max_Land_Mass_Size_Visitor)self
	this.visited[territory] = {}
	this.land_mass_size^ += 1
	return true
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils#findMaxLandMassSize(GamePlayer)
// Java:
//   final GameState data = player.getData();
//   final Predicate<Territory> cond = ProMatches.territoryCanPotentiallyMoveLandUnits(player);
//   final var visited = new HashSet<Territory>();
//   int maxLandMassSize = 1;
//   for (final Territory t : data.getMap().getTerritories()) {
//     if (!t.isWater() && !visited.contains(t)) {
//       visited.add(t);
//       final int[] landMassSize = new int[1];
//       new BreadthFirstSearch(t, cond)
//           .traverse((territory, distance) -> {
//             visited.add(territory);
//             landMassSize[0]++;
//             return true;
//           });
//       if (landMassSize[0] > maxLandMassSize) maxLandMassSize = landMassSize[0];
//     }
//   }
//   return maxLandMassSize;
pro_territory_value_utils_find_max_land_mass_size :: proc(player: ^Game_Player) -> i32 {
	data := game_player_get_data(player)
	cond_proc, cond_ctx := pro_matches_territory_can_potentially_move_land_units(player)
	visited := make(map[^Territory]struct {})
	defer delete(visited)
	max_land_mass_size: i32 = 1
	territories := game_map_get_territories(game_data_get_map(data))
	for t in territories {
		if !territory_is_water(t) {
			if _, already := visited[t]; !already {
				visited[t] = {}
				land_mass_size: i32 = 0
				bfs := breadth_first_search_new_with_start_territory_and_predicate(
					t,
					cond_proc,
					cond_ctx,
				)
				visitor := Pro_Territory_Value_Utils_Find_Max_Land_Mass_Size_Visitor{
					visitor        = Breadth_First_Search_Visitor{
						visit = pro_territory_value_utils_find_max_land_mass_size_visit,
					},
					visited        = &visited,
					land_mass_size = &land_mass_size,
				}
				breadth_first_search_traverse(bfs, &visitor.visitor)
				if land_mass_size > max_land_mass_size {
					max_land_mass_size = land_mass_size
				}
			}
		}
	}
	return max_land_mass_size
}

// Visitor for findNearbyEnemyCapitalsAndFactories. Reifies the Java anonymous
// BreadthFirstSearch.Visitor — captures the enemy set being searched for, the
// `found` accumulator, and the inner `currentDistance` field that the visitor
// uses to detect distance-layer transitions.
//
// MIN_FACTORY_CHECK_DISTANCE = 9 from ProTerritoryValueUtils (file-static).
Pro_Territory_Value_Utils_Find_Nearby_Enemy_Capitals_And_Factories_Visitor :: struct {
	using visitor:                Breadth_First_Search_Visitor,
	enemy_capitals_and_factories: ^map[^Territory]struct {},
	found:                        ^map[^Territory]struct {},
	current_distance:             i32,
}

@(private = "file")
PRO_TERRITORY_VALUE_UTILS_MIN_FACTORY_CHECK_DISTANCE :: 9

pro_territory_value_utils_find_nearby_enemy_capitals_and_factories_visit :: proc(
	self: ^Breadth_First_Search_Visitor,
	territory: ^Territory,
	distance: i32,
) -> bool {
	this :=
		cast(^Pro_Territory_Value_Utils_Find_Nearby_Enemy_Capitals_And_Factories_Visitor)self
	if _, in_set := this.enemy_capitals_and_factories[territory]; in_set {
		this.found[territory] = {}
	}
	if distance != this.current_distance {
		this.current_distance = distance
		// shouldContinueSearch(): currentDistance <= MIN_FACTORY_CHECK_DISTANCE || found.isEmpty()
		should_continue :=
			this.current_distance <= PRO_TERRITORY_VALUE_UTILS_MIN_FACTORY_CHECK_DISTANCE ||
			len(this.found) == 0
		if !should_continue {
			return false
		}
	}
	return true
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils#findNearbyEnemyCapitalsAndFactories(
//     Territory, Set<Territory>)
// Java:
//   final var found = new HashSet<Territory>();
//   new BreadthFirstSearch(startTerritory)
//       .traverse(new BreadthFirstSearch.Visitor() {
//             int currentDistance = -1;
//             public boolean visit(Territory territory, int distance) {
//               if (enemyCapitalsAndFactories.contains(territory)) found.add(territory);
//               if (distance != currentDistance) {
//                 currentDistance = distance;
//                 if (!shouldContinueSearch()) return false;
//               }
//               return true;
//             }
//             public boolean shouldContinueSearch() {
//               return currentDistance <= MIN_FACTORY_CHECK_DISTANCE || found.isEmpty();
//             }
//           });
//   return found;
pro_territory_value_utils_find_nearby_enemy_capitals_and_factories :: proc(
	start_territory: ^Territory,
	enemy_capitals_and_factories: ^map[^Territory]struct {},
) -> map[^Territory]struct {} {
	found := make(map[^Territory]struct {})
	bfs := breadth_first_search_new_with_start_territory(start_territory)
	visitor := Pro_Territory_Value_Utils_Find_Nearby_Enemy_Capitals_And_Factories_Visitor{
		visitor                      = Breadth_First_Search_Visitor{
			visit = pro_territory_value_utils_find_nearby_enemy_capitals_and_factories_visit,
		},
		enemy_capitals_and_factories = enemy_capitals_and_factories,
		found                        = &found,
		current_distance             = -1,
	}
	breadth_first_search_traverse(bfs, &visitor.visitor)
	return found
}

