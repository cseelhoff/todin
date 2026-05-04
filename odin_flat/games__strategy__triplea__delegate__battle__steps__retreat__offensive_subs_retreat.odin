package game

import "core:fmt"

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

// Java: OffensiveSubsRetreat#getName
//   if (Properties.getSubmersibleSubs(battleState.getGameData().getProperties())) {
//     return battleState.getPlayer(OFFENSE).getName() + SUBS_SUBMERGE;
//   } else {
//     return battleState.getPlayer(OFFENSE).getName() + SUBS_WITHDRAW;
//   }
offensive_subs_retreat_get_name :: proc(self: ^Offensive_Subs_Retreat) -> string {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	player := battle_state_get_player(self.battle_state, .OFFENSE)
	if properties_get_submersible_subs(props) {
		return fmt.aprintf("%s%s", player.named.base.name, BATTLE_STEP_SUBS_SUBMERGE)
	}
	return fmt.aprintf("%s%s", player.named.base.name, BATTLE_STEP_SUBS_WITHDRAW)
}

// Java: OffensiveSubsRetreat#getOrder
//   if (Properties.getSubRetreatBeforeBattle(battleState.getGameData().getProperties())) {
//     return SUB_OFFENSIVE_RETREAT_BEFORE_BATTLE;
//   } else {
//     return SUB_OFFENSIVE_RETREAT_AFTER_BATTLE;
//   }
offensive_subs_retreat_get_order :: proc(self: ^Offensive_Subs_Retreat) -> Battle_Step_Order {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if properties_get_sub_retreat_before_battle(props) {
		return Battle_Step_Order.SUB_OFFENSIVE_RETREAT_BEFORE_BATTLE
	}
	return Battle_Step_Order.SUB_OFFENSIVE_RETREAT_AFTER_BATTLE
}

// Java: OffensiveSubsRetreat#isAutoWinScenario
//   return RetreatChecks.onlyDefenselessTransportsLeft(
//       battleState.filterUnits(ALIVE, DEFENSE), battleState.getGameData());
offensive_subs_retreat_is_auto_win_scenario :: proc(self: ^Offensive_Subs_Retreat) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defense_units := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	game_data := battle_state_get_game_data(self.battle_state)
	return retreat_checks_only_defenseless_transports_left(defense_units, game_data)
}

// Java: OffensiveSubsRetreat#isRetreatNotPossible
//   return !Properties.getSubmersibleSubs(battleState.getGameData().getProperties())
//       && !RetreatChecks.canAttackerRetreat(
//           battleState.filterUnits(ALIVE, DEFENSE),
//           battleState.getGameData(),
//           battleState::getAttackerRetreatTerritories,
//           battleState.getStatus().isAmphibious());
// RetreatChecks.canAttackerRetreat is inlined here because Odin has no closures
// and the existing retreat_checks_can_attacker_retreat takes a parameterless proc
// that cannot capture self.battle_state.
offensive_subs_retreat_is_retreat_not_possible :: proc(self: ^Offensive_Subs_Retreat) -> bool {
	game_data := battle_state_get_game_data(self.battle_state)
	props := game_data_get_properties(game_data)
	if properties_get_submersible_subs(props) {
		return false
	}
	is_amphibious := battle_status_is_amphibious(battle_state_get_status(self.battle_state))
	if is_amphibious {
		return true
	}
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defense_units := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	if retreat_checks_only_defenseless_transports_left(defense_units, game_data) {
		return true
	}
	territories := battle_state_get_attacker_retreat_territories(self.battle_state)
	return len(territories) == 0
}

