package game

import "core:fmt"
import "core:slice"

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

// ---------------------------------------------------------------------------
// getCombatParticipants(BattleState, Side, Collection<Unit> units,
//                       Collection<Unit> enemyUnits) -> Collection<Unit>
//
// Mirrors MustFightBattle.removeNonCombatants() filtering: keep only units
// for which Matches.unitCanParticipateInCombat(...) holds, with battleRound
// hard-coded to 1 (matches the Java source).
// ---------------------------------------------------------------------------

firing_group_splitter_general_get_combat_participants :: proc(
	self: ^Firing_Group_Splitter_General,
	battle_state: ^Battle_State,
	side: Battle_State_Side,
	units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	pred, pred_ctx := matches_unit_can_participate_in_combat(
		side == .OFFENSE,
		battle_state_get_player(battle_state, side),
		battle_state_get_battle_site(battle_state),
		1,
		enemy_units,
	)
	result: [dynamic]^Unit
	for u in units {
		if pred(pred_ctx, u) {
			append(&result, u)
		}
	}
	return result
}

// ---------------------------------------------------------------------------
// buildFiringGroups(String name, Collection<Unit> canFire,
//                   Collection<Unit> enemyUnits, TargetGroup targetGroup)
//   -> List<FiringGroup>
//
//   Collection<Unit> firingUnits = targetGroup.getFiringUnits(canFire);
//   Collection<Unit> targetUnits = targetGroup.getTargetUnits(enemyUnits);
//   return FiringGroup.groupBySuicideOnHit(name, firingUnits, targetUnits);
// ---------------------------------------------------------------------------

firing_group_splitter_general_build_firing_groups :: proc(
	self: ^Firing_Group_Splitter_General,
	name: string,
	can_fire: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	target_group: ^Target_Group,
) -> [dynamic]^Firing_Group {
	firing_units := target_group_get_firing_units(target_group, can_fire)
	target_units := target_group_get_target_units(target_group, enemy_units)
	return firing_group_group_by_suicide_on_hit(name, firing_units, target_units)
}

// ---------------------------------------------------------------------------
// getFiringUnitPredicate(BattleState) -> Predicate<Unit>
//
//   Predicate<Unit> predicate =
//       (side == OFFENSE) ? Matches.unitIsFirstStrike()
//                         : Matches.unitIsFirstStrikeOnDefense(properties);
//   return type == NORMAL ? predicate.negate() : predicate;
//
// Returns the project's `(proc(rawptr, ^Unit) -> bool, rawptr)` closure
// pair so the result can be composed alongside the other Matches.* helpers.
// ---------------------------------------------------------------------------

Firing_Group_Splitter_General_Ctx_firing_unit_pred :: struct {
	inner_pred: proc(rawptr, ^Unit) -> bool,
	inner_ctx:  rawptr,
	negate:     bool,
}

firing_group_splitter_general_pred_firing_unit :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	c := cast(^Firing_Group_Splitter_General_Ctx_firing_unit_pred)ctx_ptr
	r := c.inner_pred(c.inner_ctx, u)
	if c.negate {
		return !r
	}
	return r
}

firing_group_splitter_general_get_firing_unit_predicate :: proc(
	self: ^Firing_Group_Splitter_General,
	battle_state: ^Battle_State,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	inner_p: proc(rawptr, ^Unit) -> bool
	inner_c: rawptr
	if self.side == .OFFENSE {
		inner_p, inner_c = matches_unit_is_first_strike()
	} else {
		inner_p, inner_c = matches_unit_is_first_strike_on_defense(
			game_data_get_properties(battle_state_get_game_data(battle_state)),
		)
	}
	ctx := new(Firing_Group_Splitter_General_Ctx_firing_unit_pred)
	ctx.inner_pred = inner_p
	ctx.inner_ctx = inner_c
	ctx.negate = self.type == .NORMAL
	return firing_group_splitter_general_pred_firing_unit, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// generateNamedGroups(String name, Collection<FiringGroup> firingGroups,
//                     Collection<TargetGroup> targetGroups,
//                     Collection<Unit> canFire, Collection<Unit> enemyUnits)
//
// Java mutates the passed-in `firingGroups` collection; the Odin port takes
// it as `^[dynamic]^Firing_Group` so the caller sees the appended entries.
// ---------------------------------------------------------------------------

firing_group_splitter_general_named_groups_unit_less :: proc(a, b: ^Unit) -> bool {
	na := default_named_get_name(&unit_get_type(a).named_attachable.default_named)
	nb := default_named_get_name(&unit_get_type(b).named_attachable.default_named)
	return na < nb
}

firing_group_splitter_general_generate_named_groups :: proc(
	self: ^Firing_Group_Splitter_General,
	name: string,
	firing_groups: ^[dynamic]^Firing_Group,
	target_groups: [dynamic]^Target_Group,
	can_fire: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) {
	if len(target_groups) == 1 {
		built := firing_group_splitter_general_build_firing_groups(
			self,
			name,
			can_fire,
			enemy_units,
			target_groups[0],
		)
		for g in built {
			append(firing_groups, g)
		}
		return
	}
	// use the first unitType name of each TargetGroup as a suffix for the
	// FiringGroup name. Sort units first so the chosen name is independent
	// of input ordering.
	for tg in target_groups {
		firing_units := target_group_get_firing_units(tg, can_fire)
		slice.sort_by(firing_units[:], firing_group_splitter_general_named_groups_unit_less)
		first := firing_units[0]
		ut := unit_get_type(first)
		ut_name := default_named_get_name(&ut.named_attachable.default_named)
		sub_name := fmt.aprintf("%s %s", name, ut_name)
		built := firing_group_splitter_general_build_firing_groups(
			self,
			sub_name,
			can_fire,
			enemy_units,
			tg,
		)
		for g in built {
			append(firing_groups, g)
		}
	}
}

// ---------------------------------------------------------------------------
// apply(BattleState) -> List<FiringGroup>
//
// Implements the Function<BattleState, Collection<FiringGroup>> entry point:
//   1. Collect ourUnits (ACTIVE on side) and enemyUnits (ALIVE on opposite).
//   2. enemyCombatants = combat participants on opposite side, filtered by
//      Matches.unitIsNotInfrastructure() AND (side == DEFENSE ?
//      !suicideOnAttack : true) AND (side == OFFENSE ? !suicideOnDefense :
//      true).
//   3. canFire = combat participants on side, filtered by
//      getFiringUnitPredicate(battleState), additionally restricted to
//      battleState.getPlayer(side)'s own units when side == OFFENSE and
//      Properties.getAlliedAirIndependent(...) is false.
//   4. Build TargetGroup list. If size 1, just buildFiringGroups; else split
//      out the air-vs-sub groups (named AIR_FIRE_NON_SUBS) from the rest
//      (named groupName) via generateNamedGroups.
//
// BattleState.UnitBattleFilter.ACTIVE corresponds to {ALIVE, CASUALTY} per
// the Java enum definition; ALIVE corresponds to {ALIVE}.
// ---------------------------------------------------------------------------

firing_group_splitter_general_apply :: proc(
	self: ^Firing_Group_Splitter_General,
	battle_state: ^Battle_State,
) -> [dynamic]^Firing_Group {
	active_filter := battle_state_unit_battle_filter_new(.Alive, .Casualty)
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	opposite := battle_state_side_get_opposite(self.side)

	our_units := battle_state_filter_units(battle_state, active_filter, self.side)
	enemy_units := battle_state_filter_units(battle_state, alive_filter, opposite)

	// enemyCombatants: getCombatParticipants(battleState, opposite, enemyUnits, ourUnits)
	// then keep iff unitIsNotInfrastructure AND (side==DEFENSE → !suicideOnAttack)
	// AND (side==OFFENSE → !suicideOnDefense).
	enemy_participants := firing_group_splitter_general_get_combat_participants(
		self,
		battle_state,
		opposite,
		enemy_units,
		our_units,
	)
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	soa_p, soa_c := matches_unit_is_suicide_on_attack()
	sod_p, sod_c := matches_unit_is_suicide_on_defense()
	enemy_combatants: [dynamic]^Unit
	for u in enemy_participants {
		if !ni_p(ni_c, u) {
			continue
		}
		if self.side == .DEFENSE && soa_p(soa_c, u) {
			continue
		}
		if self.side == .OFFENSE && sod_p(sod_c, u) {
			continue
		}
		append(&enemy_combatants, u)
	}

	// canFire: getCombatParticipants(battleState, side, ourUnits, enemyUnits)
	// then keep iff getFiringUnitPredicate(battleState) AND (when side==OFFENSE
	// and !alliedAirIndependent → unitIsOwnedBy(battleState.getPlayer(side))).
	our_participants := firing_group_splitter_general_get_combat_participants(
		self,
		battle_state,
		self.side,
		our_units,
		enemy_units,
	)
	fp_p, fp_c := firing_group_splitter_general_get_firing_unit_predicate(self, battle_state)
	restrict_to_owned :=
		self.side == .OFFENSE &&
		!properties_get_allied_air_independent(
			game_data_get_properties(battle_state_get_game_data(battle_state)),
		)
	owned_p: proc(rawptr, ^Unit) -> bool
	owned_c: rawptr
	if restrict_to_owned {
		owned_p, owned_c = matches_unit_is_owned_by(battle_state_get_player(battle_state, self.side))
	}
	can_fire: [dynamic]^Unit
	for u in our_participants {
		if !fp_p(fp_c, u) {
			continue
		}
		if restrict_to_owned && !owned_p(owned_c, u) {
			continue
		}
		append(&can_fire, u)
	}

	firing_groups: [dynamic]^Firing_Group
	target_groups := target_group_new_target_groups(can_fire, enemy_combatants)
	if len(target_groups) == 1 {
		built := firing_group_splitter_general_build_firing_groups(
			self,
			self.group_name,
			can_fire,
			enemy_combatants,
			target_groups[0],
		)
		for g in built {
			append(&firing_groups, g)
		}
	} else {
		// Split off air-vs-sub TargetGroups; name them AIR_FIRE_NON_SUBS.
		// generateNamedGroups handles size-1 vs size-N internally.
		air_pred, air_ctx := firing_group_splitter_general_filter_air_vs_sub_target_groups(
			self,
			enemy_units,
		)
		air_vs_sub_groups: [dynamic]^Target_Group
		remaining: [dynamic]^Target_Group
		for tg in target_groups {
			if air_pred(air_ctx, tg) {
				append(&air_vs_sub_groups, tg)
			} else {
				append(&remaining, tg)
			}
		}
		if len(air_vs_sub_groups) > 0 {
			firing_group_splitter_general_generate_named_groups(
				self,
				BATTLE_STEP_AIR_FIRE_NON_SUBS,
				&firing_groups,
				air_vs_sub_groups,
				can_fire,
				enemy_combatants,
			)
		}
		if len(remaining) > 0 {
			firing_group_splitter_general_generate_named_groups(
				self,
				self.group_name,
				&firing_groups,
				remaining,
				can_fire,
				enemy_combatants,
			)
		}
	}
	return firing_groups
}


// Wrapper matching the fire_round_steps_factory_builder firing_group_splitter
// proc-value signature `(rawptr, ^Battle_State) -> [dynamic]^Firing_Group`.
firing_group_splitter_general_apply_raw :: proc(
	self_raw: rawptr,
	state: ^Battle_State,
) -> [dynamic]^Firing_Group {
	return firing_group_splitter_general_apply(cast(^Firing_Group_Splitter_General)self_raw, state)
}
