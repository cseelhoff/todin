package game

import "core:fmt"

Game_Map :: struct {
	using game_data_component: Game_Data_Component,
	territories:      [dynamic]^Territory,
	connections:      map[^Territory]map[^Territory]struct{},
	territory_lookup: map[string]^Territory,
	grid_dimensions:  []i32,
}

// Mirrors Java GameMap#getNeighbors(Territory, int):
//     return getNeighbors(territory, distance, it -> true);
game_map_get_neighbors_distance :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	distance: i32,
) -> map[^Territory]struct{} {
	return game_map_get_neighbors_distance_predicate(self, territory, distance, nil, nil)
}

// Mirrors Java GameMap#getNeighbors(Territory, @Nullable Predicate<Territory>):
// Returns all adjacent neighbors of the starting territory that match the
// condition. Does NOT include the original/starting territory in the returned
// set. Java delegates to the private BiPredicate overload via
// `(it, it2) -> territoryCondition == null || territoryCondition.test(it2)`,
// which simplifies to filtering adjacent neighbors by the predicate. A nil
// `cond` means "no filter" (matches Java's @Nullable territoryCondition).
// Closure capture follows the rawptr-ctx convention (see llm-instructions.md).
game_map_get_neighbors_predicate :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	result := make(map[^Territory]struct{})
	neighbors := game_map_get_neighbors(self, territory)
	for n in neighbors {
		if cond == nil || cond(cond_ctx, n) {
			result[n] = {}
		}
	}
	return result
}

// Returns the distance between two territories or -1 if they are not connected.
game_map_get_distance :: proc(self: ^Game_Map, t1: ^Territory, t2: ^Territory) -> i32 {
	return game_map_get_distance_predicate(self, t1, t2, game_map_lambda_get_distance_14, nil)
}

// Java synthetic lambda: GameMap#lambda$getDistance$14(Territory) -> boolean.
// Originates from `getDistance(t1, t2)` calling `getDistance(t1, t2, it -> true)`.
game_map_lambda_get_distance_14 :: proc(_ctx: rawptr, _t: ^Territory) -> bool {
	return true
}

// Adapter ctx for bridging a Predicate<Territory> (under the rawptr-ctx
// convention) into the BiPredicate-shaped (rawptr, ^Territory, ^Territory)
// -> bool form expected by game_map_get_distance_bipredicate. Mirrors the
// Java lambda `(it, it2) -> cond.test(it2)` in
// GameMap.getDistance(t1, t2, Predicate), which captures `cond`. Per the
// closure-capture convention (llm-instructions.md), we heap-allocate a
// small ctx struct holding the inner predicate + its userdata and pass a
// non-capturing trampoline.
Game_Map_Distance_Predicate_Ctx :: struct {
	cond:     proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
}

game_map_distance_predicate_trampoline :: proc(
	ctx: rawptr,
	_: ^Territory,
	t2: ^Territory,
) -> bool {
	inner := cast(^Game_Map_Distance_Predicate_Ctx)ctx
	return inner.cond(inner.cond_ctx, t2)
}

// Alias for naming consistency with the Java synthetic lambda
// `GameMap#lambda$getDistance$15(Predicate, Territory, Territory)`.
game_map_lambda_get_distance_15 :: game_map_distance_predicate_trampoline

// Mirrors GameMap.getDistance(Territory, Territory, Predicate<Territory>):
//     return getDistance(t1, t2, (it, it2) -> cond.test(it2));
// The Java lambda captures `cond`, so we route through the BiPredicate
// overload using the rawptr-ctx convention (see llm-instructions.md).
game_map_get_distance_predicate :: proc(
	self: ^Game_Map,
	t1: ^Territory,
	t2: ^Territory,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> i32 {
	inner := new(Game_Map_Distance_Predicate_Ctx)
	inner.cond = cond
	inner.cond_ctx = cond_ctx
	return game_map_get_distance_bipredicate(
		self,
		t1,
		t2,
		game_map_distance_predicate_trampoline,
		inner,
	)
}

// Returns all adjacent neighbors of the starting territory. Does NOT include
// the original/starting territory in the returned set. Mirrors
// GameMap.getNeighbors(Territory) in Java; throws if the territory has no
// entry in the connections map.
game_map_get_neighbors :: proc(self: ^Game_Map, territory: ^Territory) -> map[^Territory]struct{} {
	neighbors, ok := self.connections[territory]
	if !ok {
		fmt.panicf("No neighbors for: %v", territory)
	}
	return neighbors
}

// Mirrors private GameMap.getNeighbors(Territory, BiPredicate<Territory,
// Territory> routeCondition):
//     return getNeighbors(territory).stream()
//         .filter(n -> routeCondition.test(territory, n))
//         .collect(Collectors.toSet());
// The BiPredicate is rendered with the rawptr-ctx convention from
// llm-instructions.md so the Java capturing lambdas at call sites can be
// represented faithfully.
game_map_get_neighbors_bipredicate :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	cond: proc(rawptr, ^Territory, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	result := make(map[^Territory]struct{})
	for n in game_map_get_neighbors(self, territory) {
		if cond(cond_ctx, territory, n) {
			result[n] = {}
		}
	}
	return result
}

// Mirrors GameMap.getNeighbors(Territory, int, BiPredicate<Territory,Territory>):
// Returns all neighbors within `distance` of `territory` whose route from
// each predecessor satisfies `cond`. Does NOT include the starting territory.
// `cond` is called as `cond(cond_ctx, from, to)` at every frontier step,
// matching the Java BiPredicate.test(from, to) convention.
game_map_get_neighbors_distance_bipredicate :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	distance: i32,
	cond: proc(rawptr, ^Territory, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	if distance < 0 {
		fmt.panicf("Distance must be non-negative: %v", distance)
	}
	if distance == 0 {
		return make(map[^Territory]struct{})
	}
	neighbors := game_map_get_neighbors_bipredicate(self, territory, cond, cond_ctx)
	if distance == 1 {
		return neighbors
	}
	// Mirrors the private Java helper getNeighbors(frontier, searched,
	// distance-1, routeCondition): BFS that seeds `searched` with the
	// initial neighbor set and expands outward, filtering each new step
	// through `cond` (via game_map_get_neighbors_bipredicate).
	searched := make(map[^Territory]struct{})
	for t in neighbors {
		searched[t] = {}
	}
	frontier := make(map[^Territory]struct{})
	for t in neighbors {
		frontier[t] = {}
	}
	remaining := distance - 1
	for remaining > 0 && len(frontier) > 0 {
		new_frontier := make(map[^Territory]struct{})
		for t in frontier {
			step := game_map_get_neighbors_bipredicate(self, t, cond, cond_ctx)
			for n in step {
				if _, seen := searched[n]; !seen {
					new_frontier[n] = {}
				}
			}
		}
		for n in new_frontier {
			searched[n] = {}
		}
		frontier = new_frontier
		remaining -= 1
	}
	// Java: result.remove(territory)
	delete_key(&searched, territory)
	return searched
}

// Adapter ctx for bridging a Predicate<Territory> (under the rawptr-ctx
// convention) into the BiPredicate-shaped (rawptr, ^Territory, ^Territory)
// -> bool form expected by game_map_get_neighbors_distance_bipredicate.
// Mirrors the Java lambda
//     `(it, it2) -> territoryCondition == null || territoryCondition.test(it2)`
// in GameMap.getNeighbors(Territory, int, @Nullable Predicate<Territory>),
// which captures `territoryCondition`. Per the closure-capture convention
// (llm-instructions.md), we heap-allocate a small ctx struct holding the
// inner predicate + its userdata and pass a non-capturing trampoline.
Game_Map_Neighbors_Distance_Predicate_Ctx :: struct {
	cond:     proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
}

game_map_neighbors_distance_predicate_trampoline :: proc(
	ctx: rawptr,
	_: ^Territory,
	it2: ^Territory,
) -> bool {
	inner := cast(^Game_Map_Neighbors_Distance_Predicate_Ctx)ctx
	return inner.cond == nil || inner.cond(inner.cond_ctx, it2)
}

// Java synthetic: GameMap#lambda$getNeighbors$1(Predicate, Territory, Territory).
// Alias for the trampoline above — the javac-generated lambda body is exactly
// `cond == null || cond.test(t2)`, which matches
// `game_map_neighbors_distance_predicate_trampoline`.
game_map_lambda_get_neighbors_1 :: game_map_neighbors_distance_predicate_trampoline

// Mirrors public GameMap.getNeighbors(Territory, int, @Nullable Predicate<Territory>):
//     return getNeighbors(
//         territory,
//         distance,
//         (it, it2) -> territoryCondition == null || territoryCondition.test(it2));
// The Java lambda captures `territoryCondition` (cond+cond_ctx under the
// rawptr-ctx convention), so we route through the BiPredicate overload via
// the heap-allocated trampoline pattern (see llm-instructions.md).
game_map_get_neighbors_distance_predicate :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	distance: i32,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	inner := new(Game_Map_Neighbors_Distance_Predicate_Ctx)
	inner.cond = cond
	inner.cond_ctx = cond_ctx
	return game_map_get_neighbors_distance_bipredicate(
		self,
		territory,
		distance,
		game_map_neighbors_distance_predicate_trampoline,
		inner,
	)
}

// Bidirectional. T1 connects to T2, and T2 connects to T1. Mirrors
// GameMap.addConnection(Territory, Territory) in Java.
game_map_add_connection :: proc(self: ^Game_Map, t1: ^Territory, t2: ^Territory) {
	if t1 == t2 {
		fmt.panicf("Cannot connect a territory to itself: %v", t1)
	}
	found_t1, found_t2 := false, false
	for t in self.territories {
		if t == t1 do found_t1 = true
		if t == t2 do found_t2 = true
	}
	if !found_t1 || !found_t2 {
		fmt.panicf("Missing territory definition for either %v or %v", t1, t2)
	}
	// setConnection(t1, t2)
	neighbors_1 := game_map_get_neighbors(self, t1)
	neighbors_1[t2] = {}
	self.connections[t1] = neighbors_1
	// setConnection(t2, t1)
	neighbors_2 := game_map_get_neighbors(self, t2)
	neighbors_2[t1] = {}
	self.connections[t2] = neighbors_2
}

// Mirrors GameMap.addTerritory(Territory). Rejects duplicates (by Java's
// List.contains semantics, which delegate to Territory.equals -> name
// comparison via DefaultNamed), then registers the territory in the
// territories list, the connections map (with an empty neighbor set),
// and the name->territory lookup table.
game_map_add_territory :: proc(self: ^Game_Map, territory: ^Territory) {
	for existing in self.territories {
		if existing == territory ||
		   existing.named.base.name == territory.named.base.name {
			fmt.panicf("Map already contains %s", territory.named.base.name)
		}
	}
	append(&self.territories, territory)
	self.connections[territory] = make(map[^Territory]struct{})
	self.territory_lookup[territory.named.base.name] = territory
}

// Mirrors GameMap.getTerritories(): returns an unmodifiable view of the
// territories list. In Odin we return the backing dynamic array directly;
// callers must not mutate it.
game_map_get_territories :: proc(self: ^Game_Map) -> [dynamic]^Territory {
	return self.territories
}

// Case-sensitive lookup for a Territory by name. Mirrors
// GameMap.getTerritoryOrNull(String); returns nil if no territory with the
// given name is registered.
game_map_get_territory_or_null :: proc(self: ^Game_Map, name: string) -> ^Territory {
	return self.territory_lookup[name]
}

// Mirrors GameMap.getTerritoryOrThrow(String): returns the territory with
// the given name, or panics with the same message Java's
// IllegalArgumentException carries when no such territory exists.
game_map_get_territory_or_throw :: proc(self: ^Game_Map, name: string) -> ^Territory {
	territory, ok := self.territory_lookup[name]
	if !ok {
		fmt.panicf("Territory with name %s could not be found", name)
	}
	return territory
}

// Mirrors GameMap.getNeighborsIgnoreEnd(Territory, int, Predicate<Territory>):
// returns all neighbors within `distance` of `territory` where every
// territory between the two endpoints (i.e. all but the final hop)
// satisfies `cond`. Does NOT include the original/starting territory.
//
// The Java implementation recurses through a private overload taking a
// frontier+searched set; the BFS that overload performs is inlined here so
// this proc has no dependency on a not-yet-ported helper. The Java
// `territoryCondition` is `@Nullable`, so a nil `cond` is treated as
// always-true (matching the Java predicate-true sentinel used on the final
// hop, where `neighborCond = (distance == 1) ? t -> true : territoryCondition`).
// `cond` follows the rawptr-ctx closure convention from llm-instructions.md.
game_map_get_neighbors_ignore_end :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	distance: i32,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	fmt.assertf(distance >= 0, "Distance must be non-negative: %d", distance)
	neighbors := make(map[^Territory]struct{})
	if distance == 0 {
		return neighbors
	}
	// neighbors = new HashSet<>(getNeighbors(territory))
	direct := game_map_get_neighbors(self, territory)
	for t in direct {
		neighbors[t] = {}
	}
	if distance == 1 {
		return neighbors
	}
	// start = getNeighbors(territory, territoryCondition)
	start := make(map[^Territory]struct{})
	for t in direct {
		if cond == nil || cond(cond_ctx, t) {
			start[t] = {}
		}
	}
	// for (int i = 2; i <= distance; i++) {
	//     neighbors.addAll(getNeighborsIgnoreEnd(start, new HashSet<>(start), i - 1, territoryCondition));
	// }
	for i in 2 ..= distance {
		// Inlined private getNeighborsIgnoreEnd(frontier=start, searched=copy(start), steps=i-1, cond):
		frontier := make(map[^Territory]struct{})
		searched := make(map[^Territory]struct{})
		for t in start {
			frontier[t] = {}
			searched[t] = {}
		}
		steps := i - 1
		for steps != 0 && len(frontier) > 0 {
			// neighborCond = (steps == 1) ? t -> true : territoryCondition
			use_cond := steps != 1
			new_frontier := make(map[^Territory]struct{})
			for t in frontier {
				ns := game_map_get_neighbors(self, t)
				for n in ns {
					if use_cond && cond != nil && !cond(cond_ctx, n) {
						continue
					}
					if _, seen := searched[n]; seen {
						continue
					}
					new_frontier[n] = {}
				}
			}
			for n in new_frontier {
				searched[n] = {}
			}
			delete(frontier)
			frontier = new_frontier
			steps -= 1
		}
		// neighbors.addAll(searched)
		for t in searched {
			neighbors[t] = {}
		}
		delete(frontier)
		delete(searched)
	}
	delete(start)
	// neighbors.remove(territory)
	delete_key(&neighbors, territory)
	return neighbors
}

// Mirrors the private BFS helper
//   GameMap#getNeighbors(Set<Territory> frontier, Set<Territory> searched,
//                        int distance, BiPredicate<Territory, Territory> routeCondition)
// in Java. Recursively expands `frontier` one step at a time, accumulating
// every visited territory into `searched`, until `distance` reaches 0 or the
// frontier dries up. The BiPredicate is filtered against each (origin, neighbor)
// pair via the rawptr-ctx closure convention (see llm-instructions.md).
// The `searched` map is mutated in place, matching Java's HashSet semantics.
game_map_get_neighbors_set_set_distance_bipredicate :: proc(
	self: ^Game_Map,
	frontier: map[^Territory]struct{},
	searched: map[^Territory]struct{},
	distance: i32,
	cond: proc(rawptr, ^Territory, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	if distance == 0 || len(frontier) == 0 {
		return searched
	}
	new_frontier := make(map[^Territory]struct{})
	for t in frontier {
		neighbors := game_map_get_neighbors_bipredicate(self, t, cond, cond_ctx)
		for n in neighbors {
			if _, already := searched[n]; !already {
				new_frontier[n] = {}
			}
		}
	}
	searched := searched
	for n in new_frontier {
		searched[n] = {}
	}
	return game_map_get_neighbors_set_set_distance_bipredicate(
		self,
		new_frontier,
		searched,
		distance - 1,
		cond,
		cond_ctx,
	)
}

// Mirrors Java GameMap#getRouteForUnit(Territory, Territory, Predicate<Territory>, Unit, GamePlayer):
//     return getRouteForUnits(start, end, cond, List.of(unit), player);
game_map_get_route_for_unit :: proc(
	self: ^Game_Map,
	start: ^Territory,
	end: ^Territory,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
	unit: ^Unit,
	player: ^Game_Player,
) -> ^Route {
	units := make([dynamic]^Unit, 0, 1)
	append(&units, unit)
	return game_map_get_route_for_units(self, start, end, cond, cond_ctx, units, player)
}

// Mirrors the private Java helper:
//     private Set<Territory> getNeighborsIgnoreEnd(
//         Set<Territory> frontier, Set<Territory> searched,
//         int distance, @Nullable Predicate<Territory> territoryCondition)
// BFS step used by the public getNeighborsIgnoreEnd. At distance==1 the
// predicate is replaced by an always-true filter (matches Java's
// `(distance == 1) ? territory -> true : territoryCondition`); otherwise
// `cond` is applied (a nil ctx-proc is treated as always-true, matching
// Java's @Nullable handling in the underlying getNeighbors(t, Predicate)
// overload). `searched` is mutated in place (Java does the same).
game_map_get_neighbors_ignore_end_set_set :: proc(
	self: ^Game_Map,
	frontier: map[^Territory]struct{},
	searched: map[^Territory]struct{},
	distance: i32,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	if distance == 0 || len(frontier) == 0 {
		return searched
	}
	apply_cond := distance != 1 && cond != nil
	new_frontier := make(map[^Territory]struct{})
	for t in frontier {
		// getNeighbors(t, neighborCond): adjacent neighbors of t filtered
		// by neighborCond. Inlined here because our predicate carries a
		// rawptr ctx and the existing predicate-flavored getNeighbors
		// helpers take the non-capturing or BiPredicate forms.
		adj := game_map_get_neighbors(self, t)
		for n in adj {
			if apply_cond && !cond(cond_ctx, n) {
				continue
			}
			if _, seen := searched[n]; seen {
				continue
			}
			new_frontier[n] = {}
		}
	}
	searched := searched
	for n in new_frontier {
		searched[n] = {}
	}
	return game_map_get_neighbors_ignore_end_set_set(
		self,
		new_frontier,
		searched,
		distance - 1,
		cond,
		cond_ctx,
	)
}

// Mirrors public GameMap.getNeighborsByMovementCost(
//     Territory, BigDecimal movementLeft, Predicate<Territory> territoryCondition):
//     checkArgument(movementLeft.compareTo(BigDecimal.ZERO) >= 0, ...);
//     if (movementLeft.compareTo(BigDecimal.ZERO) == 0) return new HashSet<>();
//     final Set<Territory> neighbors = getNeighbors(territory, territoryCondition);
//     if (movementLeft.compareTo(BigDecimal.ONE) <= 0) return neighbors;
//     final Set<Territory> result = getNeighbors(
//         neighbors,
//         new HashSet<>(neighbors),
//         movementLeft.intValue() - 1,
//         (it, it2) -> territoryCondition.test(it2));
//     result.remove(territory);
//     return result;
// BigDecimal -> f64 (per llm-instructions.md). The capturing lambda
// `(it, it2) -> territoryCondition.test(it2)` is rendered through the
// rawptr-ctx convention, reusing the heap-allocated trampoline already
// defined for getNeighbors(Territory, int, Predicate) since the lambda
// shape is identical (ignore origin, test candidate). BigDecimal.intValue()
// truncates toward zero; for non-negative `max_cost` this matches `i32(...)`.
game_map_get_neighbors_by_movement_cost :: proc(
	self: ^Game_Map,
	territory: ^Territory,
	max_cost: f64,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	if max_cost < 0 {
		fmt.panicf("MovementLeft must be non-negative: %v", max_cost)
	}
	if max_cost == 0 {
		return make(map[^Territory]struct{})
	}
	neighbors := game_map_get_neighbors_predicate(self, territory, cond, cond_ctx)
	if max_cost <= 1 {
		return neighbors
	}
	// Java: new HashSet<>(neighbors) — copy used as the initial `searched`
	// set so the recursive helper's mutation does not alias `neighbors`.
	searched := make(map[^Territory]struct{})
	for t in neighbors {
		searched[t] = {}
	}
	inner := new(Game_Map_Neighbors_Distance_Predicate_Ctx)
	inner.cond = cond
	inner.cond_ctx = cond_ctx
	result := game_map_get_neighbors_set_set_distance_bipredicate(
		self,
		neighbors,
		searched,
		i32(max_cost) - 1,
		game_map_neighbors_distance_predicate_trampoline,
		inner,
	)
	// Java: result.remove(territory)
	delete_key(&result, territory)
	return result
}

// Java synthetic: GameMap#lambda$getNeighborsByMovementCost$11(Predicate, Territory, Territory).
// The javac-generated lambda body is `territoryCondition.test(it2)` — the
// captured Predicate ignores `it` and tests the candidate territory.
game_map_lambda_get_neighbors_by_movement_cost_11 :: proc(
	predicate: proc(^Territory) -> bool,
	it: ^Territory,
	it2: ^Territory,
) -> bool {
	return predicate(it2)
}

// Mirrors Java GameMap#iterator() (from Iterable<Territory>):
//     return territories.iterator();
// Java returns an Iterator backed by the same underlying list. Odin's
// lightest equivalent is returning the underlying [dynamic]^Territory
// directly — callers iterate with `for t in game_map_iterator(m)`.
game_map_iterator :: proc(self: ^Game_Map) -> [dynamic]^Territory {
	return self.territories
}

// Java synthetic: GameMap#lambda$getNeighbors$2(Predicate, Territory, Territory).
// From `public Set<Territory> getNeighbors(Territory, @Nullable Predicate<Territory>)`:
//     return getNeighbors(
//         territory, (it, it2) -> territoryCondition == null || territoryCondition.test(it2));
// Body is identical to lambda$getNeighbors$1 — `cond == null || cond.test(t2)` —
// so we alias the same BiPredicate trampoline.
game_map_lambda_get_neighbors_2 :: game_map_neighbors_distance_predicate_trampoline

// Java synthetic: GameMap#lambda$getNeighbors$3(Territory) -> boolean.
// From `public Set<Territory> getNeighbors(Territory territory, int distance)`:
//     return getNeighbors(territory, distance, it -> true);
// Non-capturing Predicate<Territory> that always returns true. Written in
// the rawptr-ctx form to match the `proc(rawptr, ^Territory) -> bool`
// signature consumed by the predicate-flavored getNeighbors helpers
// (mirrors `game_map_lambda_get_distance_14`).
game_map_lambda_get_neighbors_3 :: proc(_ctx: rawptr, _t: ^Territory) -> bool {
	return true
}

// Java synthetic: GameMap#lambda$getNeighbors$4(Predicate, Territory, Territory) -> boolean.
// From `public Set<Territory> getNeighbors(Territory, int, @Nullable Predicate<Territory>)`:
//     return getNeighbors(
//         territory,
//         distance,
//         (it, it2) -> territoryCondition == null || territoryCondition.test(it2));
// The lambda captures `territoryCondition` and short-circuits to true when
// it is null. Body is identical to `lambda$getNeighbors$1` (the same null-OR
// BiPredicate appears at the public Predicate-only overload too), so this
// alias reuses the shared trampoline that consults the Predicate stored in
// `Game_Map_Neighbors_Distance_Predicate_Ctx`.
game_map_lambda_get_neighbors_4 :: game_map_neighbors_distance_predicate_trampoline

// Java synthetic: GameMap#lambda$getNeighbors$5(Predicate, Territory, Territory) -> boolean.
// From `public Set<Territory> getNeighbors(Set<Territory>, int, Predicate<Territory>)`:
//     final Set<Territory> neighbors =
//         getNeighbors(
//             frontier, new HashSet<>(frontier), distance,
//             (it, it2) -> territoryCondition.test(it2));
// Captures the (non-null) `territoryCondition` Predicate<Territory> and adapts
// it to the BiPredicate<Territory, Territory> shape demanded by the private
// BFS overload. Unlike lambda$getNeighbors$1/$2/$4, this site does NOT
// short-circuit on null — the public overload that produces this lambda has
// already established that the predicate is non-null — so we cannot reuse
// the null-OR trampoline. Per the closure-capture convention
// (llm-instructions.md), the Predicate is carried as proc + rawptr ctx
// inside `Game_Map_Neighbors_Predicate_Trampoline_Ctx`, and the
// non-capturing trampoline below unwraps it and invokes the inner Predicate
// on the second argument (`it2`), exactly mirroring the Java body.
Game_Map_Neighbors_Predicate_Trampoline_Ctx :: struct {
	cond:     proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
}

game_map_lambda_get_neighbors_5 :: proc(
	ctx: rawptr,
	_: ^Territory,
	it2: ^Territory,
) -> bool {
	inner := cast(^Game_Map_Neighbors_Predicate_Trampoline_Ctx)ctx
	return inner.cond(inner.cond_ctx, it2)
}

// Java synthetic: GameMap#lambda$getNeighbors$6(BiPredicate, Territory) -> Set<Territory>.
// From private GameMap.getNeighbors(Set<Territory>, Set<Territory>, int, BiPredicate):
//     final Set<Territory> newFrontier =
//         frontier.stream()
//             .map(t -> getNeighbors(t, routeCondition))   // <- this lambda
//             .flatMap(Collection::stream)
//             .filter(t -> !searched.contains(t))
//             .collect(Collectors.toSet());
// The lambda captures the BiPredicate `routeCondition` (carried under the
// rawptr-ctx convention) and the enclosing GameMap, and dispatches to the
// private getNeighbors(Territory, BiPredicate) overload — already ported as
// `game_map_get_neighbors_bipredicate`. The BFS in
// `game_map_get_neighbors_set_set_distance_bipredicate` already inlines this
// step; this proc is the explicit single-territory expansion the synthetic
// represents, kept available for direct callers / parity with javac output.
game_map_lambda_get_neighbors_6 :: proc(
	self: ^Game_Map,
	cond: proc(rawptr, ^Territory, ^Territory) -> bool,
	cond_ctx: rawptr,
	t: ^Territory,
) -> map[^Territory]struct{} {
	return game_map_get_neighbors_bipredicate(self, t, cond, cond_ctx)
}

// Java synthetic: GameMap#lambda$getNeighbors$7(Set<Territory>, Territory) -> boolean.
// From private GameMap.getNeighbors(Set<Territory>, Set<Territory>, int, BiPredicate):
//     final Set<Territory> newFrontier =
//         frontier.stream()
//             .map(t -> getNeighbors(t, routeCondition))
//             .flatMap(Collection::stream)
//             .filter(t -> !searched.contains(t))   // <- this lambda
//             .collect(Collectors.toSet());
// The lambda captures the local `searched` Set<Territory> and tests whether
// the candidate territory has NOT yet been visited. Java's Set<T> is the
// Odin convention `map[^T]struct{}`.
game_map_lambda_get_neighbors_7 :: proc(
	searched: map[^Territory]struct{},
	t: ^Territory,
) -> bool {
	_, ok := searched[t]
	return !ok
}

// Java synthetic: GameMap#lambda$getNeighborsIgnoreEnd$8(Territory) -> boolean.
// From private GameMap.getNeighborsIgnoreEnd(Set, Set, int, Predicate):
//     final Predicate<Territory> neighborCond =
//         (distance == 1) ? territory -> true : territoryCondition;   // <- this lambda
// Non-capturing always-true Predicate<Territory> selected when the BFS is
// on its final hop. Mirrors `game_map_lambda_get_neighbors_3` /
// `game_map_lambda_get_distance_14`; written in the rawptr-ctx form to
// match the `proc(rawptr, ^Territory) -> bool` Predicate convention.
game_map_lambda_get_neighbors_ignore_end_8 :: proc(_ctx: rawptr, _t: ^Territory) -> bool {
	return true
}

// Java synthetic: GameMap#lambda$getNeighborsIgnoreEnd$9(Predicate, Territory) -> Set<Territory>.
// From private GameMap.getNeighborsIgnoreEnd(Set, Set, int, Predicate):
//     final Set<Territory> newFrontier =
//         frontier.stream()
//             .map(t -> getNeighbors(t, neighborCond))   // <- this lambda
//             .flatMap(Collection::stream)
//             .filter(t -> !searched.contains(t))
//             .collect(Collectors.toSet());
// Captures the enclosing GameMap (`this`) and the local `neighborCond`
// (Predicate<Territory>, carried under the rawptr-ctx convention), and
// dispatches to the public `getNeighbors(Territory, Predicate)` overload —
// already ported as `game_map_get_neighbors_predicate`. Parallels
// `game_map_lambda_get_neighbors_6`, which is the BiPredicate-flavored
// twin used by the plain `getNeighbors` BFS helper.
game_map_lambda_get_neighbors_ignore_end_9 :: proc(
	self: ^Game_Map,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
	t: ^Territory,
) -> map[^Territory]struct{} {
	return game_map_get_neighbors_predicate(self, t, cond, cond_ctx)
}

// Java synthetic: GameMap#lambda$getNeighborsIgnoreEnd$10(Set, Territory) -> boolean.
// From private GameMap.getNeighborsIgnoreEnd(Set, Set, int, Predicate):
//     final Set<Territory> newFrontier =
//         frontier.stream()
//             .map(t -> getNeighbors(t, neighborCond))
//             .flatMap(Collection::stream)
//             .filter(t -> !searched.contains(t))   // <- this lambda
//             .collect(Collectors.toSet());
// Captures the local `searched` Set<Territory> and reports whether `t` has
// NOT yet been visited. Identical body to `game_map_lambda_get_neighbors_7`.
game_map_lambda_get_neighbors_ignore_end_10 :: proc(
	searched: map[^Territory]struct{},
	t: ^Territory,
) -> bool {
	_, ok := searched[t]
	return !ok
}

// Mirrors private GameMap.setConnection(Territory from, Territory to):
//     final Set<Territory> current = getNeighbors(from);
//     final Set<Territory> modified = new HashSet<>(current);
//     modified.add(to);
//     connections.put(from, Collections.unmodifiableSet(modified));
// One-directional connection registration: records `to` as a neighbor of
// `from` in the connections map. Java preserves immutability of existing
// neighbor sets by copying before mutating; in Odin we likewise allocate a
// fresh `map[^Territory]struct{}` so we never mutate the set returned by
// `game_map_get_neighbors` (which the public API exposes to callers).
game_map_set_connection :: proc(self: ^Game_Map, from: ^Territory, to: ^Territory) {
	current := game_map_get_neighbors(self, from)
	modified := make(map[^Territory]struct{})
	for t in current {
		modified[t] = {}
	}
	modified[to] = {}
	self.connections[from] = modified
}

// Mirrors public GameMap.getNeighbors(Set<Territory>, int, Predicate<Territory>):
//     final Set<Territory> neighbors =
//         getNeighbors(
//             frontier, new HashSet<>(frontier), distance,
//             (it, it2) -> territoryCondition.test(it2));
//     neighbors.removeAll(frontier);
//     return neighbors;
// The Java lambda captures `territoryCondition`, so we route through the
// private BiPredicate overload via the heap-allocated trampoline pattern
// (see llm-instructions.md). Reuses Game_Map_Neighbors_Distance_Predicate_Ctx
// since the captured-state shape is identical (a single Predicate<Territory>).
game_map_get_neighbors_set_distance_predicate :: proc(
	self: ^Game_Map,
	frontier: map[^Territory]struct{},
	distance: i32,
	cond: proc(rawptr, ^Territory) -> bool,
	cond_ctx: rawptr,
) -> map[^Territory]struct{} {
	inner := new(Game_Map_Neighbors_Distance_Predicate_Ctx)
	inner.cond = cond
	inner.cond_ctx = cond_ctx
	searched := make(map[^Territory]struct{})
	for t in frontier {
		searched[t] = {}
	}
	neighbors := game_map_get_neighbors_set_set_distance_bipredicate(
		self,
		frontier,
		searched,
		distance,
		game_map_neighbors_distance_predicate_trampoline,
		inner,
	)
	for t in frontier {
		delete_key(&neighbors, t)
	}
	return neighbors
}


// Java synthetic lambda from `GameMap.getRouteOrElseThrow`:
//   () -> new IllegalStateException("Route expected to be returned")
// Supplied to `Optional.orElseThrow` when no Route can be found between
// the start and end Territories. The Odin port has no dedicated
// IllegalStateException type, so the lambda allocates a `Throwable`
// shim (`java.lang.Throwable`) carrying the same message — matching the
// convention used by `default_attachment_lambda_get_attachment_0`. The
// returned `^Throwable` is heap-allocated and owned by the caller; no
// variables are captured.
game_map_lambda_get_route_or_else_throw_12 :: proc() -> ^Throwable {
	t := new(Throwable)
	t.message = "Route expected to be returned"
	return t
}


// Java synthetic lambda from `GameMap.getRouteForUnitOrElseThrow`:
//   () -> new IllegalStateException("Route expected to be returned")
// Supplied to `Optional.orElseThrow` when `getRouteForUnits` (called with
// a single-unit `List.of(unit)`) yields no route between the start and
// end Territories. The Odin port has no dedicated IllegalStateException
// type, so the lambda allocates a `Throwable` shim
// (`java.lang.Throwable`) carrying the same message — matching the
// convention used by `default_attachment_lambda_get_attachment_0` and
// the sibling `game_map_lambda_get_route_or_else_throw_12`. The returned
// `^Throwable` is heap-allocated and owned by the caller; no variables
// are captured.
game_map_lambda_get_route_for_unit_or_else_throw_13 :: proc() -> ^Throwable {
	t := new(Throwable)
	t.message = "Route expected to be returned"
	return t
}

// Java synthetic lambda from `GameMap.getTerritoryOrThrow(String s)`:
//   () -> new IllegalArgumentException(
//             String.format("Territory with name %s could not be found", s))
// Supplied to `Optional.orElseThrow` when the territory-name lookup
// returns null. Java's lambda is a zero-arg `Supplier` that captures the
// outer parameter `s`; in Odin we lift the captured string into a
// formal parameter (`name`), matching the `lambda$0` index. The Odin
// port has no dedicated IllegalArgumentException type, so the lambda
// allocates a `Throwable` shim (`java.lang.Throwable`) carrying the
// formatted message — matching the convention used by
// `default_attachment_lambda_get_attachment_0` and the sibling
// `game_map_lambda_get_route_or_else_throw_12`. The returned
// `^Throwable` is heap-allocated and owned by the caller; the formatted
// `message` string is also heap-allocated (via `fmt.aprintf`) and owned
// alongside the Throwable.
game_map_lambda_get_territory_or_throw_0 :: proc(name: string) -> ^Throwable {
	t := new(Throwable)
	t.message = fmt.aprintf("Territory with name %s could not be found", name)
	return t
}

// Mirrors Java GameMap(GameData data) — package-private constructor that
// chains to GameDataComponent(data). The Java field declarations
// initialize `territories`, `connections`, and `territoryLookup` to empty
// collections; `gridDimensions` is `null` (left as a zero-length slice
// here to match `[]i32`'s zero value).
game_map_new :: proc(data: ^Game_Data) -> ^Game_Map {
	self := new(Game_Map)
	self.game_data_component = make_Game_Data_Component(data)
	self.territories = make([dynamic]^Territory)
	self.connections = make(map[^Territory]map[^Territory]struct{})
	self.territory_lookup = make(map[string]^Territory)
	return self
}

// Mirrors GameMap.getTerritoriesOwnedBy(GamePlayer):
//     return territories.stream()
//         .filter(Matches.isTerritoryOwnedBy(player))
//         .collect(Collectors.toList());
game_map_get_territories_owned_by :: proc(
	self: ^Game_Map,
	player: ^Game_Player,
) -> [dynamic]^Territory {
	pred, pred_ctx := matches_is_territory_owned_by(player)
	result := make([dynamic]^Territory)
	for t in self.territories {
		if pred(pred_ctx, t) {
			append(&result, t)
		}
	}
	return result
}

// Mirrors GameMap.isValidRoute(Route): indicates whether each territory in
// the route is connected to the preceding territory. Iterates the route's
// territories (Route's iterator returns getAllTerritories()) and verifies
// each consecutive pair is in the connections map.
game_map_is_valid_route :: proc(self: ^Game_Map, route: ^Route) -> bool {
	all := route_get_all_territories(route)
	defer delete(all)
	previous: ^Territory = nil
	for t in all {
		if previous != nil {
			neighbors := game_map_get_neighbors(self, previous)
			if _, ok := neighbors[t]; !ok {
				return false
			}
		}
		previous = t
	}
	return true
}
