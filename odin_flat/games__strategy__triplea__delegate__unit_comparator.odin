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
