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
	return self
}

submerge_subs_vs_only_air_step_get_order :: proc(
	self: ^Submerge_Subs_Vs_Only_Air_Step,
) -> Battle_Step_Order {
	return Battle_Step_Order.SUBMERGE_SUBS_VS_ONLY_AIR
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

