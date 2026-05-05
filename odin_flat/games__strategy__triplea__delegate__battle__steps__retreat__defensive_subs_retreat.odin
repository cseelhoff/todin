package game

import "core:fmt"

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

// Java: DefensiveSubsRetreat#getEmptyOrFriendlySeaNeighbors
//   Collection<Territory> possible =
//       battleState.getGameData().getMap().getNeighbors(battleState.getBattleSite());
//   if (battleState.getStatus().isHeadless()) return possible;
//   Collection<Unit> unitsToRetreat = CollectionUtils.getMatches(
//       battleState.filterUnits(ALIVE, DEFENSE), Matches.unitCanEvade());
//   Predicate<Territory> canalMatch = t -> {
//       Route r = new Route(battleState.getBattleSite(), t);
//       return new MoveValidator(battleState.getGameData(), false)
//                  .validateCanal(r, unitsToRetreat, battleState.getPlayer(DEFENSE)) == null;
//   };
//   Predicate<Territory> match = Matches.territoryIsWater()
//       .and(Matches.territoryHasNoEnemyUnits(battleState.getPlayer(DEFENSE)))
//       .and(canalMatch);
//   return CollectionUtils.getMatches(possible, match);
defensive_subs_retreat_get_empty_or_friendly_sea_neighbors :: proc(
	self: ^Defensive_Subs_Retreat,
) -> [dynamic]^Territory {
	game_data := battle_state_get_game_data(self.battle_state)
	game_map := game_data_get_map(game_data)
	battle_site := battle_state_get_battle_site(self.battle_state)
	possible := game_map_get_neighbors(game_map, battle_site)

	result := make([dynamic]^Territory)

	if battle_status_is_headless(battle_state_get_status(self.battle_state)) {
		for t in possible {
			append(&result, t)
		}
		return result
	}

	defense_player := battle_state_get_player(self.battle_state, .DEFENSE)

	// unitsToRetreat = filter ALIVE/DEFENSE through Matches.unitCanEvade()
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defense_alive := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	evade_p, evade_c := matches_unit_can_evade()
	units_to_retreat := make([dynamic]^Unit)
	for u in defense_alive {
		if evade_p(evade_c, u) {
			append(&units_to_retreat, u)
		}
	}

	water_p, water_c := matches_territory_is_water()
	noenemy_p, noenemy_c := matches_territory_has_no_enemy_units(defense_player)

	for t in possible {
		if !water_p(water_c, t) {
			continue
		}
		if !noenemy_p(noenemy_c, t) {
			continue
		}
		// canalMatch: new MoveValidator(data,false).validateCanal(new Route(site,t), unitsToRetreat, defensePlayer) == null
		r := route_new_from_start_and_steps(battle_site, t)
		validator := move_validator_new(game_data, false)
		if move_validator_validate_canal(validator, r, units_to_retreat, false, defense_player) != nil {
			continue
		}
		append(&result, t)
	}
	return result
}

// Java: DefensiveSubsRetreat#getName
//   if (Properties.getSubmersibleSubs(battleState.getGameData().getProperties()))
//       return battleState.getPlayer(DEFENSE).getName() + SUBS_SUBMERGE;
//   else
//       return battleState.getPlayer(DEFENSE).getName() + SUBS_WITHDRAW;
defensive_subs_retreat_get_name :: proc(self: ^Defensive_Subs_Retreat) -> string {
	game_data := battle_state_get_game_data(self.battle_state)
	props := game_data_get_properties(game_data)
	player := battle_state_get_player(self.battle_state, .DEFENSE)
	if properties_get_submersible_subs(props) {
		return fmt.aprintf("%s%s", player.named.base.name, BATTLE_STEP_SUBS_SUBMERGE)
	}
	return fmt.aprintf("%s%s", player.named.base.name, BATTLE_STEP_SUBS_WITHDRAW)
}

// Java: DefensiveSubsRetreat#getOrder
//   if (Properties.getSubRetreatBeforeBattle(battleState.getGameData().getProperties()))
//       return SUB_DEFENSIVE_RETREAT_BEFORE_BATTLE;
//   else
//       return SUB_DEFENSIVE_RETREAT_AFTER_BATTLE;
defensive_subs_retreat_get_order :: proc(self: ^Defensive_Subs_Retreat) -> Battle_Step_Order {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if properties_get_sub_retreat_before_battle(props) {
		return Battle_Step_Order.SUB_DEFENSIVE_RETREAT_BEFORE_BATTLE
	}
	return Battle_Step_Order.SUB_DEFENSIVE_RETREAT_AFTER_BATTLE
}

// Java: DefensiveSubsRetreat#isRetreatNotPossible
//   return !(Properties.getSubmersibleSubs(...) || Properties.getSubmarinesDefendingMaySubmergeOrRetreat(...))
//          && getEmptyOrFriendlySeaNeighbors().isEmpty();
defensive_subs_retreat_is_retreat_not_possible :: proc(self: ^Defensive_Subs_Retreat) -> bool {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if properties_get_submersible_subs(props) || properties_get_submarines_defending_may_submerge_or_retreat(props) {
		return false
	}
	neighbors := defensive_subs_retreat_get_empty_or_friendly_sea_neighbors(self)
	return len(neighbors) == 0
}

// Java: DefensiveSubsRetreat#getAllStepDetails
//   if (isEvaderNotPresent() || isRetreatNotPossible()) return List.of();
//   return List.of(new StepDetails(getName(), this));
defensive_subs_retreat_get_all_step_details :: proc(self: ^Defensive_Subs_Retreat) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	if defensive_subs_retreat_is_evader_not_present(self) ||
	   defensive_subs_retreat_is_retreat_not_possible(self) {
		return out
	}
	append(&out, battle_step_step_details_new(defensive_subs_retreat_get_name(self), &self.battle_step))
	return out
}

// Java: DefensiveSubsRetreat#execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (battleState.getStatus().isOver()
//       || isDestroyerPresent()
//       || isEvaderNotPresent()
//       || isRetreatNotPossible()) return;
//   Collection<Unit> unitsToRetreat = CollectionUtils.getMatches(
//       battleState.filterUnits(ALIVE, DEFENSE), Matches.unitCanEvade());
//   if (unitsToRetreat.isEmpty()) return;
//   Collection<Territory> retreatTerritories;
//   if (Properties.getSubmersibleSubs(...)) retreatTerritories = List.of(battleState.getBattleSite());
//   else { retreatTerritories = new ArrayList<>(getEmptyOrFriendlySeaNeighbors());
//          if (Properties.getSubmarinesDefendingMaySubmergeOrRetreat(...))
//            retreatTerritories.add(battleState.getBattleSite()); }
//   EvaderRetreat.retreatUnits(EvaderRetreat.Parameters.builder()...build(), retreatTerritories, getName());
defensive_subs_retreat_execute :: proc(self: ^Defensive_Subs_Retreat, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	if battle_status_is_over(battle_state_get_status(self.battle_state)) ||
	   defensive_subs_retreat_is_destroyer_present(self) ||
	   defensive_subs_retreat_is_evader_not_present(self) ||
	   defensive_subs_retreat_is_retreat_not_possible(self) {
		return
	}

	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defense_alive := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
	evade_p, evade_c := matches_unit_can_evade()
	units_to_retreat := make([dynamic]^Unit)
	for u in defense_alive {
		if evade_p(evade_c, u) {
			append(&units_to_retreat, u)
		}
	}
	if len(units_to_retreat) == 0 {
		return
	}

	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	retreat_territories := make([dynamic]^Territory)
	if properties_get_submersible_subs(props) {
		append(&retreat_territories, battle_state_get_battle_site(self.battle_state))
	} else {
		neighbors := defensive_subs_retreat_get_empty_or_friendly_sea_neighbors(self)
		for t in neighbors {
			append(&retreat_territories, t)
		}
		if properties_get_submarines_defending_may_submerge_or_retreat(props) {
			append(&retreat_territories, battle_state_get_battle_site(self.battle_state))
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
					.DEFENSE,
				),
				bridge,
			),
			units_to_retreat,
		),
	)
	evader_retreat_retreat_units(params, retreat_territories, defensive_subs_retreat_get_name(self))
}

// Java: DefensiveSubsRetreat#lambda$getEmptyOrFriendlySeaNeighbors$0(Collection unitsToRetreat, Territory t)
//   Route r = new Route(battleState.getBattleSite(), t);
//   return new MoveValidator(battleState.getGameData(), false)
//              .validateCanal(r, unitsToRetreat, battleState.getPlayer(DEFENSE)) == null;
defensive_subs_retreat_lambda_get_empty_or_friendly_sea_neighbors_0 :: proc(
	self: ^Defensive_Subs_Retreat,
	units_to_retreat: [dynamic]^Unit,
	t: ^Territory,
) -> bool {
	game_data := battle_state_get_game_data(self.battle_state)
	battle_site := battle_state_get_battle_site(self.battle_state)
	defense_player := battle_state_get_player(self.battle_state, .DEFENSE)
	r := route_new_from_start_and_steps(battle_site, t)
	validator := move_validator_new(game_data, false)
	return move_validator_validate_canal(validator, r, units_to_retreat, false, defense_player) == nil
}

