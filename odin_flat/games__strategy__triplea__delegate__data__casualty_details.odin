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

// Java: public CasualtyDetails(Collection<Unit> killed, Collection<Unit> damaged, boolean autoCalculated)
casualty_details_new_from_collections :: proc(
	killed: []^Unit,
	damaged: []^Unit,
	auto_calculated: bool,
) -> ^Casualty_Details {
	self := new(Casualty_Details)
	casualty_list_init(&self.casualty_list, killed, damaged)
	self.auto_calculated = auto_calculated
	return self
}

// Java: public CasualtyDetails(CasualtyList casualties, boolean autoCalculated)
//   super(casualties == null ? null : casualties.getKilled(),
//         casualties == null ? null : casualties.getDamaged());
casualty_details_new_from_list_auto_calculated :: proc(
	casualties: ^Casualty_List,
	auto_calculated: bool,
) -> ^Casualty_Details {
	self := new(Casualty_Details)
	if casualties != nil {
		casualty_list_init(
			&self.casualty_list,
			casualties.killed[:],
			casualties.damaged[:],
		)
	} else {
		self.casualty_list.killed = make([dynamic]^Unit)
		self.casualty_list.damaged = make([dynamic]^Unit)
	}
	self.auto_calculated = auto_calculated
	return self
}

// Java: public void ensureUnitsAreKilledFirst(
//           Collection<Unit> targets,
//           Predicate<Unit> matcher,
//           Comparator<Unit> shouldBeKilledFirst)
//
// Replaces the units in `killed` that match `matcher` by the same number of
// units in `targets` that match `matcher` and are first according to
// `shouldBeKilledFirst`.
casualty_details_ensure_units_are_killed_first :: proc(
	self: ^Casualty_Details,
	targets: []^Unit,
	matcher: proc(^Unit) -> bool,
	should_be_killed_first: proc(^Unit, ^Unit) -> bool,
) {
	// targets.stream().collect(Collectors.groupingBy(UnitOwner::new, Collectors.toList()))
	targets_grouped_by_owner_and_type := make(map[Unit_Owner][dynamic]^Unit)
	defer {
		for _, v in &targets_grouped_by_owner_and_type do delete(v)
		delete(targets_grouped_by_owner_and_type)
	}
	for u in targets {
		key := Unit_Owner{type = unit_get_type(u), owner = unit_get_owner(u)}
		if _, ok := targets_grouped_by_owner_and_type[key]; !ok {
			targets_grouped_by_owner_and_type[key] = make([dynamic]^Unit)
		}
		bucket := &targets_grouped_by_owner_and_type[key]
		append(bucket, u)
	}

	// getKilled().stream().filter(matcher)
	//   .collect(Collectors.groupingBy(UnitOwner::new, Collectors.toList()))
	old_units_grouped_by_owner_and_type := make(map[Unit_Owner][dynamic]^Unit)
	defer {
		for _, v in &old_units_grouped_by_owner_and_type do delete(v)
		delete(old_units_grouped_by_owner_and_type)
	}
	for u in self.killed {
		if !matcher(u) do continue
		key := Unit_Owner{type = unit_get_type(u), owner = unit_get_owner(u)}
		if _, ok := old_units_grouped_by_owner_and_type[key]; !ok {
			old_units_grouped_by_owner_and_type[key] = make([dynamic]^Unit)
		}
		bucket := &old_units_grouped_by_owner_and_type[key]
		append(bucket, u)
	}

	killed_with_correct_order := casualty_details_ensure_units_are_killed_first_private(
		self,
		should_be_killed_first,
		&targets_grouped_by_owner_and_type,
		&old_units_grouped_by_owner_and_type,
	)
	defer delete(killed_with_correct_order)

	// killed.addAll(killedWithCorrectOrder.stream()
	//                  .filter(unit -> !killed.contains(unit))
	//                  .collect(Collectors.toList()));
	for u in killed_with_correct_order {
		already := false
		for k in self.killed {
			if k == u {
				already = true
				break
			}
		}
		if !already {
			append(&self.killed, u)
		}
	}

	// killed.removeIf(matcher.and(not(killedWithCorrectOrder::contains)));
	write_idx := 0
	for i := 0; i < len(self.killed); i += 1 {
		u := self.killed[i]
		in_correct := false
		for c in killed_with_correct_order {
			if c == u {
				in_correct = true
				break
			}
		}
		remove := matcher(u) && !in_correct
		if !remove {
			self.killed[write_idx] = u
			write_idx += 1
		}
	}
	resize(&self.killed, write_idx)
}

// Java: public CasualtyDetails()
//   Empty details, with autoCalculated as true.
casualty_details_new :: proc() -> ^Casualty_Details {
	self := new(Casualty_Details)
	casualty_list_init(&self.casualty_list, []^Unit{}, []^Unit{})
	self.auto_calculated = true
	return self
}

// Java: public CasualtyDetails(boolean autoCalculated)
//   Empty details, with the supplied autoCalculated flag.
casualty_details_new_auto_calculated :: proc(auto: bool) -> ^Casualty_Details {
	self := new(Casualty_Details)
	casualty_list_init(&self.casualty_list, []^Unit{}, []^Unit{})
	self.auto_calculated = auto
	return self
}

// Java: lambda for `isMarine`
//   unit -> unit.getUnitAttachment().getIsMarine() != 0
casualty_details_lambda_ensure_units_with_positive_marine_bonus_are_killed_last_is_marine :: proc(
	u: ^Unit,
) -> bool {
	return unit_attachment_get_is_marine(unit_get_unit_attachment(u)) != 0
}

// Java: lambda for `positiveMarineEffectFirstNegativeMarineEffectLast`
//   (unit1, unit2) -> {
//     if (unit1.getUnitAttachment().getIsMarine() > 0) {
//       return Boolean.compare(unit1.getWasAmphibious(), unit2.getWasAmphibious());
//     } else {
//       return Boolean.compare(unit2.getWasAmphibious(), unit1.getWasAmphibious());
//     }
//   }
// Returned as a "less-than" comparator (true iff u1 should sort before u2).
// Boolean.compare(a, b) < 0  ⇔  !a && b   (since false < true).
casualty_details_lambda_ensure_units_with_positive_marine_bonus_are_killed_last_cmp :: proc(
	u1: ^Unit,
	u2: ^Unit,
) -> bool {
	is_marine_1 := unit_attachment_get_is_marine(unit_get_unit_attachment(u1))
	a1 := unit_get_was_amphibious(u1)
	a2 := unit_get_was_amphibious(u2)
	if is_marine_1 > 0 {
		// Boolean.compare(a1, a2) < 0
		return !a1 && a2
	}
	// Boolean.compare(a2, a1) < 0
	return a1 && !a2
}

// Java: private static void redistributeHits(
//           List<Unit> targetsWithHitsBeforeRedistribution,
//           List<Unit> targets,
//           Comparator<Unit> shouldTakeHitsFirst,
//           List<Unit> targetsHitWithCorrectOrder)
//
// Redistributes the hits from targetsWithHitsBeforeRedistribution among
// targets according to which units shouldTakeHitsFirst. Mutates `targets`
// (sorted in place) and appends the resulting per-hit unit references to
// `targetsHitWithCorrectOrder`.
casualty_details_redistribute_hits :: proc(
	targets_with_hits_before_redistribution: ^[dynamic]^Unit,
	targets: ^[dynamic]^Unit,
	should_take_hits_first: proc(^Unit, ^Unit) -> bool,
	targets_hit_with_correct_order: ^[dynamic]^Unit,
) {
	// targets.sort(shouldTakeHitsFirst);
	slice.sort_by(targets[:], should_take_hits_first)

	// targetsWithHitsBeforeRedistribution.stream()
	//   .collect(Collectors.groupingBy(e -> e, Collectors.counting()))
	//   .values().stream()
	//   .sorted(Comparator.reverseOrder())   // descending
	//   .collect(Collectors.toList())
	hits_per_unit := make(map[^Unit]int)
	defer delete(hits_per_unit)
	// Preserve first-encountered insertion order for deterministic iteration
	// when units share the same count (mirrors Java's HashMap behavior, which
	// is unspecified but typically stable for a given JVM run; the algorithm
	// does not rely on a specific tie-breaking order).
	insertion_order := make([dynamic]^Unit, 0)
	defer delete(insertion_order)
	for u in targets_with_hits_before_redistribution {
		if _, ok := hits_per_unit[u]; !ok {
			append(&insertion_order, u)
		}
		hits_per_unit[u] = hits_per_unit[u] + 1
	}
	counts := make([dynamic]int, 0, len(insertion_order))
	defer delete(counts)
	for u in insertion_order {
		append(&counts, hits_per_unit[u])
	}
	// Sort in descending order.
	slice.sort_by(counts[:], proc(a, b: int) -> bool { return a > b })

	// while (iter.hasNext() || hitsToRedistribute > 0) { ... }
	hits_to_redistribute := 0
	count_idx := 0
	unit_idx := 0
	for count_idx < len(counts) || hits_to_redistribute > 0 {
		if count_idx < len(counts) {
			hits_to_redistribute += counts[count_idx]
			count_idx += 1
		}

		// final Unit unit = unitIterator.next();
		// (Java would throw NoSuchElementException if exhausted; mirror by
		// indexing — caller contract guarantees enough targets.)
		unit := targets[unit_idx]
		unit_idx += 1

		hits_to_redistribute_to_unit := cast(int)unit_hits_unit_can_take_hit_without_being_killed(
			unit,
		)
		if hits_to_redistribute < hits_to_redistribute_to_unit {
			hits_to_redistribute_to_unit = hits_to_redistribute
		}
		hits_to_redistribute -= hits_to_redistribute_to_unit

		for i := 0; i < hits_to_redistribute_to_unit; i += 1 {
			append(targets_hit_with_correct_order, unit)
		}
	}
}

// Java: public void ensureUnitsWithPositiveMarineBonusAreKilledLast(Collection<Unit> units)
//
// Ensures that any killed or damaged units have no better marine effect than
// others of the same type. `units` should be a superset of the union of
// `killed` and `damaged`.
casualty_details_ensure_units_with_positive_marine_bonus_are_killed_last :: proc(
	self: ^Casualty_Details,
	units: []^Unit,
) {
	casualty_details_ensure_units_are_killed_first(
		self,
		units,
		casualty_details_lambda_ensure_units_with_positive_marine_bonus_are_killed_last_is_marine,
		casualty_details_lambda_ensure_units_with_positive_marine_bonus_are_killed_last_cmp,
	)
}

