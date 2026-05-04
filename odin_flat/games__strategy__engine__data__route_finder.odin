package game

import "core:slice"

Route_Finder :: struct {
	move_validator: ^Move_Validator,
	game_map:       ^Game_Map,
	condition:      proc(rawptr, ^Territory) -> bool,
	condition_ctx:  rawptr,
	units:          [dynamic]^Unit,
	player:         ^Game_Player,
}

// Mirrors private RouteFinder#findRouteByCost(Territory, Territory,
// Function<Territory, BigDecimal>): a BFS-style relaxation that finds the
// minimum-cost route from `start` to `end` using `cost` to score each
// territory entry. Returns nil when no path exists (Java's Optional.empty).
// BigDecimal collapses to f64 per the port rules. The unique suffix
// `_with_cost_fn` distinguishes this overload from the (Territory,
// Territory) variant being ported in parallel by a sibling subagent.
route_finder_find_route_by_cost_with_cost_fn :: proc(
	self: ^Route_Finder,
	start: ^Territory,
	end: ^Territory,
	cost: proc(t: ^Territory) -> f64,
) -> ^Route {
	assert(start != nil)
	assert(end != nil)

	if start == end {
		r := new(Route)
		r.start = start
		return r
	}

	previous := make(map[^Territory]^Territory)
	defer delete(previous)
	previous[start] = nil

	to_visit: [dynamic]^Territory
	defer delete(to_visit)
	append(&to_visit, start)

	route_costs := make(map[^Territory]f64)
	defer delete(route_costs)
	route_costs[start] = 0

	// Java uses `new BigDecimal(Integer.MAX_VALUE)` as the sentinel "no
	// route found yet" cost; mirror with f64 of i32 max.
	min_cost := f64(max(i32))

	for len(to_visit) > 0 {
		current := to_visit[0]
		ordered_remove(&to_visit, 0)
		if route_costs[current] >= min_cost {
			continue
		}
		neighbors := route_finder_get_neighbors_validating_canals(
			self,
			current,
			self.condition,
			self.condition_ctx,
			self.units,
			self.player,
		)
		defer delete(neighbors)
		for neighbor in neighbors {
			route_cost := route_costs[current] + cost(neighbor)
			_, has_prev := previous[neighbor]
			if !has_prev || route_cost < route_costs[neighbor] {
				previous[neighbor] = current
				route_costs[neighbor] = route_cost
				if neighbor == end && route_cost < min_cost {
					min_cost = route_cost
					break
				}
				append(&to_visit, neighbor)
			}
		}
	}

	if min_cost == f64(max(i32)) {
		return nil
	}
	return route_finder_get_route(start, end, previous)
}

@(private="file")
route_finder_find_route_by_cost_pair_cost_adapter :: proc(ctx: rawptr, t: ^Territory) -> f64 {
	self := cast(^Route_Finder)ctx
	return route_finder_get_max_movement_cost(self, t)
}

route_finder_find_route_by_cost_pair :: proc(self: ^Route_Finder, start: ^Territory, end: ^Territory) -> ^Route {
	assert(start != nil)
	assert(end != nil)
	return route_finder_find_route_by_cost_with_cost_fn(
		self,
		start,
		end,
		route_finder_find_route_by_cost_pair_cost_adapter,
		rawptr(self),
	)
}

// Mirrors the private static Java RouteFinder#getRoute(start, destination,
// previous): walks the `previous` predecessor map back from `destination`
// to `start`, then reverses to produce a forward-ordered Route. The first
// element of the reversed list (== start) becomes Route.start; the rest
// become Route.steps. Java asserts non-null on each predecessor link.
route_finder_get_route :: proc(
	self: ^Route_Finder,
	start: ^Territory,
	end: ^Territory,
	prev: map[^Territory]^Territory,
) -> ^Route {
	territories: [dynamic]^Territory
	current := end
	for current != start {
		assert(current != nil, "Route was calculated but isn't connected")
		append(&territories, current)
		current = prev[current]
	}
	append(&territories, start)
	slice.reverse(territories[:])

	route := new(Route)
	route.start = territories[0]
	route.steps = make([dynamic]^Territory, 0, len(territories) - 1)
	for i in 1 ..< len(territories) {
		append(&route.steps, territories[i])
	}
	delete(territories)
	return route
}

// Mirrors the Java lambda `t -> BigDecimal.ONE` inside
// RouteFinder#findRouteByDistance, used as the per-territory cost function
// passed to findRouteByCost. BigDecimal collapses to f64 per the port
// rules, so BigDecimal.ONE becomes 1.0.
route_finder_lambda_find_route_by_distance_0 :: proc(territory: ^Territory) -> f64 {
	return 1.0
}

// Captures for the AND-combined predicate built inside
// route_finder_get_neighbors_validating_canals when a non-null GamePlayer
// is supplied. Mirrors what Java's `neighborFilter.and(t -> moveValidator
// .canAnyUnitsPassCanal(territory, t, units, player))` closes over: the
// outer (per-call) territory, the original neighbor filter (with its
// rawptr ctx), the unit collection, the player, and the MoveValidator
// reachable through the RouteFinder. Per llm-instructions.md the Java
// Predicate becomes a (rawptr, ^Territory) -> bool plus its userdata.
@(private="file")
Route_Finder_Get_Neighbors_Validating_Canals_And_Ctx :: struct {
	self:                ^Route_Finder,
	territory:           ^Territory,
	neighbor_filter:     proc(rawptr, ^Territory) -> bool,
	neighbor_filter_ctx: rawptr,
	units:               [dynamic]^Unit,
	player:              ^Game_Player,
}

// Implements the `Predicate.and` combination of the caller-supplied
// neighborFilter with the canal-check lambda from the Java
// getNeighborsValidatingCanals body. Java short-circuits via `&&` inside
// Predicate.and, so we evaluate neighborFilter first and only consult the
// MoveValidator on a non-null GamePlayer when that succeeds. The canal
// proc `move_validator_can_any_units_pass_canal` is a forward reference
// (layer 6) — Odin resolves procs at the package level, so emitting the
// call here is fine even though it isn't yet implemented.
@(private="file")
route_finder_get_neighbors_validating_canals_and_proc :: proc(
	ctx: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Route_Finder_Get_Neighbors_Validating_Canals_And_Ctx)ctx
	if c.neighbor_filter != nil && !c.neighbor_filter(c.neighbor_filter_ctx, t) {
		return false
	}
	return move_validator_can_any_units_pass_canal(
		c.self.move_validator,
		c.territory,
		t,
		c.units,
		c.player,
	)
}

// Mirrors private RouteFinder#getNeighborsValidatingCanals(Territory,
// Predicate<Territory>, Collection<Unit>, GamePlayer):
//     return map.getNeighbors(
//         territory,
//         player == null
//             ? neighborFilter
//             : neighborFilter.and(
//                 t -> moveValidator.canAnyUnitsPassCanal(
//                     territory, t, units, player)));
// Returns the set of neighbor Territories of `territory` that pass the
// effective predicate. The Java `Predicate<Territory>` is rendered with
// the rawptr-ctx convention (proc + ctx) per llm-instructions.md so
// capturing predicates from Java callers survive the port. When `player`
// is nil we forward the caller's predicate verbatim to
// game_map_get_neighbors_predicate; otherwise we build an AND-combined
// predicate over file-private state. The canal lambda's MoveValidator
// call is a layer-6 forward reference — package-level proc resolution in
// Odin makes this safe, mirroring the in-package layering of the Java
// source.
route_finder_get_neighbors_validating_canals :: proc(
	self: ^Route_Finder,
	territory: ^Territory,
	neighbor_filter: proc(rawptr, ^Territory) -> bool,
	neighbor_filter_ctx: rawptr,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> map[^Territory]struct{} {
	if player == nil {
		return game_map_get_neighbors_predicate(
			self.game_map,
			territory,
			neighbor_filter,
			neighbor_filter_ctx,
		)
	}
	and_ctx := new(Route_Finder_Get_Neighbors_Validating_Canals_And_Ctx)
	defer free(and_ctx)
	and_ctx.self = self
	and_ctx.territory = territory
	and_ctx.neighbor_filter = neighbor_filter
	and_ctx.neighbor_filter_ctx = neighbor_filter_ctx
	and_ctx.units = units
	and_ctx.player = player
	return game_map_get_neighbors_predicate(
		self.game_map,
		territory,
		route_finder_get_neighbors_validating_canals_and_proc,
		rawptr(and_ctx),
	)
}

// Mirrors the private all-args RouteFinder constructor synthesized by
// Lombok's @RequiredArgsConstructor(access = PRIVATE): assigns each final
// field directly. Java's `Predicate<Territory> condition` is translated
// per llm-instructions.md's closure-capture rule into a paired
// `proc(rawptr, ^Territory) -> bool` plus its `rawptr` userdata so
// capturing predicates from Java callers survive the port. The Collection
// is `Collection<Unit>` per the Java declaration; we accept the already-
// materialized [dynamic]^Unit. `player` is @Nullable in Java, so a nil
// pointer is allowed here.
route_finder_new :: proc(
	move_validator: ^Move_Validator,
	game_map: ^Game_Map,
	predicate: proc(rawptr, ^Territory) -> bool,
	predicate_ctx: rawptr,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> ^Route_Finder {
	self := new(Route_Finder)
	self.move_validator = move_validator
	self.game_map = game_map
	self.condition = predicate
	self.condition_ctx = predicate_ctx
	self.units = units
	self.player = player
	return self
}

// Mirrors the public 4-arg Java constructor
// RouteFinder(GameMap, Predicate<Territory>, Collection<Unit>, GamePlayer):
// builds a fresh MoveValidator over the map's GameData (with
// isNonCombat=false, since the Java comment notes MoveValidator is only
// used for canal checks here, where isNonCombat is unused) and chains to
// the Lombok-generated all-args constructor. The Predicate is paired
// with a `rawptr` userdata per llm-instructions.md's closure-capture
// rule — Java callers may pass capturing lambdas. `player` is @Nullable
// in Java, so a nil pointer is allowed.
route_finder_new_with_units_player :: proc(
	game_map: ^Game_Map,
	condition: proc(rawptr, ^Territory) -> bool,
	condition_ctx: rawptr,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> ^Route_Finder {
	move_validator := move_validator_new(
		game_data_component_get_data(&game_map.game_data_component),
		false,
	)
	return route_finder_new(move_validator, game_map, condition, condition_ctx, units, player)
}

// Mirrors the public 2-arg Java constructor
// RouteFinder(GameMap, Predicate<Territory>): chains to the 4-arg
// constructor with `Set.of()` (an empty unit collection) and a null
// GamePlayer. The Predicate is paired with a `rawptr` userdata per
// llm-instructions.md's closure-capture rule. An empty `[dynamic]^Unit`
// is the zero value (nil dynamic array, which has len 0). The bare
// `route_finder_new` name is taken by the Lombok-synthesized all-args
// private constructor, so this 2-arg overload uses a `_map_condition`
// suffix to disambiguate.
route_finder_new_map_condition :: proc(
	game_map: ^Game_Map,
	condition: proc(rawptr, ^Territory) -> bool,
	condition_ctx: rawptr,
) -> ^Route_Finder {
	empty_units: [dynamic]^Unit
	return route_finder_new_with_units_player(
		game_map,
		condition,
		condition_ctx,
		empty_units,
		nil,
	)
}

// Mirrors RouteFinder#findRouteByDistance(Territory, Territory):
//     return findRouteByCost(start, end, t -> BigDecimal.ONE);
// Java's @Nonnull annotations become assert(... != nil) — these are
// validated by Preconditions.checkNotNull deeper in findRouteByCost.
// The cost lambda `t -> BigDecimal.ONE` is captured by the file-scoped
// `route_finder_lambda_find_route_by_distance_0` proc (BigDecimal -> f64
// per the port rules, so 1.0). Java's Optional<Route> collapses to a
// nullable ^Route — nil signals "no route found".
route_finder_find_route_by_distance :: proc(
	self: ^Route_Finder,
	start: ^Territory,
	end: ^Territory,
) -> ^Route {
	return route_finder_find_route_by_cost_with_cost_fn(
		self,
		start,
		end,
		route_finder_lambda_find_route_by_distance_0,
	)
}

// Mirrors @VisibleForTesting RouteFinder#getMaxMovementCost(Territory):
//     return TerritoryEffectHelper.getMaxMovementCost(t, units);
// BigDecimal -> f64 per the port rules. Forwards to the static helper
// with this RouteFinder's captured unit collection. Already referenced
// as a forward call by the cost-pair adapter earlier in this file;
// emitting the body now closes that reference.
route_finder_get_max_movement_cost :: proc(self: ^Route_Finder, t: ^Territory) -> f64 {
	return territory_effect_helper_get_max_movement_cost(t, self.units)
}
