package game

Offensive_Subs_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

offensive_subs_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Offensive_Subs_Retreat {
	self := new(Offensive_Subs_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

// Java: OffensiveSubsRetreat#isDestroyerPresent
//   return battleState.filterUnits(ACTIVE, DEFENSE).stream().anyMatch(Matches.unitIsDestroyer());
// ACTIVE filter = ALIVE + CASUALTY (BattleState.UnitBattleFilter.ACTIVE).
offensive_subs_retreat_is_destroyer_present :: proc(self: ^Offensive_Subs_Retreat) -> bool {
	active_filter := battle_state_unit_battle_filter_new(.Alive, .Casualty)
	defense_units := battle_state_filter_units(self.battle_state, active_filter, .DEFENSE)
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	for u in defense_units {
		if destroyer_p(destroyer_c, u) {
			return true
		}
	}
	return false
}

// Java: OffensiveSubsRetreat#isEvaderNotPresent
//   return battleState.filterUnits(ALIVE, OFFENSE).stream().noneMatch(Matches.unitCanEvade());
offensive_subs_retreat_is_evader_not_present :: proc(self: ^Offensive_Subs_Retreat) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	offense_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	evade_p, evade_c := matches_unit_can_evade()
	for u in offense_units {
		if evade_p(evade_c, u) {
			return false
		}
	}
	return true
}

