package game

// games.strategy.triplea.delegate.UnitComparator
// Java is a Lombok @UtilityClass — no instance state. Each Java
// `Comparator<Unit>` factory becomes an Odin proc returning either a
// plain `proc(^Unit, ^Unit) -> i32` (non-capturing) or a
// `(proc(rawptr, ^Unit, ^Unit) -> i32, rawptr)` pair (capturing) per
// the closure-capture convention in llm-instructions.md. BigDecimal
// movement-left values map to f64.
Unit_Comparator :: struct {}

// ---------------------------------------------------------------------------
// getDecreasingBombardComparator
// ---------------------------------------------------------------------------
// Java:
//   return Comparator.comparing(
//       Unit::getUnitAttachment,
//       Comparator.comparingInt(UnitAttachment::getBombard).reversed());
// Non-capturing: orders units by bombard value, descending.
unit_comparator_decreasing_bombard_compare :: proc(u1: ^Unit, u2: ^Unit) -> i32 {
	b1 := unit_attachment_get_bombard(unit_get_unit_attachment(u1))
	b2 := unit_attachment_get_bombard(unit_get_unit_attachment(u2))
	if b1 > b2 {
		return -1
	}
	if b1 < b2 {
		return 1
	}
	return 0
}

unit_comparator_get_decreasing_bombard_comparator :: proc() -> proc(^Unit, ^Unit) -> i32 {
	return unit_comparator_decreasing_bombard_compare
}

// ---------------------------------------------------------------------------
// getLowestToHighestMovementComparator and its synthetic lambda$0
// ---------------------------------------------------------------------------
// Java:
//   public static Comparator<Unit> getLowestToHighestMovementComparator() {
//     final Map<Unit, BigDecimal> cache = new HashMap<>();
//     return Comparator.comparing(u -> cache.computeIfAbsent(u, Unit::getMovementLeft));
//   }
// The lambda captures `cache`, so we use the rawptr-ctx convention:
// the comparator carries a heap-allocated ctx with the per-instance
// cache. lambda$0 itself is the synthetic
//   (Map<Unit,BigDecimal> cache, Unit u) -> BigDecimal
// helper; it does the cache.computeIfAbsent step and is split out so
// other comparator factories that build a per-instance cache (e.g.
// getMovableUnitsComparator) can reuse the same logic.
Unit_Comparator_Lowest_To_Highest_Movement_Ctx :: struct {
	cache: map[^Unit]f64,
}

unit_comparator_lambda_get_lowest_to_highest_movement_comparator_0 :: proc(
	cache: ^map[^Unit]f64,
	u: ^Unit,
) -> f64 {
	if existing, ok := cache[u]; ok {
		return existing
	}
	val := unit_get_movement_left(u)
	cache[u] = val
	return val
}

unit_comparator_lowest_to_highest_movement_compare :: proc(
	ctx: rawptr,
	u1: ^Unit,
	u2: ^Unit,
) -> i32 {
	c := cast(^Unit_Comparator_Lowest_To_Highest_Movement_Ctx)ctx
	v1 := unit_comparator_lambda_get_lowest_to_highest_movement_comparator_0(&c.cache, u1)
	v2 := unit_comparator_lambda_get_lowest_to_highest_movement_comparator_0(&c.cache, u2)
	if v1 < v2 {
		return -1
	}
	if v1 > v2 {
		return 1
	}
	return 0
}

unit_comparator_get_lowest_to_highest_movement_comparator :: proc(
) -> (
	proc(rawptr, ^Unit, ^Unit) -> i32,
	rawptr,
) {
	ctx := new(Unit_Comparator_Lowest_To_Highest_Movement_Ctx)
	ctx.cache = make(map[^Unit]f64)
	return unit_comparator_lowest_to_highest_movement_compare, rawptr(ctx)
}

// Less-than adapter over the 3-way comparator above. Java callers use
// Comparator<Unit>; Odin sort/AA-fire helpers want a `proc(rawptr, ^Unit, ^Unit) -> bool`.
unit_comparator_lowest_to_highest_movement_less_than :: proc(ctx: rawptr, a, b: ^Unit) -> bool {
	return unit_comparator_lowest_to_highest_movement_compare(ctx, a, b) < 0
}

unit_comparator_get_lowest_to_highest_movement_less_than :: proc(
) -> (
	proc(rawptr, ^Unit, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Unit_Comparator_Lowest_To_Highest_Movement_Ctx)
	ctx.cache = make(map[^Unit]f64)
	return unit_comparator_lowest_to_highest_movement_less_than, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// lambda$getIncreasingCapacityComparator$2
// ---------------------------------------------------------------------------
// Java factory body:
//   final Map<Unit, Integer> cache = new HashMap<>();
//   return Comparator.comparingInt(
//       u -> cache.computeIfAbsent(u, k -> TransportUtils.getTransportCost(u.getTransporting())));
// lambda$2 is the synthetic
//   (Map<Unit,Integer> cache, Unit u) -> int
// extracted helper that performs the cache.computeIfAbsent and
// invokes TransportUtils.getTransportCost on the unit's currently
// transported units.
//
// lambda$1 is the synthetic inner mappingFunction passed to
// computeIfAbsent: `k -> TransportUtils.getTransportCost(u.getTransporting())`.
// Its declared parameter is the map key `k` (a Unit), but the body
// uses the captured outer `u`, so the synthetic signature is
//   (Unit u, Unit k) -> int
// and `k` is unused.
unit_comparator_lambda_get_increasing_capacity_comparator_1 :: proc(
	u: ^Unit,
	k: ^Unit,
) -> i32 {
	_ = k
	return transport_utils_get_transport_cost(unit_get_transporting(u))
}

unit_comparator_lambda_get_increasing_capacity_comparator_2 :: proc(
	cache: ^map[^Unit]i32,
	u: ^Unit,
) -> i32 {
	if existing, ok := cache[u]; ok {
		return existing
	}
	transporting := unit_get_transporting(u)
	val := transport_utils_get_transport_cost(transporting)
	cache[u] = val
	return val
}

// ---------------------------------------------------------------------------
// lambda$getUnloadableTransportsComparator$3
// ---------------------------------------------------------------------------
// Java factory tail:
//   .thenComparingInt(t -> noTies ? t.hashCode() : 0);
// lambda$3 is the synthetic
//   (boolean noTies, Unit t) -> int
// helper: when noTies is true it falls back to the unit's hashCode so
// the comparator becomes a total order; otherwise it returns 0 to
// keep ties (stable on the previous keys).
unit_comparator_lambda_get_unloadable_transports_comparator_3 :: proc(
	no_ties: bool,
	t: ^Unit,
) -> i32 {
	if no_ties {
		return unit_hash_code(t)
	}
	return 0
}

// ---------------------------------------------------------------------------
// lambda$getMovableUnitsComparator$4
// ---------------------------------------------------------------------------
// Java factory body returns:
//   (u1, u2) -> { /* big body */ }
// which captures cache, route, units, and decreasingCapacityComparator.
// The synthetic desugared signature is therefore
//   int lambda$4(Map<Unit,BigDecimal> cache,
//                Route route,
//                List<Unit> units,
//                Comparator<Unit> decreasingCapacityComparator,
//                Unit u1, Unit u2)
// In Odin we mirror that as the captured values + the rawptr-ctx pair
// for the inner Comparator<Unit>. `route` may be null in Java; we
// translate that to a possibly-nil ^Route.
unit_comparator_lambda_get_movable_units_comparator_4 :: proc(
	cache: ^map[^Unit]f64,
	route: ^Route,
	units: [dynamic]^Unit,
	decreasing_capacity_comparator: proc(rawptr, ^Unit, ^Unit) -> i32,
	decreasing_capacity_ctx: rawptr,
	u1: ^Unit,
	u2: ^Unit,
) -> i32 {
	// Ensure units have enough movement (cache.computeIfAbsent(u, Unit::getMovementLeft)).
	left1 := unit_comparator_lambda_get_lowest_to_highest_movement_comparator_0(cache, u1)
	left2 := unit_comparator_lambda_get_lowest_to_highest_movement_comparator_0(cache, u2)
	if route != nil {
		cost1 := route_get_movement_cost(route, u1)
		cost2 := route_get_movement_cost(route, u2)
		if left1 >= cost1 && left2 < cost2 {
			return -1
		}
		if left1 < cost1 && left2 >= cost2 {
			return 1
		}
	}

	// Prefer transports for which dependents are also selected.
	transporting1 := unit_get_transporting_no_args(u1)
	transporting2 := unit_get_transporting_no_args(u2)
	contains_all_1 := true
	for t in transporting1 {
		found := false
		for u in units {
			if u == t {
				found = true
				break
			}
		}
		if !found {
			contains_all_1 = false
			break
		}
	}
	contains_all_2 := true
	for t in transporting2 {
		found := false
		for u in units {
			if u == t {
				found = true
				break
			}
		}
		if !found {
			contains_all_2 = false
			break
		}
	}
	has_depends1: i32 = 0
	if contains_all_1 {
		has_depends1 = 1
	}
	has_depends2: i32 = 0
	if contains_all_2 {
		has_depends2 = 1
	}
	if has_depends1 != has_depends2 {
		return has_depends1 - has_depends2
	}

	// Sort by decreasing transport capacity (only valid for transports).
	compare_capacity := decreasing_capacity_comparator(decreasing_capacity_ctx, u1, u2)
	if compare_capacity != 0 {
		return compare_capacity
	}

	// Sort by increasing movement normally, but by decreasing movement during loading.
	if left1 != left2 {
		if route != nil && route_is_load(route) {
			if left2 < left1 {
				return -1
			}
			return 1
		}
		if left1 < left2 {
			return -1
		}
		return 1
	}

	// Sort units by type first.
	t1 := unit_get_type(u1)
	t2 := unit_get_type(u2)
	if !unit_type_equals(t1, t2) {
		// Land transportable units should have higher priority than
		// non-land transportable ones, when all else is equal.
		is_land_transportable1: i32 = 0
		if unit_attachment_is_land_transportable(unit_type_get_unit_attachment(t1)) {
			is_land_transportable1 = 1
		}
		is_land_transportable2: i32 = 0
		if unit_attachment_is_land_transportable(unit_type_get_unit_attachment(t2)) {
			is_land_transportable2 = 1
		}
		if is_land_transportable1 != is_land_transportable2 {
			return is_land_transportable2 - is_land_transportable1
		}
		h1 := unit_type_hash_code(t1)
		h2 := unit_type_hash_code(t2)
		if h1 < h2 {
			return -1
		}
		if h1 > h2 {
			return 1
		}
		return 0
	}

	hu1 := unit_hash_code(u1)
	hu2 := unit_hash_code(u2)
	if hu1 < hu2 {
		return -1
	}
	if hu1 > hu2 {
		return 1
	}
	return 0
}
