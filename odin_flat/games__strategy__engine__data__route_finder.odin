package game

import "core:slice"

Route_Finder :: struct {
	move_validator: ^Move_Validator,
	game_map:       ^Game_Map,
	condition:      proc(t: ^Territory) -> bool,
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
