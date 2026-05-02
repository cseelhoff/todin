package game

Move_Description :: struct {
	using abstract_move_description: Abstract_Move_Description,
	route: ^Route,
	units_to_sea_transports: map[^Unit]^Unit,
	air_transports_dependents: map[^Unit]map[^Unit]struct{},
}

// Synthetic constructor lambda: `e -> Set.copyOf(e.getValue())`
// from `MoveDescription(Collection<Unit>, Route, Map<Unit, Unit>, Map<Unit, Collection<Unit>>)`,
// applied as the value-mapper of `Collectors.toMap` over
// `airTransportsDependents.entrySet()`. Input is a `Map.Entry<Unit, Collection<Unit>>`;
// output is the entry's collection materialized as an immutable `Set<Unit>`.
move_description_lambda_new_0 :: proc(key: ^Unit, value: [dynamic]^Unit) -> map[^Unit]struct{} {
	result := make(map[^Unit]struct{})
	for u in value {
		result[u] = {}
	}
	return result
}

move_description_new :: proc(
	units: []^Unit,
	route: ^Route,
	units_to_sea_transports: map[^Unit]^Unit,
	air_transports_dependents: map[^Unit][dynamic]^Unit,
) -> ^Move_Description {
	assert(route != nil)
	assert(route_has_steps(route))
	self := new(Move_Description)
	self.abstract_move_description = make_Abstract_Move_Description(units)
	self.route = route
	self.units_to_sea_transports = make(map[^Unit]^Unit)
	for k, v in units_to_sea_transports {
		self.units_to_sea_transports[k] = v
	}
	self.air_transports_dependents = make(map[^Unit]map[^Unit]struct{})
	for k, v in air_transports_dependents {
		self.air_transports_dependents[k] = move_description_lambda_new_0(k, v)
	}
	return self
}

// Mirrors the public 3-arg Java constructor
// MoveDescription(Collection<Unit>, Route, Map<Unit, Unit>): chains to
// the 4-arg constructor with `Map.of()` (an empty
// airTransportsDependents map). The bare `move_description_new` name is
// taken by the all-args constructor, so this 3-arg overload uses a
// `_with_sea_transports` suffix to disambiguate.
move_description_new_with_sea_transports :: proc(
	units: []^Unit,
	route: ^Route,
	units_to_sea_transports: map[^Unit]^Unit,
) -> ^Move_Description {
	empty_air_transports_dependents: map[^Unit][dynamic]^Unit
	return move_description_new(
		units,
		route,
		units_to_sea_transports,
		empty_air_transports_dependents,
	)
}

// Mirrors the public 2-arg Java constructor
// MoveDescription(Collection<Unit>, Route): chains to the 4-arg
// constructor with `Map.of()` for both unitsToSeaTransports and
// airTransportsDependents. The bare `move_description_new` name is
// taken by the all-args constructor, so this 2-arg overload uses a
// `_units_route` suffix to disambiguate.
move_description_new_units_route :: proc(
	units: []^Unit,
	route: ^Route,
) -> ^Move_Description {
	empty_units_to_sea_transports: map[^Unit]^Unit
	empty_air_transports_dependents: map[^Unit][dynamic]^Unit
	return move_description_new(
		units,
		route,
		empty_units_to_sea_transports,
		empty_air_transports_dependents,
	)
}

move_description_get_units_to_sea_transports :: proc(self: ^Move_Description) -> map[^Unit]^Unit {
	return self.units_to_sea_transports
}

move_description_get_air_transports_dependents :: proc(self: ^Move_Description) -> map[^Unit]map[^Unit]struct{} {
	return self.air_transports_dependents
}

move_description_get_route :: proc(self: ^Move_Description) -> ^Route {
	return self.route
}

move_description_collections_are_equal :: proc(a: [dynamic]^Unit, b: [dynamic]^Unit) -> bool {
	if len(a) != len(b) {
		return false
	}
	counts := make(map[^Unit]int)
	defer delete(counts)
	for u in a {
		counts[u] = counts[u] + 1
	}
	for u in b {
		c, ok := counts[u]
		if !ok || c == 0 {
			return false
		}
		counts[u] = c - 1
	}
	for _, c in counts {
		if c != 0 {
			return false
		}
	}
	return true
}

