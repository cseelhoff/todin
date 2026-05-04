package game



Pro_Odds_Calculator :: struct {
	calc:    ^I_Battle_Calculator,
	stopped: bool,
}

pro_odds_calculator_new :: proc(calculator: ^I_Battle_Calculator) -> ^Pro_Odds_Calculator {
	self := new(Pro_Odds_Calculator)
	self.calc = calculator
	self.stopped = false
	return self
}

// Java: ProOddsCalculator#canSubmergeBeforeBattle (private static)
//   return checkSubmerge
//       && Properties.getSubRetreatBeforeBattle(data.getProperties())
//       && defendingUnits.stream().allMatch(Matches.unitCanEvade())
//       && attackingUnits.stream().noneMatch(Matches.unitIsDestroyer());
pro_odds_calculator_can_submerge_before_battle :: proc(
	data: ^Game_State,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	check_submerge: bool,
) -> bool {
	if !check_submerge {
		return false
	}
	if !properties_get_sub_retreat_before_battle(game_state_get_properties(data)) {
		return false
	}
	evade_p, evade_c := matches_unit_can_evade()
	for u in defending_units {
		if !evade_p(evade_c, u) {
			return false
		}
	}
	destroyer_p, destroyer_c := matches_unit_is_destroyer()
	for u in attacking_units {
		if destroyer_p(destroyer_c, u) {
			return false
		}
	}
	return true
}

