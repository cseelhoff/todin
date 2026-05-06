package game

Submerge_Subs_Vs_Only_Air_Step :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

submerge_subs_vs_only_air_step_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Submerge_Subs_Vs_Only_Air_Step {
	self := new(Submerge_Subs_Vs_Only_Air_Step)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.battle_step.get_all_step_details = submerge_subs_vs_only_air_step_v_get_all_step_details
	self.battle_step.i_executable.execute = submerge_subs_vs_only_air_step_v_execute
	return self
}

submerge_subs_vs_only_air_step_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return submerge_subs_vs_only_air_step_get_all_step_details(cast(^Submerge_Subs_Vs_Only_Air_Step)self)
}

submerge_subs_vs_only_air_step_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	submerge_subs_vs_only_air_step_execute(cast(^Submerge_Subs_Vs_Only_Air_Step)self, stack, bridge)
}

submerge_subs_vs_only_air_step_get_order :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
) -> Battle_Step_Order {
	return Battle_Step_Order.SUBMERGE_SUBS_VS_ONLY_AIR
}

// games.strategy.triplea.delegate.battle.steps.retreat.sub.SubmergeSubsVsOnlyAirStep#getAllStepDetails
submerge_subs_vs_only_air_step_get_all_step_details :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if submerge_subs_vs_only_air_step_valid(self) {
		append(&out, battle_step_step_details_new(BATTLE_STEP_SUBMERGE_SUBS_VS_AIR_ONLY, &self.battle_step))
	}
	return out
}

// games.strategy.triplea.delegate.battle.steps.retreat.sub.SubmergeSubsVsOnlyAirStep#valid
submerge_subs_vs_only_air_step_valid :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
) -> bool {
	return submerge_subs_vs_only_air_step_side_only_has_air_that_can_not_target_subs(self, .OFFENSE) ||
		submerge_subs_vs_only_air_step_side_only_has_air_that_can_not_target_subs(self, .DEFENSE)
}

// games.strategy.triplea.delegate.battle.steps.retreat.sub.SubmergeSubsVsOnlyAirStep#sideOnlyHasAirThatCanNotTargetSubs
submerge_subs_vs_only_air_step_side_only_has_air_that_can_not_target_subs :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
	side_with_air: Battle_State_Side,
) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	with_air := battle_state_filter_units(self.battle_state, alive_filter, side_with_air)
	if len(with_air) == 0 {
		return false
	}
	air_p, air_c := matches_unit_is_air()
	for u in with_air {
		if !air_p(air_c, u) {
			return false
		}
	}

	opp := battle_state_side_get_opposite(side_with_air)
	alive_filter2 := battle_state_unit_battle_filter_new(.Alive)
	opp_units := battle_state_filter_units(self.battle_state, alive_filter2, opp)
	if len(opp_units) == 0 {
		return false
	}

	evade_p, evade_c := matches_unit_can_evade()
	cnbt_p, cnbt_c := matches_unit_can_not_be_targeted_by_all()
	for u in opp_units {
		if evade_p(evade_c, u) && cnbt_p(cnbt_c, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.retreat.sub.SubmergeSubsVsOnlyAirStep#execute
submerge_subs_vs_only_air_step_execute :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	submerging_side: Battle_State_Side
	if submerge_subs_vs_only_air_step_side_only_has_air_that_can_not_target_subs(self, .OFFENSE) {
		submerging_side = .DEFENSE
	} else if submerge_subs_vs_only_air_step_side_only_has_air_that_can_not_target_subs(self, .DEFENSE) {
		submerging_side = .OFFENSE
	} else {
		return
	}

	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	candidates := battle_state_filter_units(self.battle_state, alive_filter, submerging_side)
	evade_p, evade_c := matches_unit_can_evade()
	cnbt_p, cnbt_c := matches_unit_can_not_be_targeted_by_all()
	matched := make([dynamic]^Unit)
	for u in candidates {
		if evade_p(evade_c, u) && cnbt_p(cnbt_c, u) {
			append(&matched, u)
		}
	}

	params := evader_retreat_parameters_parameters_builder_build(
		evader_retreat_parameters_parameters_builder_units(
			evader_retreat_parameters_parameters_builder_bridge(
				evader_retreat_parameters_parameters_builder_side(
					evader_retreat_parameters_parameters_builder_battle_actions(
						evader_retreat_parameters_parameters_builder_battle_state(
							evader_retreat_parameters_builder(),
							self.battle_state,
						),
						self.battle_actions,
					),
					submerging_side,
				),
				bridge,
			),
			matched,
		),
	)
	evader_retreat_submerge_evaders(params)
}

