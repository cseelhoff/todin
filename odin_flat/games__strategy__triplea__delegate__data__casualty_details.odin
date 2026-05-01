package game

import "core:slice"

Casualty_Details :: struct {
	using casualty_list: Casualty_List,
	auto_calculated: bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.data.CasualtyDetails

// Java: public boolean getAutoCalculated()
casualty_details_get_auto_calculated :: proc(self: ^Casualty_Details) -> bool {
	return self.auto_calculated
}

// Closure context for lambda$ensureUnitsAreKilledFirst$0 — captures the
// enclosing CasualtyList's `killed` collection so the predicate can ask
// "is this unit not yet in `killed`?".
Casualty_Details_Lambda_Ensure_Units_Are_Killed_First_0_Ctx :: struct {
	killed: ^[dynamic]^Unit,
}

// Java: lambda$ensureUnitsAreKilledFirst$0(Unit)
//   unit -> !killed.contains(unit)
casualty_details_lambda_ensure_units_are_killed_first_0 :: proc(
	ctx: rawptr,
	unit: ^Unit,
) -> bool {
	c := cast(^Casualty_Details_Lambda_Ensure_Units_Are_Killed_First_0_Ctx)ctx
	for u in c.killed do if u == unit do return false
	return true
}

// Closure context for lambda$ensureUnitsAreKilledFirst$1 — captures the
// "all units grouped by owner+type" map and the comparator so the
// per-entry mapper can sort and truncate the right slice.
Casualty_Details_Lambda_Ensure_Units_Are_Killed_First_1_Ctx :: struct {
	all_units_grouped_by_owner_and_type: ^map[Unit_Owner][dynamic]^Unit,
	should_be_killed_first:              proc(^Unit, ^Unit) -> bool,
}

// Java: lambda$ensureUnitsAreKilledFirst$1(Map, Comparator, Map.Entry)
//   entry -> allUnitsGroupedByOwnerAndType.get(entry.getKey()).stream()
//              .sorted(shouldBeKilledFirst)
//              .limit(entry.getValue().size())
// Returns the per-entry slice of units (newly allocated; caller owns it).
casualty_details_lambda_ensure_units_are_killed_first_1 :: proc(
	ctx: rawptr,
	entry_key: Unit_Owner,
	entry_value_size: int,
) -> [dynamic]^Unit {
	c := cast(^Casualty_Details_Lambda_Ensure_Units_Are_Killed_First_1_Ctx)ctx
	src, ok := c.all_units_grouped_by_owner_and_type[entry_key]
	if !ok {
		return make([dynamic]^Unit, 0, 0)
	}
	sorted_units := make([dynamic]^Unit, 0, len(src))
	for u in src do append(&sorted_units, u)
	slice.sort_by(sorted_units[:], c.should_be_killed_first)
	limit := entry_value_size
	if limit > len(sorted_units) do limit = len(sorted_units)
	out := make([dynamic]^Unit, 0, limit)
	for i := 0; i < limit; i += 1 do append(&out, sorted_units[i])
	delete(sorted_units)
	return out
}

// Java: lambda$redistributeHits$2(Unit)
//   e -> e   (identity classifier passed to Collectors.groupingBy)
casualty_details_lambda_redistribute_hits_2 :: proc(e: ^Unit) -> ^Unit {
	return e
}

// Java: private List<Unit> ensureUnitsAreKilledFirst(
//           Comparator<Unit> shouldBeKilledFirst,
//           Map<UnitOwner, List<Unit>> allUnitsGroupedByOwnerAndType,
//           Map<UnitOwner, List<Unit>> oldUnitsGroupedByOwnerAndType)
//
// For each entry in oldUnitsGroupedByOwnerAndType, sort the matching slice
// of allUnitsGroupedByOwnerAndType by `shouldBeKilledFirst` and take the
// first N (where N is the entry's list size); flatMap the per-entry slices
// into a single list.
casualty_details_ensure_units_are_killed_first_private :: proc(
	self: ^Casualty_Details,
	should_be_killed_first: proc(^Unit, ^Unit) -> bool,
	all_units_grouped_by_owner_and_type: ^map[Unit_Owner][dynamic]^Unit,
	old_units_grouped_by_owner_and_type: ^map[Unit_Owner][dynamic]^Unit,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	ctx := Casualty_Details_Lambda_Ensure_Units_Are_Killed_First_1_Ctx {
		all_units_grouped_by_owner_and_type = all_units_grouped_by_owner_and_type,
		should_be_killed_first              = should_be_killed_first,
	}
	for key, value in old_units_grouped_by_owner_and_type^ {
		chunk := casualty_details_lambda_ensure_units_are_killed_first_1(
			&ctx,
			key,
			len(value),
		)
		for u in chunk do append(&result, u)
		delete(chunk)
	}
	return result
}

