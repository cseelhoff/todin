package game

Remove_Unprotected_Units :: struct {
	using battle_step: Battle_Step,
	battle_state:      ^Battle_State,
	battle_actions:    ^Battle_Actions,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits

remove_unprotected_units_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
) -> ^Remove_Unprotected_Units {
	self := new(Remove_Unprotected_Units)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	return self
}

remove_unprotected_units_get_order :: proc(self: ^Remove_Unprotected_Units) -> Battle_Step_Order {
	return .REMOVE_UNPROTECTED_UNITS
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#attackerHasRetreat
// Java:
//   return side == OFFENSE
//       && (!battleState.getAttackerRetreatTerritories().isEmpty()
//           || battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsAir()));
remove_unprotected_units_attacker_has_retreat :: proc(
	self: ^Remove_Unprotected_Units,
	side: Battle_State_Side,
) -> bool {
	if side != .OFFENSE {
		return false
	}
	retreats := battle_state_get_attacker_retreat_territories(self.battle_state)
	if len(retreats) > 0 {
		return true
	}
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	air_p, air_c := matches_unit_is_air()
	for u in units {
		if air_p(air_c, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#getAlliedTransports
// Java:
//   final Predicate<Unit> matchAllied =
//       Matches.unitIsSeaTransport()
//           .and(Matches.unitIsNotCombatSeaTransport())
//           .and(Matches.isUnitAllied(player))
//           .and(Matches.unitIsSea());
//   return CollectionUtils.getMatches(battleState.getBattleSite().getUnits(), matchAllied);
remove_unprotected_units_get_allied_transports :: proc(
	self: ^Remove_Unprotected_Units,
	player: ^Game_Player,
) -> [dynamic]^Unit {
	site := battle_state_get_battle_site(self.battle_state)
	site_units := unit_collection_get_units(territory_get_unit_collection(site))
	t_p, t_c := matches_unit_is_sea_transport()
	nc_p, nc_c := matches_unit_is_not_combat_sea_transport()
	a_p, a_c := matches_is_unit_allied(player)
	s_p, s_c := matches_unit_is_sea()
	result: [dynamic]^Unit
	for u in site_units {
		if t_p(t_c, u) && nc_p(nc_c, u) && a_p(a_c, u) && s_p(s_c, u) {
			append(&result, u)
		}
	}
	return result
}

