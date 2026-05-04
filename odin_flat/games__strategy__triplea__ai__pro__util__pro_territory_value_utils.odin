package game

import "core:math"
import "core:slice"

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

// Wrapper around the non-capturing Java method reference
// `TerritoryAttachment::getProduction` so it satisfies the
// `proc(rawptr, ^Territory) -> i32` ctx-form ToIntFunction shape that
// `pro_territory_value_utils_calculate_territory_value_to_targets`
// expects (see closure-capture rule in llm-instructions.md).
pro_territory_value_utils_method_ref_territory_attachment_get_production :: proc(
	_ctx: rawptr,
	t: ^Territory,
) -> i32 {
	return territory_attachment_static_get_production(t)
}

// Adapter ctx + trampoline for the Java lambda
//   targetTerritory ->
//       targetTerritory.getUnitCollection().countMatches(Matches.unitIsEnemyOf(player))
// which appears inline as the second `toTargetValueFunction` argument
// passed to calculateTerritoryValueToTargets in findSeaTerritoryValues.
// The lambda captures `player`, so under the rawptr-ctx convention we
// pair the proc with a ctx struct holding the captured GamePlayer and
// delegate to the already-defined synthetic
// pro_territory_value_utils_lambda_find_sea_territory_values_0.
Pro_Territory_Value_Utils_Find_Sea_Territory_Values_0_Ctx :: struct {
	player: ^Game_Player,
}

pro_territory_value_utils_lambda_find_sea_territory_values_0_trampoline :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> i32 {
	c := cast(^Pro_Territory_Value_Utils_Find_Sea_Territory_Values_0_Ctx)ctx_ptr
	return pro_territory_value_utils_lambda_find_sea_territory_values_0(c.player, t)
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #findSeaTerritoryValues(GamePlayer, List<Territory>, List<Territory>)
// Java:
//   final Map<Territory, Double> territoryValueMap = new HashMap<>();
//   final GameData data = player.getData();
//   for (final Territory t : territoriesToCheck) {
//     if (!territoriesThatCantBeHeld.contains(t)
//         && t.isWater()
//         && !data.getMap().getNeighbors(t, Matches.territoryIsWater()).isEmpty()) {
//       double nearbySeaProductionValue = 0;
//       final Set<Territory> nearbySeaTerritories =
//           data.getMap().getNeighbors(t, 4,
//               ProMatches.territoryCanMoveSeaUnits(player, true));
//       final List<Territory> nearbyEnemySeaTerritories =
//           CollectionUtils.getMatches(nearbySeaTerritories,
//               ProMatches.territoryIsEnemyOrCantBeHeld(player, territoriesThatCantBeHeld));
//       calculateTerritoryValueToTargets(
//           t, nearbyEnemySeaTerritories, player, data,
//           TerritoryAttachment::getProduction);
//
//       double nearbyEnemySeaUnitValue = 0;
//       final List<Territory> nearbyEnemySeaUnitTerritories =
//           CollectionUtils.getMatches(nearbySeaTerritories,
//               Matches.territoryHasEnemyUnits(player));
//       calculateTerritoryValueToTargets(
//           t, nearbyEnemySeaUnitTerritories, player, data,
//           targetTerritory ->
//               targetTerritory.getUnitCollection()
//                   .countMatches(Matches.unitIsEnemyOf(player)));
//
//       final double value = 100 * nearbySeaProductionValue + nearbyEnemySeaUnitValue;
//       territoryValueMap.put(t, value);
//     } else if (t.isWater()) {
//       territoryValueMap.put(t, 0.0);
//     }
//   }
//   return territoryValueMap;
//
// Notes:
// - Java's `nearbySeaProductionValue` and `nearbyEnemySeaUnitValue` are
//   never reassigned: the two `calculateTerritoryValueToTargets` return
//   values are discarded. The final `value` therefore always evaluates
//   to `0`. We mirror Java faithfully: we still invoke the helper twice
//   (it has no observable side effects, but the call must exist for
//   behavior parity), and we still emit `100 * nearby_sea_production_value
//   + nearby_enemy_sea_unit_value` over the unmutated zeroed locals.
// - `Set<Territory>` from `getNeighbors(t, 4, ...)` is mirrored as
//   `map[^Territory]struct{}`, matching `game_map_get_neighbors_distance_predicate`.
// - The `CollectionUtils.getMatches(nearbySeaTerritories, predicate)`
//   calls are inlined as direct loops that filter the neighbor map into
//   `[dynamic]^Territory`, which is the shape calculate_territory_value_to_targets
//   already accepts (the orchestrator's sibling sea-target call uses the
//   same `[dynamic]^Territory` view).
// - `territoriesThatCantBeHeld.contains(t)` becomes a linear scan; the
//   typical input is a small List<Territory>, same as the surrounding
//   Pro AI code.
pro_territory_value_utils_find_sea_territory_values :: proc(
	player: ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
	territories_to_check: [dynamic]^Territory,
) -> map[^Territory]f64 {
	territory_value_map := make(map[^Territory]f64)
	data := game_player_get_data(player)
	game_map := game_data_get_map(data)

	water_pred, water_ctx := matches_territory_is_water()
	sea_move_pred, sea_move_ctx := pro_matches_territory_can_move_sea_units(player, true)
	enemy_or_cant_pred, enemy_or_cant_ctx := pro_matches_territory_is_enemy_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	has_enemy_units_pred, has_enemy_units_ctx := matches_territory_has_enemy_units(player)

	for t in territories_to_check {
		contained := false
		for tt in territories_that_cant_be_held {
			if tt == t {
				contained = true
				break
			}
		}
		if !contained && territory_is_water(t) {
			water_neighbors := game_map_get_neighbors_predicate(
				game_map,
				t,
				water_pred,
				water_ctx,
			)
			defer delete(water_neighbors)
			if len(water_neighbors) != 0 {
				nearby_sea_production_value: f64 = 0

				nearby_sea_territories := game_map_get_neighbors_distance_predicate(
					game_map,
					t,
					4,
					sea_move_pred,
					sea_move_ctx,
				)
				defer delete(nearby_sea_territories)

				nearby_enemy_sea_territories := make([dynamic]^Territory)
				defer delete(nearby_enemy_sea_territories)
				for n in nearby_sea_territories {
					if enemy_or_cant_pred(enemy_or_cant_ctx, n) {
						append(&nearby_enemy_sea_territories, n)
					}
				}
				_ = pro_territory_value_utils_calculate_territory_value_to_targets(
					t,
					nearby_enemy_sea_territories,
					player,
					data,
					pro_territory_value_utils_method_ref_territory_attachment_get_production,
					nil,
				)

				nearby_enemy_sea_unit_value: f64 = 0
				nearby_enemy_sea_unit_territories := make([dynamic]^Territory)
				defer delete(nearby_enemy_sea_unit_territories)
				for n in nearby_sea_territories {
					if has_enemy_units_pred(has_enemy_units_ctx, n) {
						append(&nearby_enemy_sea_unit_territories, n)
					}
				}
				lambda_ctx := new(Pro_Territory_Value_Utils_Find_Sea_Territory_Values_0_Ctx)
				lambda_ctx.player = player
				_ = pro_territory_value_utils_calculate_territory_value_to_targets(
					t,
					nearby_enemy_sea_unit_territories,
					player,
					data,
					pro_territory_value_utils_lambda_find_sea_territory_values_0_trampoline,
					rawptr(lambda_ctx),
				)

				value := 100.0 * nearby_sea_production_value + nearby_enemy_sea_unit_value
				territory_value_map[t] = value
			} else if territory_is_water(t) {
				territory_value_map[t] = 0.0
			}
		} else if territory_is_water(t) {
			territory_value_map[t] = 0.0
		}
	}
	return territory_value_map
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils#findTerritoryAttackValue(ProData,GamePlayer,Territory)
// Java:
//   public static double findTerritoryAttackValue(
//       final ProData proData, final GamePlayer player, final Territory t) {
//     final int isEnemyFactory =
//         ProMatches.territoryHasInfraFactoryAndIsEnemyLand(player).test(t) ? 1 : 0;
//     double value = 3.0 * TerritoryAttachment.getProduction(t) * (isEnemyFactory + 1);
//     if (ProUtils.isNeutralLand(t)) {
//       final double strength =
//           ProBattleUtils.estimateStrength(
//               t, new ArrayList<>(t.getUnits()), new ArrayList<>(), false);
//       final double tuvSwing = -(strength / 8) * proData.getMinCostPerHitPoint();
//       value += tuvSwing;
//     }
//     return value;
//   }
pro_territory_value_utils_find_territory_attack_value :: proc(
	pro_data: ^Pro_Data,
	player:   ^Game_Player,
	t:        ^Territory,
) -> f64 {
	enemy_factory_ctx := Pro_Matches_Ctx_territory_has_infra_factory_and_is_enemy_land{
		player = player,
	}
	is_enemy_factory: i32 = 0
	if pro_matches_pred_territory_has_infra_factory_and_is_enemy_land(rawptr(&enemy_factory_ctx), t) {
		is_enemy_factory = 1
	}
	value := 3.0 * f64(territory_attachment_static_get_production(t)) * f64(is_enemy_factory + 1)
	if pro_utils_is_neutral_land(t) {
		my_units: [dynamic]^Unit
		uc := territory_get_unit_collection(t)
		for u in uc.units {
			append(&my_units, u)
		}
		enemy_units: [dynamic]^Unit
		strength := pro_battle_utils_estimate_strength(t, my_units, enemy_units, false)
		tuv_swing := -(strength / 8.0) * pro_data_get_min_cost_per_hit_point(pro_data)
		value += tuv_swing
	}
	return value
}

// Adapter ctx + trampoline for the Java BiPredicate<Territory,Territory>
//   (t1, t2) ->
//       ProMatches.territoryCanPotentiallyMoveLandUnits(player).test(t2)
//           && ProMatches.noCanalsBetweenTerritories(player).test(t1, t2);
// constructed inside findLandValue. Captures `player`. Delegates to the
// already-defined synthetic
// pro_territory_value_utils_lambda_find_land_value_2 (which inlines the
// two ProMatches predicates against stack-local ctx structs).
Pro_Territory_Value_Utils_Find_Land_Value_2_Ctx :: struct {
	player: ^Game_Player,
}

pro_territory_value_utils_lambda_find_land_value_2_trampoline :: proc(
	ctx_ptr: rawptr,
	t1: ^Territory,
	t2: ^Territory,
) -> bool {
	c := cast(^Pro_Territory_Value_Utils_Find_Land_Value_2_Ctx)ctx_ptr
	return pro_territory_value_utils_lambda_find_land_value_2(c.player, t1, t2)
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #findLandValue(ProData, Territory, GamePlayer, int,
//       Map<Territory,Double>, List<Territory>, List<Territory>)
// Java:
//   if (territoriesThatCantBeHeld.contains(t)) return 0.0;
//   final List<Double> values = new ArrayList<>();
//   final GameData data = proData.getData();
//   final Collection<Territory> nearbyEnemyCapitalsAndFactories =
//       findNearbyEnemyCapitalsAndFactories(t, enemyCapitalsAndFactoriesMap.keySet());
//   final BiPredicate<Territory, Territory> routeCond =
//       (t1, t2) ->
//           ProMatches.territoryCanPotentiallyMoveLandUnits(player).test(t2)
//               && ProMatches.noCanalsBetweenTerritories(player).test(t1, t2);
//   for (final Territory enemyCapitalOrFactory : nearbyEnemyCapitalsAndFactories) {
//     final int distance = data.getMap().getDistance(t, enemyCapitalOrFactory, routeCond);
//     if (distance > 0) {
//       values.add(enemyCapitalsAndFactoriesMap.get(enemyCapitalOrFactory) / Math.pow(2, distance));
//     }
//   }
//   values.sort(Collections.reverseOrder());
//   double capitalOrFactoryValue = 0;
//   for (int i = 0; i < values.size(); i++) {
//     capitalOrFactoryValue += values.get(i) / Math.pow(2, i);
//   }
//   double nearbyEnemyValue = 0;
//   final Set<Territory> nearbyTerritories = data.getMap().getNeighbors(t, 2, routeCond);
//   final List<Territory> nearbyEnemyTerritories =
//       CollectionUtils.getMatches(nearbyTerritories,
//           ProMatches.territoryIsEnemyOrCantBeHeld(player, territoriesThatCantBeHeld));
//   nearbyEnemyTerritories.removeAll(territoriesToAttack);
//   for (final Territory nearbyEnemyTerritory : nearbyEnemyTerritories) {
//     final int distance = data.getMap().getDistance(t, nearbyEnemyTerritory, routeCond);
//     if (distance > 0) {
//       double value = TerritoryAttachment.getProduction(nearbyEnemyTerritory);
//       if (ProUtils.isNeutralLand(nearbyEnemyTerritory)) {
//         value = findTerritoryAttackValue(proData, player, nearbyEnemyTerritory) / 3;
//       } else if (ProMatches.territoryIsAlliedLandAndHasNoEnemyNeighbors(player)
//           .test(nearbyEnemyTerritory)) {
//         value *= 0.1;
//       }
//       if (value > 0) {
//         nearbyEnemyValue += (value / Math.pow(2, distance));
//       }
//     }
//   }
//   final int landMassSize = 1 + data.getMap().getNeighbors(t, 6, routeCond).size();
//   double value = nearbyEnemyValue * landMassSize / maxLandMassSize + capitalOrFactoryValue;
//   if (ProMatches.territoryHasInfraFactoryAndIsLand().test(t)) value *= 1.1;
//   return value;
//
// Notes:
// - `enemyCapitalsAndFactoriesMap.keySet()` is mirrored as the keys of
//   the `map[^Territory]f64` map; we pass it as a Set<Territory>-shaped
//   `map[^Territory]struct{}` (the shape that
//   `pro_territory_value_utils_find_nearby_enemy_capitals_and_factories`
//   accepts) by materializing a transient set view.
// - `routeCond` is a capturing BiPredicate; we use the rawptr-ctx form
//   per llm-instructions.md, paired with the trampoline above.
// - `Collections.reverseOrder()` on `List<Double>` is rendered as
//   `slice.sort` ascending then a reverse iteration via index
//   `len-1-i`, which yields descending order without an extra reverse
//   pass.
// - `CollectionUtils.getMatches` and `removeAll(territoriesToAttack)` are
//   inlined as a filter-then-skip loop (the same pattern used by
//   findEnemyCapitalsAndFactoriesValue / findSeaTerritoryValues above).
@(private = "file")
pro_territory_value_utils_find_land_value :: proc(
	pro_data:                         ^Pro_Data,
	t:                                ^Territory,
	player:                           ^Game_Player,
	max_land_mass_size:               i32,
	enemy_capitals_and_factories_map: map[^Territory]f64,
	territories_that_cant_be_held:    [dynamic]^Territory,
	territories_to_attack:            [dynamic]^Territory,
) -> f64 {
	for tt in territories_that_cant_be_held {
		if tt == t {
			return 0.0
		}
	}

	values := make([dynamic]f64)
	defer delete(values)
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	enemy_keys := make(map[^Territory]struct {})
	defer delete(enemy_keys)
	for k in enemy_capitals_and_factories_map {
		enemy_keys[k] = {}
	}
	nearby_enemy_capitals_and_factories :=
		pro_territory_value_utils_find_nearby_enemy_capitals_and_factories(t, &enemy_keys)
	defer delete(nearby_enemy_capitals_and_factories)

	route_cond_ctx := new(Pro_Territory_Value_Utils_Find_Land_Value_2_Ctx)
	route_cond_ctx.player = player

	for enemy_cap_or_factory in nearby_enemy_capitals_and_factories {
		distance := game_map_get_distance_bipredicate(
			game_map,
			t,
			enemy_cap_or_factory,
			pro_territory_value_utils_lambda_find_land_value_2_trampoline,
			rawptr(route_cond_ctx),
		)
		if distance > 0 {
			append(
				&values,
				enemy_capitals_and_factories_map[enemy_cap_or_factory] /
				math.pow(2.0, f64(distance)),
			)
		}
	}

	slice.sort(values[:])
	capital_or_factory_value: f64 = 0
	n := len(values)
	for i in 0 ..< n {
		// descending order via reverse index
		capital_or_factory_value += values[n - 1 - i] / math.pow(2.0, f64(i))
	}

	nearby_enemy_value: f64 = 0
	nearby_territories := game_map_get_neighbors_distance_bipredicate(
		game_map,
		t,
		2,
		pro_territory_value_utils_lambda_find_land_value_2_trampoline,
		rawptr(route_cond_ctx),
	)
	defer delete(nearby_territories)

	enemy_or_cant_pred, enemy_or_cant_ctx := pro_matches_territory_is_enemy_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)
	allied_no_enemy_pred, allied_no_enemy_ctx :=
		pro_matches_territory_is_allied_land_and_has_no_enemy_neighbors(player)

	for nearby_enemy_territory in nearby_territories {
		if !enemy_or_cant_pred(enemy_or_cant_ctx, nearby_enemy_territory) {
			continue
		}
		// removeAll(territoriesToAttack)
		in_attack := false
		for at in territories_to_attack {
			if at == nearby_enemy_territory {
				in_attack = true
				break
			}
		}
		if in_attack {
			continue
		}
		distance := game_map_get_distance_bipredicate(
			game_map,
			t,
			nearby_enemy_territory,
			pro_territory_value_utils_lambda_find_land_value_2_trampoline,
			rawptr(route_cond_ctx),
		)
		if distance > 0 {
			value := f64(territory_attachment_static_get_production(nearby_enemy_territory))
			if pro_utils_is_neutral_land(nearby_enemy_territory) {
				value =
					pro_territory_value_utils_find_territory_attack_value(
						pro_data,
						player,
						nearby_enemy_territory,
					) /
					3.0
			} else if allied_no_enemy_pred(allied_no_enemy_ctx, nearby_enemy_territory) {
				value *= 0.1
			}
			if value > 0 {
				nearby_enemy_value += value / math.pow(2.0, f64(distance))
			}
		}
	}

	land_mass_neighbors := game_map_get_neighbors_distance_bipredicate(
		game_map,
		t,
		6,
		pro_territory_value_utils_lambda_find_land_value_2_trampoline,
		rawptr(route_cond_ctx),
	)
	defer delete(land_mass_neighbors)
	land_mass_size: i32 = 1 + i32(len(land_mass_neighbors))

	value :=
		nearby_enemy_value * f64(land_mass_size) / f64(max_land_mass_size) +
		capital_or_factory_value
	is_land_pred, is_land_ctx := pro_matches_territory_has_infra_factory_and_is_land()
	if is_land_pred(is_land_ctx, t) {
		value *= 1.1
	}
	return value
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #findWaterValue(ProData, Territory, GamePlayer, int,
//       Map<Territory,Double>, List<Territory>, List<Territory>,
//       Map<Territory,Double>)
// Java:
//   final GameState data = proData.getData();
//   if (territoriesThatCantBeHeld.contains(t)
//       || data.getMap().getNeighbors(t, Matches.territoryIsWater()).isEmpty()) {
//     return 0.0;
//   }
//   final List<Double> values = new ArrayList<>();
//   final Collection<Territory> nearbyEnemyCapitalsAndFactories =
//       findNearbyEnemyCapitalsAndFactories(t, enemyCapitalsAndFactoriesMap.keySet());
//   for (final Territory enemyCapitalOrFactory : nearbyEnemyCapitalsAndFactories) {
//     final Optional<Route> optionalRoute =
//         data.getMap().getRouteForUnits(t, enemyCapitalOrFactory,
//             ProMatches.territoryCanMoveSeaUnits(player, true), Set.of(), player);
//     if (optionalRoute.isEmpty()) continue;
//     final int distance = optionalRoute.get().numberOfSteps();
//     if (distance > 0) {
//       values.add(enemyCapitalsAndFactoriesMap.get(enemyCapitalOrFactory)
//           / Math.pow(2, distance));
//     }
//   }
//   values.sort(Collections.reverseOrder());
//   double capitalOrFactoryValue = 0;
//   for (int i = 0; i < values.size(); i++) {
//     capitalOrFactoryValue += values.get(i) / Math.pow(2, i);
//   }
//   double nearbyLandValue = 0;
//   final Set<Territory> nearbyTerritories = data.getMap()
//       .getNeighborsIgnoreEnd(t, 3, ProMatches.territoryCanMoveSeaUnits(player, true));
//   final List<Territory> nearbyLandTerritories = CollectionUtils.getMatches(
//       nearbyTerritories, ProMatches.territoryCanPotentiallyMoveLandUnits(player));
//   nearbyLandTerritories.removeAll(territoriesToAttack);
//   for (final Territory nearbyLandTerritory : nearbyLandTerritories) {
//     final Optional<Route> optionalRoute = data.getMap().getRouteForUnits(...);
//     if (optionalRoute.isEmpty()) continue;
//     final int distance = optionalRoute.get().numberOfSteps();
//     if (distance > 0 && distance <= 3) {
//       if (ProMatches.territoryIsEnemyOrCantBeHeld(player, territoriesThatCantBeHeld)
//           .test(nearbyLandTerritory)) {
//         double value = TerritoryAttachment.getProduction(nearbyLandTerritory);
//         if (ProUtils.isNeutralLand(nearbyLandTerritory)) {
//           value = findTerritoryAttackValue(proData, player, nearbyLandTerritory);
//         }
//         nearbyLandValue += value;
//       }
//       if (!territoryValueMap.containsKey(nearbyLandTerritory)) {
//         final double value = findLandValue(...);
//         territoryValueMap.put(nearbyLandTerritory, value);
//       }
//       nearbyLandValue += territoryValueMap.get(nearbyLandTerritory);
//     }
//   }
//   return capitalOrFactoryValue / 100 + nearbyLandValue / 10;
//
// Notes:
// - `territoryValueMap` is mutated (memoization cache for findLandValue
//   results), so it is passed as `^map[^Territory]f64` to ensure growth
//   is observed by the caller.
// - `enemyCapitalsAndFactoriesMap.keySet()` is materialized as a
//   transient `map[^Territory]struct{}` for the
//   `findNearbyEnemyCapitalsAndFactories` helper, mirroring the same
//   pattern used by `find_land_value` above.
// - `data.getMap().getRouteForUnits(...)` is bypassed in favor of
//   constructing a `Route_Finder` directly via
//   `route_finder_new_with_units_player` + `find_route_by_cost_pair`,
//   the same pattern used by `calculate_territory_value_to_targets`
//   (the sea-units predicate is the rawptr-ctx form that Route_Finder
//   itself takes).
// - `Set.of()` (empty unmodifiable Set<Unit>) is mirrored as the
//   zero-value `[dynamic]^Unit`.
// - `Collections.reverseOrder()` over `List<Double>` is rendered as
//   `slice.sort` ascending then a reverse-index iteration to walk the
//   sorted slice in descending order.
// - `CollectionUtils.getMatches(...)` and `removeAll(territoriesToAttack)`
//   are inlined as a filter-then-skip loop, matching the surrounding
//   procs in this file.
@(private = "file")
pro_territory_value_utils_find_water_value :: proc(
	pro_data:                         ^Pro_Data,
	t:                                ^Territory,
	player:                           ^Game_Player,
	max_land_mass_size:               i32,
	enemy_capitals_and_factories_map: map[^Territory]f64,
	territories_that_cant_be_held:    [dynamic]^Territory,
	territories_to_attack:            [dynamic]^Territory,
	territory_value_map:              ^map[^Territory]f64,
) -> f64 {
	data := pro_data_get_data(pro_data)
	game_map := game_data_get_map(data)

	for tt in territories_that_cant_be_held {
		if tt == t {
			return 0.0
		}
	}
	water_pred, water_ctx := matches_territory_is_water()
	water_neighbors := game_map_get_neighbors_predicate(game_map, t, water_pred, water_ctx)
	defer delete(water_neighbors)
	if len(water_neighbors) == 0 {
		return 0.0
	}

	// Determine value based on enemy factory distance
	values := make([dynamic]f64)
	defer delete(values)

	enemy_keys := make(map[^Territory]struct {})
	defer delete(enemy_keys)
	for k in enemy_capitals_and_factories_map {
		enemy_keys[k] = {}
	}
	nearby_enemy_capitals_and_factories :=
		pro_territory_value_utils_find_nearby_enemy_capitals_and_factories(t, &enemy_keys)
	defer delete(nearby_enemy_capitals_and_factories)

	sea_pred, sea_ctx := pro_matches_territory_can_move_sea_units(player, true)
	empty_units: [dynamic]^Unit

	for enemy_cap_or_factory in nearby_enemy_capitals_and_factories {
		rf := route_finder_new_with_units_player(
			game_map,
			sea_pred,
			sea_ctx,
			empty_units,
			player,
		)
		optional_route := route_finder_find_route_by_cost_pair(rf, t, enemy_cap_or_factory)
		if optional_route == nil {
			continue
		}
		distance := route_number_of_steps(optional_route)
		if distance > 0 {
			append(
				&values,
				enemy_capitals_and_factories_map[enemy_cap_or_factory] /
				math.pow(2.0, f64(distance)),
			)
		}
	}
	slice.sort(values[:])
	capital_or_factory_value: f64 = 0
	n := len(values)
	for i in 0 ..< n {
		// descending order via reverse index
		capital_or_factory_value += values[n - 1 - i] / math.pow(2.0, f64(i))
	}

	// Determine value based on nearby territory production
	nearby_land_value: f64 = 0
	nearby_territories := game_map_get_neighbors_ignore_end(
		game_map,
		t,
		3,
		sea_pred,
		sea_ctx,
	)
	defer delete(nearby_territories)

	can_move_land_pred, can_move_land_ctx := pro_matches_territory_can_potentially_move_land_units(player)
	enemy_or_cant_pred, enemy_or_cant_ctx := pro_matches_territory_is_enemy_or_cant_be_held(
		player,
		territories_that_cant_be_held,
	)

	for nearby_land_territory in nearby_territories {
		if !can_move_land_pred(can_move_land_ctx, nearby_land_territory) {
			continue
		}
		// removeAll(territoriesToAttack)
		in_attack := false
		for at in territories_to_attack {
			if at == nearby_land_territory {
				in_attack = true
				break
			}
		}
		if in_attack {
			continue
		}
		rf := route_finder_new_with_units_player(
			game_map,
			sea_pred,
			sea_ctx,
			empty_units,
			player,
		)
		optional_route := route_finder_find_route_by_cost_pair(rf, t, nearby_land_territory)
		if optional_route == nil {
			continue
		}
		distance := route_number_of_steps(optional_route)
		if distance > 0 && distance <= 3 {
			if enemy_or_cant_pred(enemy_or_cant_ctx, nearby_land_territory) {
				value := f64(territory_attachment_static_get_production(nearby_land_territory))
				if pro_utils_is_neutral_land(nearby_land_territory) {
					value = pro_territory_value_utils_find_territory_attack_value(
						pro_data,
						player,
						nearby_land_territory,
					)
				}
				nearby_land_value += value
			}
			if _, has := territory_value_map[nearby_land_territory]; !has {
				v := pro_territory_value_utils_find_land_value(
					pro_data,
					nearby_land_territory,
					player,
					max_land_mass_size,
					enemy_capitals_and_factories_map,
					territories_that_cant_be_held,
					territories_to_attack,
				)
				territory_value_map[nearby_land_territory] = v
			}
			nearby_land_value += territory_value_map[nearby_land_territory]
		}
	}

	return capital_or_factory_value / 100.0 + nearby_land_value / 10.0
}

// games.strategy.triplea.ai.pro.util.ProTerritoryValueUtils
//   #findTerritoryValues(ProData, GamePlayer, List<Territory>,
//       List<Territory>, Set<Territory>) -> Map<Territory, Double>
// Java:
//   final int maxLandMassSize = findMaxLandMassSize(player);
//   final Map<Territory, Double> enemyCapitalsAndFactoriesMap =
//       findEnemyCapitalsAndFactoriesValue(player, maxLandMassSize,
//           territoriesThatCantBeHeld, territoriesToAttack);
//   final Map<Territory, Double> territoryValueMap = new HashMap<>();
//   for (final Territory t : territoriesToCheck) {
//     if (!t.isWater()) {
//       final double value = findLandValue(proData, t, player,
//           maxLandMassSize, enemyCapitalsAndFactoriesMap,
//           territoriesThatCantBeHeld, territoriesToAttack);
//       territoryValueMap.put(t, value);
//     }
//   }
//   for (final Territory t : territoriesToCheck) {
//     if (t.isWater()) {
//       final double value = findWaterValue(proData, t, player,
//           maxLandMassSize, enemyCapitalsAndFactoriesMap,
//           territoriesThatCantBeHeld, territoriesToAttack,
//           territoryValueMap);
//       territoryValueMap.put(t, value);
//     }
//   }
//   return territoryValueMap;
//
// Notes:
// - `territoriesToCheck` is a `Set<Territory>`; mirrored as the
//   `map[^Territory]struct{}` shape used elsewhere in this file.
// - The land pass runs first (populating the cache) so the water
//   pass's `findWaterValue` can reuse the cached land values via the
//   `territory_value_map` parameter (mutated by reference).
pro_territory_value_utils_find_territory_values :: proc(
	pro_data:                      ^Pro_Data,
	player:                        ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
	territories_to_attack:         [dynamic]^Territory,
	territories_to_check:          map[^Territory]struct {},
) -> map[^Territory]f64 {
	max_land_mass_size := pro_territory_value_utils_find_max_land_mass_size(player)
	enemy_capitals_and_factories_map :=
		pro_territory_value_utils_find_enemy_capitals_and_factories_value(
			player,
			max_land_mass_size,
			territories_that_cant_be_held,
			territories_to_attack,
		)
	defer delete(enemy_capitals_and_factories_map)

	territory_value_map := make(map[^Territory]f64)
	for t in territories_to_check {
		if !territory_is_water(t) {
			value := pro_territory_value_utils_find_land_value(
				pro_data,
				t,
				player,
				max_land_mass_size,
				enemy_capitals_and_factories_map,
				territories_that_cant_be_held,
				territories_to_attack,
			)
			territory_value_map[t] = value
		}
	}
	for t in territories_to_check {
		if territory_is_water(t) {
			value := pro_territory_value_utils_find_water_value(
				pro_data,
				t,
				player,
				max_land_mass_size,
				enemy_capitals_and_factories_map,
				territories_that_cant_be_held,
				territories_to_attack,
				&territory_value_map,
			)
			territory_value_map[t] = value
		}
	}
	return territory_value_map
}
