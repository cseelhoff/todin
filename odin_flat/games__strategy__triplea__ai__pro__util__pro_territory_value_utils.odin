package game

import "core:math"

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

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #findEnemyCapitalsAndFactoriesValue(GamePlayer, int, List<Territory>, List<Territory>)
// Java:
//   final GameState data = player.getData();
//   final List<Territory> allTerritories = data.getMap().getTerritories();
//   final Set<Territory> enemyCapitalsAndFactories =
//       new HashSet<>(CollectionUtils.getMatches(allTerritories,
//           ProMatches.territoryHasInfraFactoryAndIsOwnedByPlayersOrCantBeHeld(
//               player, ProUtils.getPotentialEnemyPlayers(player), territoriesThatCantBeHeld)));
//   final int numPotentialEnemyTerritories =
//       CollectionUtils.countMatches(allTerritories,
//           Matches.isTerritoryOwnedByAnyOf(ProUtils.getPotentialEnemyPlayers(player)));
//   if (enemyCapitalsAndFactories.size() * 2 >= numPotentialEnemyTerritories) {
//       enemyCapitalsAndFactories.clear();
//   }
//   enemyCapitalsAndFactories.addAll(ProUtils.getLiveEnemyCapitals(data, player));
//   enemyCapitalsAndFactories.removeAll(territoriesToAttack);
//   final Map<Territory, Double> enemyCapitalsAndFactoriesMap = new HashMap<>();
//   for (final Territory t : enemyCapitalsAndFactories) {
//     int factoryProduction = 0;
//     if (ProMatches.territoryHasInfraFactoryAndIsLand().test(t)) {
//       factoryProduction = TerritoryAttachment.getProduction(t);
//     }
//     double playerProduction = 0;
//     if (TerritoryAttachment.get(t).map(TerritoryAttachment::isCapital).orElse(false)) {
//       playerProduction = ProUtils.getPlayerProduction(t.getOwner(), data);
//     }
//     final int isNeutral = ProUtils.isNeutralLand(t) ? 1 : 0;
//     final int landMassSize = 1
//         + data.getMap()
//             .getNeighbors(t, 6, ProMatches.territoryCanPotentiallyMoveLandUnits(player))
//             .size();
//     final double value = Math.sqrt(factoryProduction + Math.sqrt(playerProduction))
//         * 32 / (1 + 3.0 * isNeutral) * landMassSize / maxLandMassSize;
//     enemyCapitalsAndFactoriesMap.put(t, value);
//   }
//   return enemyCapitalsAndFactoriesMap;
//
// `Set<Territory>` is mirrored as `map[^Territory]struct{}`. The
// CollectionUtils.getMatches/countMatches calls are inlined as direct
// loops to avoid round-tripping the typed `[dynamic]^Territory` through
// the rawptr-based collection_utils helpers.
pro_territory_value_utils_find_enemy_capitals_and_factories_value :: proc(
	player: ^Game_Player,
	max_land_mass_size: i32,
	territories_that_cant_be_held: [dynamic]^Territory,
	territories_to_attack: [dynamic]^Territory,
) -> map[^Territory]f64 {
	data := game_player_get_data(player)
	game_map := game_data_get_map(data)
	all_territories := game_map_get_territories(game_map)

	potential_enemies := pro_utils_get_potential_enemy_players(player)
	defer delete(potential_enemies)

	enemy_capitals_and_factories := make(map[^Territory]struct {})
	defer delete(enemy_capitals_and_factories)

	factory_pred, factory_ctx :=
		pro_matches_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held(
			player,
			potential_enemies,
			territories_that_cant_be_held,
		)
	for t in all_territories {
		if factory_pred(factory_ctx, t) {
			enemy_capitals_and_factories[t] = {}
		}
	}

	owned_pred, owned_ctx := matches_is_territory_owned_by_any_of(potential_enemies)
	num_potential_enemy_territories: i32 = 0
	for t in all_territories {
		if owned_pred(owned_ctx, t) {
			num_potential_enemy_territories += 1
		}
	}
	if i32(len(enemy_capitals_and_factories)) * 2 >= num_potential_enemy_territories {
		clear(&enemy_capitals_and_factories)
	}

	live_capitals := pro_utils_get_live_enemy_capitals(&data.game_state, player)
	defer delete(live_capitals)
	for c in live_capitals {
		enemy_capitals_and_factories[c] = {}
	}
	for t in territories_to_attack {
		delete_key(&enemy_capitals_and_factories, t)
	}

	enemy_capitals_and_factories_map := make(map[^Territory]f64)
	is_land_pred, is_land_ctx := pro_matches_territory_has_infra_factory_and_is_land()
	can_move_pred, can_move_ctx := pro_matches_territory_can_potentially_move_land_units(player)
	for t in enemy_capitals_and_factories {
		factory_production: i32 = 0
		if is_land_pred(is_land_ctx, t) {
			factory_production = territory_attachment_static_get_production(t)
		}
		player_production: f64 = 0
		att := territory_attachment_get(t)
		if att != nil && territory_attachment_is_capital(att) {
			player_production = pro_utils_get_player_production(
				territory_get_owner(t),
				&data.game_state,
			)
		}
		is_neutral: i32 = 0
		if pro_utils_is_neutral_land(t) {
			is_neutral = 1
		}
		neighbors := game_map_get_neighbors_distance_predicate(
			game_map,
			t,
			6,
			can_move_pred,
			can_move_ctx,
		)
		defer delete(neighbors)
		land_mass_size: i32 = 1 + i32(len(neighbors))
		value :=
			math.sqrt(f64(factory_production) + math.sqrt(player_production)) *
			32.0 /
			(1.0 + 3.0 * f64(is_neutral)) *
			f64(land_mass_size) /
			f64(max_land_mass_size)
		enemy_capitals_and_factories_map[t] = value
	}
	return enemy_capitals_and_factories_map
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #calculateTerritoryValueToTargets(
//       Territory, List<Territory>, GamePlayer, GameData,
//       ToIntFunction<Territory>)
// Java:
//   double territoryValue = 0;
//   for (final Territory targetTerritory : targetTerritories) {
//     final Optional<Route> optionalRoute = data.getMap()
//         .getRouteForUnits(t, targetTerritory,
//             ProMatches.territoryCanMoveSeaUnits(player, true),
//             Set.of(), player);
//     if (optionalRoute.isEmpty()) continue;
//     final int distance = optionalRoute.get().numberOfSteps();
//     if (distance > 0) {
//       territoryValue += toTargetValueFunction.applyAsInt(targetTerritory)
//           / Math.pow(2, distance);
//       territoryValue += targetTerritory.getUnitCollection()
//           .countMatches(Matches.unitIsEnemyOf(player))
//           / Math.pow(2, distance);
//     }
//   }
//   return territoryValue;
//
// `ToIntFunction<Territory>` is a functional interface (returns `int`),
// translated to a `proc(rawptr, ^Territory) -> i32` plus a paired
// `rawptr` userdata per the closure-capture rule in
// llm-instructions.md: one of the two Java callsites passes the
// non-capturing method ref `TerritoryAttachment::getProduction`, but
// the other passes a lambda capturing `player`, so the parameter must
// support captures.
//
// `data.getMap().getRouteForUnits(...)` is bypassed in favor of
// constructing a `Route_Finder` directly via
// `route_finder_new_with_units_player`. The reason: the Odin
// `game_map_get_route_for_units` helper accepts a bare
// `proc(^Territory) -> bool` (non-capturing) Predicate, but the
// `pro_matches_territory_can_move_sea_units` factory returns the
// `(proc(rawptr, ^Territory) -> bool, rawptr)` ctx-form Predicate
// (it captures `player` and `is_combat_move`). `Route_Finder` itself
// holds the ctx-form Predicate, so we feed the factory's output
// straight to it — same end result as `getRouteForUnits` (single
// `findRouteByCost` call, empty unit set, optional route → nullable
// `^Route`).
//
// `Set.of()` (an empty unmodifiable Set<Unit>) is mirrored as the
// zero-value `[dynamic]^Unit` (nil dynamic array, len 0) — same shape
// the existing `route_finder_new_map_condition` uses for its
// `Set.of()` call.
//
// The inner `targetTerritory.getUnitCollection().countMatches(
//   Matches.unitIsEnemyOf(player))` is exactly the body of the sibling
// lambda `pro_territory_value_utils_lambda_find_sea_territory_values_0`
// already defined above this method (which inlines the
// `Matches.unitIsEnemyOf(player)` Predicate by walking the unit
// collection and calling `game_player_is_at_war` on each owner). We
// reuse that lambda rather than duplicating its loop.
pro_territory_value_utils_calculate_territory_value_to_targets :: proc(
	t: ^Territory,
	target_territories: [dynamic]^Territory,
	player: ^Game_Player,
	data: ^Game_Data,
	to_target_value_function: proc(rawptr, ^Territory) -> i32,
	to_target_value_function_ctx: rawptr,
) -> f64 {
	territory_value: f64 = 0
	sea_pred, sea_ctx := pro_matches_territory_can_move_sea_units(player, true)
	empty_units: [dynamic]^Unit
	game_map := game_data_get_map(data)
	for target_territory in target_territories {
		rf := route_finder_new_with_units_player(
			game_map,
			sea_pred,
			sea_ctx,
			empty_units,
			player,
		)
		optional_route := route_finder_find_route_by_cost_pair(rf, t, target_territory)
		if optional_route == nil {
			continue
		}
		distance := route_number_of_steps(optional_route)
		if distance > 0 {
			divisor := math.pow(2.0, f64(distance))
			territory_value +=
				f64(to_target_value_function(to_target_value_function_ctx, target_territory)) /
				divisor
			enemy_count := pro_territory_value_utils_lambda_find_sea_territory_values_0(
				player,
				target_territory,
			)
			territory_value += f64(enemy_count) / divisor
		}
	}
	return territory_value
}

