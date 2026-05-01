package game

import "core:fmt"

Firing_Group :: struct {
	display_name:   string,
	group_name:     string,
	firing_units:   [dynamic]^Unit,
	target_units:   [dynamic]^Unit,
	suicide_on_hit: bool,
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#getDisplayName
firing_group_get_display_name :: proc(self: ^Firing_Group) -> string {
	return self.display_name
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#getGroupName
firing_group_get_group_name :: proc(self: ^Firing_Group) -> string {
	return self.group_name
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#getFiringUnits
firing_group_get_firing_units :: proc(self: ^Firing_Group) -> [dynamic]^Unit {
	return self.firing_units
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#getTargetUnits
firing_group_get_target_units :: proc(self: ^Firing_Group) -> [dynamic]^Unit {
	return self.target_units
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#isSuicideOnHit
firing_group_is_suicide_on_hit :: proc(self: ^Firing_Group) -> bool {
	return self.suicide_on_hit
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#retainAliveTargets
// Java: targetUnits.retainAll(new HashSet<>(aliveUnits))
firing_group_retain_alive_targets :: proc(self: ^Firing_Group, alive_units: [dynamic]^Unit) {
	alive_set: map[^Unit]struct{}
	defer delete(alive_set)
	for u in alive_units {
		alive_set[u] = {}
	}
	kept: [dynamic]^Unit
	for u in self.target_units {
		if u in alive_set {
			append(&kept, u)
		}
	}
	delete(self.target_units)
	self.target_units = kept
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#<init>(String,String,Collection<Unit>,Collection<Unit>)
// Private 4-arg constructor used by groupBySuicideOnHit. Computes suicideOnHit
// from the firing units (all must be suicide-on-hit; allMatch on empty == true).
firing_group_new :: proc(
	display_name: string,
	group_name: string,
	firing_units: [dynamic]^Unit,
	target_units: [dynamic]^Unit,
) -> ^Firing_Group {
	self := new(Firing_Group)
	self.display_name = display_name
	self.group_name = group_name
	self.firing_units = firing_units
	self.target_units = target_units
	pred, ctx := matches_unit_is_suicide_on_hit()
	all_suicide := true
	for u in self.firing_units {
		if !pred(ctx, u) {
			all_suicide = false
			break
		}
	}
	self.suicide_on_hit = all_suicide
	return self
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroup#generateName(String, Collection<Unit>, FiringGroup$SuicideAndNonSuicide)
// Static helper: builds the display name suffix based on whether the unit
// breakdown produced a single bucket, a single suicide+non-suicide pair, or
// multiple suicide buckets that need their unit-type name appended.
firing_group_generate_name :: proc(
	original_name: string,
	firing_units: [dynamic]^Unit,
	separated_by_suicide: ^Firing_Group_Suicide_And_Non_Suicide,
) -> string {
	group_count := firing_group_suicide_and_non_suicide_group_count(separated_by_suicide)
	if group_count == 1 {
		return original_name
	}

	pred, ctx := matches_unit_is_suicide_on_hit()
	all_suicide := true
	for u in firing_units {
		if !pred(ctx, u) {
			all_suicide = false
			break
		}
	}

	if group_count == 2 &&
	   len(separated_by_suicide.non_suicide_group) > 0 &&
	   all_suicide {
		return fmt.aprintf("%s suicide", original_name)
	}

	if all_suicide {
		any_unit := firing_units[0]
		ut := unit_get_type(any_unit)
		ut_name := default_named_get_name(&ut.named_attachable.default_named)
		return fmt.aprintf("%s suicide %s", original_name, ut_name)
	}
	return original_name
}
