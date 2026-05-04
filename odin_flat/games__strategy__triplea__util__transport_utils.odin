package game

import "core:slice"

// Utilities for loading/unloading various types of transports.
// Java: games.strategy.triplea.util.TransportUtils (utility class — no instance state).
// Java owners covered by this file:
//   - games.strategy.triplea.util.TransportUtils
Transport_Utils :: struct {}

// Java: TransportUtils.getTransportCost(Collection<Unit> units) -> int
// Sums Unit#getUnitAttachment#getTransportCost over all units. Java treats a
// null collection as 0; in Odin an empty/zero [dynamic] yields 0 naturally.
transport_utils_get_transport_cost :: proc(units: [dynamic]^Unit) -> i32 {
	total: i32 = 0
	for u in units {
		if u == nil {
			continue
		}
		total += unit_attachment_get_transport_cost(unit_get_unit_attachment(u))
	}
	return total
}

// Java: TransportUtils.sortByTransportCostDescending(Collection<Unit>) -> List<Unit>
// Returns a new list sorted by Unit#getUnitAttachment#getTransportCost descending.
transport_utils_sort_by_transport_cost_descending :: proc(units: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, len(units))
	for u in units {
		append(&result, u)
	}
	slice.sort_by(result[:], proc(a, b: ^Unit) -> bool {
		ca := unit_attachment_get_transport_cost(unit_get_unit_attachment(a))
		cb := unit_attachment_get_transport_cost(unit_get_unit_attachment(b))
		return ca > cb
	})
	return result
}

// Java: TransportUtils.sortByTransportCapacityDescendingThenMovesDescending(Collection<Unit>) -> List<Unit>
// Sort key (in Java order):
//   1. TransportTracker.hasTransportUnloadedInPreviousPhase (false before true)
//   2. TransportTracker.getAvailableCapacity ascending
//   3. Unit.getMovementLeft descending (reversed)
transport_utils_sort_by_transport_capacity_descending_then_moves_descending :: proc(transports: [dynamic]^Unit) -> [dynamic]^Unit {
	result := make([dynamic]^Unit, 0, len(transports))
	for u in transports {
		append(&result, u)
	}
	slice.sort_by(result[:], proc(a, b: ^Unit) -> bool {
		a_unloaded := transport_tracker_has_transport_unloaded_in_previous_phase(a)
		b_unloaded := transport_tracker_has_transport_unloaded_in_previous_phase(b)
		if a_unloaded != b_unloaded {
			// false (not previously unloaded) sorts before true
			return !a_unloaded && b_unloaded
		}
		a_cap := transport_tracker_get_available_capacity(a)
		b_cap := transport_tracker_get_available_capacity(b)
		if a_cap != b_cap {
			return a_cap < b_cap
		}
		// Movement-left is f64 in the Odin port (Java BigDecimal).
		return unit_get_movement_left(a) > unit_get_movement_left(b)
	})
	return result
}

// Java: lambda$sortByTransportOptionsAscending$0(List a, List b)
// Used as the merge function in a Collectors.toMap call. Java throws on
// duplicate keys; the algorithm's invariant guarantees this is never
// triggered in practice. Return the first list to preserve the
// no-duplicate-keys contract without panicking.
lambda_transport_utils_sort_by_transport_options_ascending_0 :: proc(
	a: [dynamic]^Unit,
	b: [dynamic]^Unit,
) -> [dynamic]^Unit {
	_ = b
	return a
}

// Java: lambda$removeTransportAndLoadedUnits$1(Unit transport, List<Unit> t)
// Body: t.remove(transport)  -- removes the first occurrence of `transport` from list `t`.
lambda_transport_utils_remove_transport_and_loaded_units_1 :: proc(
	transport: ^Unit,
	t: ^[dynamic]^Unit,
) {
	if t == nil {
		return
	}
	for i := 0; i < len(t^); i += 1 {
		if t^[i] == transport {
			ordered_remove(t, i)
			return
		}
	}
}

// Java: lambda$chooseEquivalentUnitsToUnload$4(List<Unit> updatedUnits, int unitIndex, Unit u)
// Body: updatedUnits.set(unitIndex, u)  -- replaces the entry at unitIndex.
lambda_transport_utils_choose_equivalent_units_to_unload_4 :: proc(
	updated_units: ^[dynamic]^Unit,
	unit_index: int,
	u: ^Unit,
) {
	if updated_units == nil {
		return
	}
	if unit_index < 0 || unit_index >= len(updated_units^) {
		return
	}
	updated_units^[unit_index] = u
}

// Java: TransportUtils.canUnload(Unit unit, Territory territory) -> boolean (private static)
// Body: transport = unit.getTransportedBy(); return transport != null
//                && !Matches.transportCannotUnload(territory).test(transport);
transport_utils_can_unload :: proc(unit: ^Unit, territory: ^Territory) -> bool {
	transport := unit_get_transported_by(unit)
	if transport == nil {
		return false
	}
	pred, ctx := matches_transport_cannot_unload(territory)
	return !pred(ctx, transport)
}

// Java: lambda$chooseEquivalentUnitsToUnload$2(Unit origUnit, Unit u)
// Body: u.isEquivalent(origUnit). Captured: origUnit; param: u.
lambda_transport_utils_choose_equivalent_units_to_unload_2 :: proc(
	orig_unit: ^Unit,
	u: ^Unit,
) -> bool {
	return unit_is_equivalent(u, orig_unit)
}

// Java: lambda$chooseEquivalentUnitsToUnload$3(Route route, Unit u)
// Body: canUnload(u, route.getEnd()). Captured: route; param: u.
lambda_transport_utils_choose_equivalent_units_to_unload_3 :: proc(
	route: ^Route,
	u: ^Unit,
) -> bool {
	return transport_utils_can_unload(u, route_get_end(route))
}

// Java: TransportUtils.mapTransportsAlreadyLoaded(Collection<Unit> units, Collection<Unit> transports)
//   -> Map<Unit, Unit>
// Returns a map of unit -> transport for units already transported by something
// in the `transports` collection. Filters both sides via Matches.unitCanBeTransported
// and Matches.unitCanTransport before pairing.
transport_utils_map_transports_already_loaded :: proc(
	units: [dynamic]^Unit,
	transports: [dynamic]^Unit,
) -> map[^Unit]^Unit {
	cb_p, cb_c := matches_unit_can_be_transported()
	can_be_transported := make([dynamic]^Unit, 0, len(units))
	for u in units {
		if cb_p(cb_c, u) {
			append(&can_be_transported, u)
		}
	}

	ct_p, ct_c := matches_unit_can_transport()
	can_transport := make([dynamic]^Unit, 0, len(transports))
	for t in transports {
		if ct_p(ct_c, t) {
			append(&can_transport, t)
		}
	}

	mapping: map[^Unit]^Unit
	for current_transported in can_be_transported {
		transport := unit_get_transported_by(current_transported)
		if transport == nil {
			continue
		}
		// Java: !canTransport.contains(transport)
		found := false
		for t in can_transport {
			if t == transport {
				found = true
				break
			}
		}
		if !found {
			continue
		}
		mapping[current_transported] = transport
	}
	return mapping
}

// Java: TransportUtils.loadUnitIntoFirstAvailableTransport(Unit unit,
//     List<Unit> canTransport, Map<Unit,Unit> mapping, IntegerMap<Unit> addedLoad)
//   -> Optional<Unit>  (private static)
// Walks `canTransport` in order; for the first transport whose remaining
// capacity (TransportTracker.getAvailableCapacity - addedLoad) is at least
// the unit's transport cost, records the load and returns that transport.
// Returns nil if no transport had room (Java's Optional.empty()).
transport_utils_load_unit_into_first_available_transport :: proc(
	unit: ^Unit,
	can_transport: [dynamic]^Unit,
	mapping: ^map[^Unit]^Unit,
	added_load: ^Integer_Map,
) -> ^Unit {
	cost := unit_attachment_get_transport_cost(unit_get_unit_attachment(unit))
	for transport in can_transport {
		capacity :=
			transport_tracker_get_available_capacity(transport) -
			integer_map_get_int(added_load, rawptr(transport))
		if capacity >= cost {
			integer_map_add(added_load, rawptr(transport), cost)
			mapping^[unit] = transport
			return transport
		}
	}
	return nil
}

