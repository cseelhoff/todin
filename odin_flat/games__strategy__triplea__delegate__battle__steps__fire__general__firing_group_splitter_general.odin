package game

Firing_Group_Splitter_General :: struct {
	side:       Battle_State_Side,
	type:       Firing_Group_Splitter_General_Type,
	group_name: string,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.fire.general.FiringGroupSplitterGeneral

// ---------------------------------------------------------------------------
// Constructor: FiringGroupSplitterGeneral(Side, Type, String) (Lombok @Value
// staticConstructor = "of"). Translated as the package-wide `_new` factory.
// ---------------------------------------------------------------------------

firing_group_splitter_general_new :: proc(
	side: Battle_State_Side,
	type: Firing_Group_Splitter_General_Type,
	group_name: string,
) -> ^Firing_Group_Splitter_General {
	self := new(Firing_Group_Splitter_General)
	self.side = side
	self.type = type
	self.group_name = group_name
	return self
}

// ---------------------------------------------------------------------------
// filterAirVsSubTargetGroups(Collection<Unit> enemyUnits) -> Predicate<TargetGroup>
//
// The returned predicate captures `enemyUnits`, so it follows the project's
// closure-capture convention: a heap-allocated context struct paired with a
// `proc(rawptr, ^T) -> bool` callback.
// ---------------------------------------------------------------------------

Firing_Group_Splitter_General_Ctx_filter_air_vs_sub :: struct {
	enemy_units: [dynamic]^Unit,
}

firing_group_splitter_general_pred_filter_air_vs_sub :: proc(
	ctx_ptr: rawptr,
	target_group: ^Target_Group,
) -> bool {
	ctx := cast(^Firing_Group_Splitter_General_Ctx_filter_air_vs_sub)ctx_ptr

	// boolean allAir = targetGroup.getFiringUnitTypes().stream()
	//                            .allMatch(Matches.unitTypeIsAir());
	pred_air, ctx_air := matches_unit_type_is_air()
	all_air := true
	for ut, _ in target_group.firing_unit_types {
		if !pred_air(ctx_air, ut) {
			all_air = false
			break
		}
	}
	if !all_air {
		return false
	}

	// canNotBeTargetedUnitTypes = enemyUnits.stream()
	//   .filter(Matches.unitCanNotBeTargetedByAll())
	//   .map(Unit::getType)
	//   .filter(Matches.unitTypeIsSea())
	//   .collect(toList())
	pred_cnbt, ctx_cnbt := matches_unit_can_not_be_targeted_by_all()
	pred_sea, ctx_sea := matches_unit_type_is_sea()
	can_not_be_targeted: [dynamic]^Unit_Type
	for u in ctx.enemy_units {
		if !pred_cnbt(ctx_cnbt, u) {
			continue
		}
		ut := unit_get_type(u)
		if !pred_sea(ctx_sea, ut) {
			continue
		}
		append(&can_not_be_targeted, ut)
	}

	// targetTypes = new ArrayList<>(targetGroup.getTargetUnitTypes());
	// targetTypes.retainAll(canNotBeTargetedUnitTypes);
	// return targetTypes.isEmpty();
	for ut, _ in target_group.target_unit_types {
		for x in can_not_be_targeted {
			if x == ut {
				return false
			}
		}
	}
	return true
}

firing_group_splitter_general_filter_air_vs_sub_target_groups :: proc(
	self: ^Firing_Group_Splitter_General,
	enemy_units: [dynamic]^Unit,
) -> (proc(rawptr, ^Target_Group) -> bool, rawptr) {
	ctx := new(Firing_Group_Splitter_General_Ctx_filter_air_vs_sub)
	ctx.enemy_units = enemy_units
	return firing_group_splitter_general_pred_filter_air_vs_sub, rawptr(ctx)
}

