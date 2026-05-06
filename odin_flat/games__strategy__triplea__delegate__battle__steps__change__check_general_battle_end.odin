package game

Check_General_Battle_End :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd

check_general_battle_end_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return check_general_battle_end_get_all_step_details(cast(^Check_General_Battle_End)self)
}

check_general_battle_end_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	check_general_battle_end_execute(cast(^Check_General_Battle_End)self, stack, bridge)
}

check_general_battle_end_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Check_General_Battle_End {
	self := new(Check_General_Battle_End)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.get_all_step_details = check_general_battle_end_v_get_all_step_details
	self.execute = check_general_battle_end_v_execute
	return self
}

check_general_battle_end_get_all_step_details :: proc(
	self: ^Check_General_Battle_End,
) -> [dynamic]^Battle_Step_Step_Details {
	return make([dynamic]^Battle_Step_Step_Details)
}

check_general_battle_end_get_battle_actions :: proc(
	self: ^Check_General_Battle_End,
) -> ^Battle_Actions {
	return self.battle_actions
}

check_general_battle_end_get_battle_state :: proc(
	self: ^Check_General_Battle_End,
) -> ^Battle_State {
	return self.battle_state
}

check_general_battle_end_get_order :: proc(
	self: ^Check_General_Battle_End,
) -> Battle_Step_Order {
	return .GENERAL_BATTLE_END_CHECK
}

check_general_battle_end_has_no_targets :: proc(
	self: ^Check_General_Battle_End,
	firing_groups: [dynamic]^Firing_Group,
) -> bool {
	return len(firing_groups) == 0
}

// Mirrors Java `Predicate<Unit> inAnyFiringGroup(Iterable<FiringGroup>)`.
// The returned rawptr is a heap-allocated capture of `firing_groups`
// to be passed alongside `check_general_battle_end_lambda_in_any_firing_group_1`.
check_general_battle_end_in_any_firing_group :: proc(
	self: ^Check_General_Battle_End,
	firing_groups: [dynamic]^Firing_Group,
) -> rawptr {
	captured := new([dynamic]^Firing_Group)
	captured^ = firing_groups
	return rawptr(captured)
}

check_general_battle_end_lambda_can_attacker_retreat_in_stalemate_2 :: proc(b: bool) -> bool {
	return b
}

check_general_battle_end_lambda_in_any_firing_group_1 :: proc(
	firing_groups: [dynamic]^Firing_Group,
	u: ^Unit,
) -> bool {
	for fg in firing_groups {
		for unit in fg.firing_units {
			if unit == u {
				return true
			}
		}
	}
	return false
}

// Mirrors javac-synthetic `lambda$inAnyFiringGroup$0`: the outer
// `Predicate<Unit>` body `u -> stream(firingGroups).anyMatch(fg -> fg.getFiringUnits().contains(u))`.
// The captured `firingGroups` arrives as a `rawptr` to a heap-allocated
// `[dynamic]^Firing_Group` (see `check_general_battle_end_in_any_firing_group`).
check_general_battle_end_lambda__in_any_firing_group__0 :: proc(
	ctx: rawptr,
	u: ^Unit,
) -> bool {
	firing_groups := (^[dynamic]^Firing_Group)(ctx)^
	for fg in firing_groups {
		for unit in fg.firing_units {
			if unit == u {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#hasSideLost
check_general_battle_end_has_side_lost :: proc(
	self: ^Check_General_Battle_End,
	side: Battle_State_Side,
) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, side)
	pred, ctx := matches_unit_is_not_infrastructure()
	for u in units {
		if pred(ctx, u) {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#transportsVsTransports
check_general_battle_end_transports_vs_transports :: proc(
	self: ^Check_General_Battle_End,
) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	offense_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	defense_units := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	game_data := battle_state_get_game_data(self.battle_state)
	return(
		retreat_checks_only_defenseless_transports_left(offense_units, game_data) &&
		retreat_checks_only_defenseless_transports_left(defense_units, game_data) \
	)
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#canAttackerRetreatInStalemate
check_general_battle_end_can_attacker_retreat_in_stalemate :: proc(
	self: ^Check_General_Battle_End,
) -> bool {
	// Collect all of the non-null 'can retreat on stalemate' option values.
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	offense_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	can_retreat_options := make(map[bool]struct {})
	defer delete(can_retreat_options)
	for u in offense_units {
		ua := unit_get_unit_attachment(u)
		opt := unit_attachment_get_can_retreat_on_stalemate(ua)
		if opt == nil {
			continue
		}
		can_retreat_options[opt^] = struct {}{}
	}

	property_is_set_at_least_once := len(can_retreat_options) > 0

	// Check if all of the non-null properties are set to true.
	allow_retreat_from_property := true
	for b in can_retreat_options {
		if !check_general_battle_end_lambda_can_attacker_retreat_in_stalemate_2(b) {
			allow_retreat_from_property = false
			break
		}
	}

	return(
		(property_is_set_at_least_once && allow_retreat_from_property) ||
		(!property_is_set_at_least_once &&
				check_general_battle_end_transports_vs_transports(self)) \
	)
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#getFiringGroup
check_general_battle_end_get_firing_group :: proc(
	self: ^Check_General_Battle_End,
	side: Battle_State_Side,
	type: Firing_Group_Splitter_General_Type,
) -> [dynamic]^Firing_Group {
	splitter := firing_group_splitter_general_new(side, type, "stalemate")
	return firing_group_splitter_general_apply(splitter, self.battle_state)
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#getAllFiringGroups
// Java: Iterables.concat(getFiringGroup(side, NORMAL), getFiringGroup(side, FIRST_STRIKE)).
// Odin: materialize the concatenation as a single [dynamic]^Firing_Group;
// the only callers iterate it once or pass it to inAnyFiringGroup / hasNoTargets.
check_general_battle_end_get_all_firing_groups :: proc(
	self: ^Check_General_Battle_End,
	side: Battle_State_Side,
) -> [dynamic]^Firing_Group {
	normal := check_general_battle_end_get_firing_group(self, side, .NORMAL)
	first_strike := check_general_battle_end_get_firing_group(self, side, .FIRST_STRIKE)
	result := make([dynamic]^Firing_Group, 0, len(normal) + len(first_strike))
	for fg in normal {
		append(&result, fg)
	}
	for fg in first_strike {
		append(&result, fg)
	}
	return result
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#hasNoStrengthOrRolls
// Java: !PowerStrengthAndRolls.buildWithPreSortedUnits(
//           myUnits,
//           CombatValueBuilder.mainCombatValue()
//               .enemyUnits(enemyUnits).friendlyUnits(myUnits).side(side)
//               .gameSequence(battleState.getGameData().getSequence())
//               .supportAttachments(battleState.getGameData().getUnitTypeList().getSupportRules())
//               .lhtrHeavyBombers(Properties.getLhtrHeavyBombers(battleState.getGameData().getProperties()))
//               .gameDiceSides(battleState.getGameData().getDiceSides())
//               .territoryEffects(battleState.getTerritoryEffects())
//               .build())
//       .hasStrengthOrRolls();
check_general_battle_end_has_no_strength_or_rolls :: proc(
	self: ^Check_General_Battle_End,
	side: Battle_State_Side,
	my_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
) -> bool {
	game_data := battle_state_get_game_data(self.battle_state)
	support_map := unit_type_list_get_support_rules(game_data_get_unit_type_list(game_data))
	support_list: [dynamic]^Unit_Support_Attachment
	defer delete(support_list)
	for k, _ in support_map {
		append(&support_list, k)
	}
	cv := combat_value_builder_build_main_combat_value(
		enemy_units,
		my_units,
		side,
		game_data_get_sequence(game_data),
		support_list,
		properties_get_lhtr_heavy_bombers(game_data_get_properties(game_data)),
		int(game_data_get_dice_sides(game_data)),
		battle_state_get_territory_effects(self.battle_state),
	)
	psar := power_strength_and_rolls_build_with_pre_sorted_units(my_units, cv)
	return !power_strength_and_rolls_has_strength_or_rolls(psar)
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#isStalemate
check_general_battle_end_is_stalemate :: proc(
	self: ^Check_General_Battle_End,
) -> bool {
	if battle_status_is_last_round(battle_state_get_status(self.battle_state)) {
		return true
	}

	alive_filter := battle_state_unit_battle_filter_new(.Alive)

	attacker_firing_groups := check_general_battle_end_get_all_firing_groups(self, .OFFENSE)
	alive_offense := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	attacker_ctx := check_general_battle_end_in_any_firing_group(self, attacker_firing_groups)
	attackers := make([dynamic]^Unit, 0, len(alive_offense))
	for u in alive_offense {
		if check_general_battle_end_lambda__in_any_firing_group__0(attacker_ctx, u) {
			append(&attackers, u)
		}
	}

	defender_firing_groups := check_general_battle_end_get_all_firing_groups(self, .DEFENSE)
	alive_defense := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	defender_ctx := check_general_battle_end_in_any_firing_group(self, defender_firing_groups)
	defenders := make([dynamic]^Unit, 0, len(alive_defense))
	for u in alive_defense {
		if check_general_battle_end_lambda__in_any_firing_group__0(defender_ctx, u) {
			append(&defenders, u)
		}
	}

	return(
		battle_status_is_last_round(battle_state_get_status(self.battle_state)) ||
		(check_general_battle_end_has_no_strength_or_rolls(self, .OFFENSE, attackers, defenders) &&
				check_general_battle_end_has_no_strength_or_rolls(self, .DEFENSE, defenders, attackers)) ||
		(check_general_battle_end_has_no_targets(self, attacker_firing_groups) &&
				check_general_battle_end_has_no_targets(self, defender_firing_groups)) \
	)
}

// games.strategy.triplea.delegate.battle.steps.change.CheckGeneralBattleEnd#execute
check_general_battle_end_execute :: proc(
	self: ^Check_General_Battle_End,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if check_general_battle_end_has_side_lost(self, .OFFENSE) {
		battle_actions_end_battle(self.battle_actions, .DEFENDER, bridge)
	} else if check_general_battle_end_has_side_lost(self, .DEFENSE) {
		battle_actions_end_battle(self.battle_actions, .ATTACKER, bridge)
	} else if check_general_battle_end_is_stalemate(self) &&
	   !check_general_battle_end_can_attacker_retreat_in_stalemate(self) {
		battle_actions_end_battle(self.battle_actions, .DRAW, bridge)
	}
}

