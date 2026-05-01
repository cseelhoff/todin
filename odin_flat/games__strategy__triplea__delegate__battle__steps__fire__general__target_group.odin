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

// lambda$sortTargetGroups$2(TargetGroup targetGroup):
// the Comparator.comparingInt(targetGroup -> targetGroup.getTargetUnitTypes().size())
// key extractor from sortTargetGroups. Returns the size of the group's
// target_unit_types set as i32 (Java int).
target_group_lambda__sort_target_groups__2 :: proc(target_group: ^Target_Group) -> i32 {
	return i32(len(target_group_get_target_unit_types(target_group)))
}
