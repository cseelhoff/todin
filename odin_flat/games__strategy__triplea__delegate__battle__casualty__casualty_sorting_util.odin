package game

import "core:slice"

Casualty_Sorting_Util :: struct {}

@(private="file")
casualty_sorting_util_marines_cmp :: proc(u1: ^Unit, u2: ^Unit) -> int {
	a1 := unit_get_was_amphibious(u1)
	a2 := unit_get_was_amphibious(u2)
	v1 := 1 if a1 else 0
	v2 := 1 if a2 else 0
	if v1 != v2 {
		return v1 - v2
	}
	ua1: ^Unit_Attachment = nil
	ua2: ^Unit_Attachment = nil
	if u1 != nil && u1.type != nil {
		ua1 = u1.type.unit_attachment
	}
	if u2 != nil && u2.type != nil {
		ua2 = u2.type.unit_attachment
	}
	m1: i32 = ua1.is_marine if ua1 != nil else 0
	m2: i32 = ua2.is_marine if ua2 != nil else 0
	if m1 < m2 {
		return -1
	}
	if m1 > m2 {
		return 1
	}
	return 0
}

casualty_sorting_util_compare_marines :: proc() -> proc(a: ^Unit, b: ^Unit) -> int {
	return casualty_sorting_util_marines_cmp
}

// games.strategy.triplea.delegate.battle.casualty.CasualtySortingUtil#sortPreBattle(List)
// Java:
//   units.sort(
//       Comparator.comparing(Unit::getType, Comparator.comparing(UnitType::getName))
//           .thenComparing(compareMarines())
//           .thenComparing(UnitComparator.getLowestToHighestMovementComparator()));
// Composite ordering: unit type name, then amphibious/marine flags, then
// movement-left ascending. The movement comparator caches Unit#getMovementLeft
// per Unit; we recreate that cache here via the rawptr-ctx factory and consult
// it inside the sort_by predicate.
@(private="file")
casualty_sorting_util_sort_pre_battle_ctx: struct {
	movement_cmp:     proc(rawptr, ^Unit, ^Unit) -> i32,
	movement_cmp_ctx: rawptr,
}

@(private="file")
casualty_sorting_util_sort_pre_battle_less :: proc(a: ^Unit, b: ^Unit) -> bool {
	ta := unit_get_type(a)
	tb := unit_get_type(b)
	na := ta.name if ta != nil else ""
	nb := tb.name if tb != nil else ""
	if na != nb {
		return na < nb
	}
	mc := casualty_sorting_util_marines_cmp(a, b)
	if mc != 0 {
		return mc < 0
	}
	ctx := casualty_sorting_util_sort_pre_battle_ctx
	mv := ctx.movement_cmp(ctx.movement_cmp_ctx, a, b)
	return mv < 0
}

casualty_sorting_util_sort_pre_battle :: proc(units: ^[dynamic]^Unit) {
	if units == nil || len(units^) < 2 {
		return
	}
	cmp, cmp_ctx := unit_comparator_get_lowest_to_highest_movement_comparator()
	casualty_sorting_util_sort_pre_battle_ctx = {
		movement_cmp     = cmp,
		movement_cmp_ctx = cmp_ctx,
	}
	slice.sort_by(units[:], casualty_sorting_util_sort_pre_battle_less)
}

