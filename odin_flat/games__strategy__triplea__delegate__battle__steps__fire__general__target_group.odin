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
