package game

import "core:slice"

Target_Group :: struct {
	firing_unit_types: map[^Unit_Type]struct{},
	target_unit_types: map[^Unit_Type]struct{},
}

// TargetGroup(UnitType firingUnitType, Set<UnitType> targetUnitTypes):
// firingUnitTypes := Sets.newHashSet(firingUnitType); this.targetUnitTypes := targetUnitTypes.
target_group_new :: proc(
	firing_unit_type: ^Unit_Type,
	target_unit_types: map[^Unit_Type]struct{},
) -> ^Target_Group {
	self := new(Target_Group)
	self.firing_unit_types = make(map[^Unit_Type]struct{})
	self.firing_unit_types[firing_unit_type] = {}
	self.target_unit_types = target_unit_types
	return self
}

// @Getter(AccessLevel.PACKAGE) Set<UnitType> getFiringUnitTypes().
target_group_get_firing_unit_types :: proc(self: ^Target_Group) -> map[^Unit_Type]struct{} {
	return self.firing_unit_types
}

// @Getter(AccessLevel.PACKAGE) Set<UnitType> getTargetUnitTypes().
target_group_get_target_unit_types :: proc(self: ^Target_Group) -> map[^Unit_Type]struct{} {
	return self.target_unit_types
}

// public List<Unit> getFiringUnits(Collection<Unit> units):
//   return CollectionUtils.getMatches(units, Matches.unitIsOfTypes(firingUnitTypes));
// `collection_utils_get_matches` operates on `[dynamic]rawptr` with a
// non-capturing predicate, while the matches_* factories produce a
// (proc(rawptr, ^Unit) -> bool, rawptr) pair. Bridging the two would
// require fabricating a wrapper closure; the Java source is itself a
// single-pass filter, so we inline the loop and call the predicate
// pair directly (same convention used in canal_attachment.odin).
target_group_get_firing_units :: proc(
	self: ^Target_Group,
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	p, c := matches_unit_is_of_types(self.firing_unit_types)
	for u in units {
		if p(c, u) {
			append(&result, u)
		}
	}
	return result
}

// public Collection<Unit> getTargetUnits(Collection<Unit> units):
//   return CollectionUtils.getMatches(units, Matches.unitIsOfTypes(targetUnitTypes));
target_group_get_target_units :: proc(
	self: ^Target_Group,
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	p, c := matches_unit_is_of_types(self.target_unit_types)
	for u in units {
		if p(c, u) {
			append(&result, u)
		}
	}
	return result
}

// private static Set<UnitType> findTargets(UnitType unitType, boolean destroyerPresent,
//     Set<UnitType> enemyUnitTypes):
//   Set<UnitType> cannotTarget = unitType.getUnitAttachment().getCanNotTarget();
//   return enemyUnitTypes.stream().filter(t -> {
//     if (cannotTarget.contains(t)) return false;
//     if (destroyerPresent) return true;
//     return !t.getUnitAttachment().getCanNotBeTargetedBy().contains(unitType);
//   }).collect(Collectors.toSet());
// The Java single-pass stream filter is inlined directly; the result is a
// new owned `map[^Unit_Type]struct{}` standing in for `Set<UnitType>`.
target_group_find_targets :: proc(
	unit_type: ^Unit_Type,
	destroyer_present: bool,
	enemy_unit_types: map[^Unit_Type]struct{},
) -> map[^Unit_Type]struct{} {
	cannot_target := unit_attachment_get_can_not_target(unit_type_get_unit_attachment(unit_type))
	result := make(map[^Unit_Type]struct{})
	for target_unit_type, _ in enemy_unit_types {
		if _, in_cannot := cannot_target[target_unit_type]; in_cannot {
			continue
		}
		if destroyer_present {
			result[target_unit_type] = {}
			continue
		}
		cnbt := unit_attachment_get_can_not_be_targeted_by(
			unit_type_get_unit_attachment(target_unit_type),
		)
		if _, blocked := cnbt[unit_type]; !blocked {
			result[target_unit_type] = {}
		}
	}
	return result
}

// lambda$findTargets$0(Set<UnitType> cannotTarget, boolean destroyerPresent,
//     UnitType unitType, UnitType targetUnitType):
// the .filter predicate inside findTargets. Returns true iff the candidate
// targetUnitType is targetable by `unitType` given the captured cannotTarget
// set and destroyer-presence flag.
target_group_lambda_find_targets_0 :: proc(
	cannot_target: map[^Unit_Type]struct{},
	destroyer_present: bool,
	unit_type: ^Unit_Type,
	target_unit_type: ^Unit_Type,
) -> bool {
	if _, in_cannot := cannot_target[target_unit_type]; in_cannot {
		return false
	}
	if destroyer_present {
		return true
	}
	cnbt := unit_attachment_get_can_not_be_targeted_by(
		unit_type_get_unit_attachment(target_unit_type),
	)
	_, blocked := cnbt[unit_type]
	return !blocked
}

// findTargetsInTargetGroups: find a TargetGroup whose targetUnitTypes equals
// the given targets set, returning Optional<TargetGroup>. Odin port returns
// the pointer to the matching Target_Group, or nil for Optional.empty().
target_group_find_targets_in_target_groups :: proc(
	targets: map[^Unit_Type]struct{},
	target_groups: [dynamic]^Target_Group,
) -> ^Target_Group {
	for tg in target_groups {
		other := tg.target_unit_types
		if len(other) != len(targets) {
			continue
		}
		all_present := true
		for k, _ in targets {
			if _, ok := other[k]; !ok {
				all_present = false
				break
			}
		}
		if all_present {
			return tg
		}
	}
	return nil
}

// sortTargetGroups: sort by Comparator.comparingInt(tg -> tg.targetUnitTypes.size()).
// Stream.sorted is stable; slice.sort_by uses a stable order under the strict
// less-than predicate below (only swaps when a's size is strictly less).
target_group_sort_target_groups :: proc(
	target_groups: [dynamic]^Target_Group,
) -> [dynamic]^Target_Group {
	result := make([dynamic]^Target_Group, 0, len(target_groups))
	for tg in target_groups {
		append(&result, tg)
	}
	slice.sort_by(result[:], proc(a, b: ^Target_Group) -> bool {
		return len(a.target_unit_types) < len(b.target_unit_types)
	})
	return result
}

// lambda$findTargetsInTargetGroups$1(Set<UnitType> targets, TargetGroup targetGroup):
// the .filter(targetGroup -> targetGroup.getTargetUnitTypes().equals(targets))
// predicate from findTargetsInTargetGroups. Returns true iff the target_group's
// target_unit_types set equals the captured `targets` set (Java Set.equals →
// same size + same elements).
target_group_lambda__find_targets_in_target_groups__1 :: proc(
	targets: map[^Unit_Type]struct{},
	target_group: ^Target_Group,
) -> bool {
	other := target_group_get_target_unit_types(target_group)
	if len(other) != len(targets) {
		return false
	}
	for k, _ in targets {
		if _, ok := other[k]; !ok {
			return false
		}
	}
	return true
}

// public static List<TargetGroup> newTargetGroups(Collection<Unit> units,
//     Collection<Unit> enemyUnits): build TargetGroups for firing/enemy units
// using canNotTarget / canNotBeTargetedBy attributes (destroyer presence
// cancels canNotBeTargetedBy), then sort ascending by target set size.
target_group_new_target_groups :: proc(
	units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> [dynamic]^Target_Group {
	unit_types := unit_utils_get_unit_types_from_unit_list(units)
	destroyer_present := false
	{
		p, c := matches_unit_type_is_destroyer()
		for ut, _ in unit_types {
			if p(c, ut) {
				destroyer_present = true
				break
			}
		}
	}
	enemy_unit_types := unit_utils_get_unit_types_from_unit_list(enemy_units)
	target_groups: [dynamic]^Target_Group
	for unit_type, _ in unit_types {
		targets := target_group_find_targets(unit_type, destroyer_present, enemy_unit_types)
		if len(targets) == 0 {
			continue
		}
		existing := target_group_find_targets_in_target_groups(targets, target_groups)
		if existing != nil {
			existing.firing_unit_types[unit_type] = {}
		} else {
			append(&target_groups, target_group_new(unit_type, targets))
		}
	}
	return target_group_sort_target_groups(target_groups)
}

// lambda$sortTargetGroups$2(TargetGroup targetGroup):
// the Comparator.comparingInt(targetGroup -> targetGroup.getTargetUnitTypes().size())
// key extractor from sortTargetGroups. Returns the size of the group's
// target_unit_types set as i32 (Java int).
target_group_lambda__sort_target_groups__2 :: proc(target_group: ^Target_Group) -> i32 {
	return i32(len(target_group_get_target_unit_types(target_group)))
}
