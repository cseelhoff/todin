package game

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
