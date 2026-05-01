package game

Defensive_Subs_Retreat :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

defensive_subs_retreat_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Defensive_Subs_Retreat {
	self := new(Defensive_Subs_Retreat)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

// Java: DefensiveSubsRetreat#isEvaderNotPresent
//   return battleState.filterUnits(ALIVE, DEFENSE).stream().noneMatch(Matches.unitCanEvade());
defensive_subs_retreat_is_evader_not_present :: proc(self: ^Defensive_Subs_Retreat) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defense_units := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	evade_p, evade_c := matches_unit_can_evade()
	for u in defense_units {
		if evade_p(evade_c, u) {
			return false
		}
	}
	return true
}

// Java: DefensiveSubsRetreat#isDestroyerPresent
//   return battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsDestroyer())
//       || battleState.filterUnits(CASUALTY, OFFENSE).stream().anyMatch(Matches.unitIsDestroyer());
defensive_subs_retreat_is_destroyer_present :: proc(self: ^Defensive_Subs_Retreat) -> bool {
	destroyer_p, destroyer_c := matches_unit_is_destroyer()

	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	alive_offense := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	for u in alive_offense {
		if destroyer_p(destroyer_c, u) {
			return true
		}
	}

	casualty_filter := battle_state_unit_battle_filter_new(.Casualty)
	casualty_offense := battle_state_filter_units(self.battle_state, casualty_filter, .OFFENSE)
	for u in casualty_offense {
		if destroyer_p(destroyer_c, u) {
			return true
		}
	}
	return false
}

