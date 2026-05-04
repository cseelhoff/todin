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

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#getAlliedUnits
// Java:
//   final Predicate<Unit> alliedUnitsMatch =
//       Matches.isUnitAllied(player)
//           .and(Matches.unitIsNotLand())
//           .and(Matches.unitIsSubmerged().negate());
//   return CollectionUtils.getMatches(battleState.getBattleSite().getUnits(), alliedUnitsMatch);
remove_unprotected_units_get_allied_units :: proc(
	self: ^Remove_Unprotected_Units,
	player: ^Game_Player,
) -> [dynamic]^Unit {
	site := battle_state_get_battle_site(self.battle_state)
	site_units := unit_collection_get_units(territory_get_unit_collection(site))
	a_p, a_c := matches_is_unit_allied(player)
	nl_p, nl_c := matches_unit_is_not_land()
	sub_p, sub_c := matches_unit_is_submerged()
	result: [dynamic]^Unit
	for u in site_units {
		if a_p(a_c, u) && nl_p(nl_c, u) && !sub_p(sub_c, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#getEnemyUnitsThatCanFire
// Java:
//   final Predicate<Unit> enemyUnitsMatch =
//       Matches.unitIsNotLand()
//           .and(Matches.enemyUnit(player))
//           .and(Matches.unitIsSubmerged().negate())
//           .and(Matches.unitCanAttack(player));
//   return CollectionUtils.getMatches(battleState.getBattleSite().getUnits(), enemyUnitsMatch);
remove_unprotected_units_get_enemy_units_that_can_fire :: proc(
	self: ^Remove_Unprotected_Units,
	player: ^Game_Player,
) -> [dynamic]^Unit {
	site := battle_state_get_battle_site(self.battle_state)
	site_units := unit_collection_get_units(territory_get_unit_collection(site))
	nl_p, nl_c := matches_unit_is_not_land()
	en_p, en_c := matches_enemy_unit(player)
	sub_p, sub_c := matches_unit_is_submerged()
	atk_p, atk_c := matches_unit_can_attack(player)
	result: [dynamic]^Unit
	for u in site_units {
		if nl_p(nl_c, u) && en_p(en_c, u) && !sub_p(sub_c, u) && atk_p(atk_c, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#getUnprotectedUnits
// Java:
//   return CollectionUtils.getMatches(
//       battleState.filterUnits(ALIVE, side),
//       Matches.unitIsActiveInTerritory(battleState.getBattleSite())
//           .and(Matches.unitIsNotInfrastructure()));
remove_unprotected_units_get_unprotected_units :: proc(
	self: ^Remove_Unprotected_Units,
	side: Battle_State_Side,
) -> [dynamic]^Unit {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, side)
	act_p, act_c := matches_unit_is_active_in_territory(
		battle_state_get_battle_site(self.battle_state),
	)
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	result: [dynamic]^Unit
	for u in units {
		if act_p(act_c, u) && ni_p(ni_c, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#unitIsActiveAndCanFight
// Java:
//   return Matches.unitIsActiveInTerritory(battleState.getBattleSite())
//       .and(Matches.unitIsSupporterOrHasCombatAbility(side == OFFENSE));
Remove_Unprotected_Units_Ctx_unit_is_active_and_can_fight :: struct {
	active_p: proc(rawptr, ^Unit) -> bool,
	active_c: rawptr,
	combat_p: proc(rawptr, ^Unit) -> bool,
	combat_c: rawptr,
}

remove_unprotected_units_pred_unit_is_active_and_can_fight :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	c := cast(^Remove_Unprotected_Units_Ctx_unit_is_active_and_can_fight)ctx_ptr
	return c.active_p(c.active_c, u) && c.combat_p(c.combat_c, u)
}

remove_unprotected_units_unit_is_active_and_can_fight :: proc(
	self: ^Remove_Unprotected_Units,
	side: Battle_State_Side,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Remove_Unprotected_Units_Ctx_unit_is_active_and_can_fight)
	ctx.active_p, ctx.active_c = matches_unit_is_active_in_territory(
		battle_state_get_battle_site(self.battle_state),
	)
	ctx.combat_p, ctx.combat_c = matches_unit_is_supporter_or_has_combat_ability(side == .OFFENSE)
	return remove_unprotected_units_pred_unit_is_active_and_can_fight, rawptr(ctx)
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#areFightingOrSupportingUnitsLeft
// Java:
//   return battleState.filterUnits(ALIVE, side).stream().anyMatch(unitIsActiveAndCanFight(side));
remove_unprotected_units_are_fighting_or_supporting_units_left :: proc(
	self: ^Remove_Unprotected_Units,
	side: Battle_State_Side,
) -> bool {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	units := battle_state_filter_units(self.battle_state, alive_filter, side)
	pred, ctx := remove_unprotected_units_unit_is_active_and_can_fight(self, side)
	for u in units {
		if pred(ctx, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#getAllStepDetails
// Java:
//   if (battleState.getBattleSite().isWater()
//       && Properties.getTransportCasualtiesRestricted(battleState.getGameData().getProperties())
//       && (battleState.filterUnits(ALIVE, OFFENSE).stream().anyMatch(Matches.unitIsSeaTransport())
//           || battleState.filterUnits(ALIVE, DEFENSE).stream()
//               .anyMatch(Matches.unitIsSeaTransport()))) {
//     return List.of(new StepDetails(REMOVE_UNESCORTED_TRANSPORTS, this));
//   }
//   return List.of();
remove_unprotected_units_get_all_step_details :: proc(
	self: ^Remove_Unprotected_Units,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	site := battle_state_get_battle_site(self.battle_state)
	if !territory_is_water(site) {
		return out
	}
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if !properties_get_transport_casualties_restricted(props) {
		return out
	}
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	t_p, t_c := matches_unit_is_sea_transport()
	has_transport := false
	off_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	for u in off_units {
		if t_p(t_c, u) {
			has_transport = true
			break
		}
	}
	if !has_transport {
		def_units := battle_state_filter_units(self.battle_state, alive_filter, .DEFENSE)
		for u in def_units {
			if t_p(t_c, u) {
				has_transport = true
				break
			}
		}
	}
	if !has_transport {
		return out
	}
	append(&out, battle_step_step_details_new(BATTLE_STEP_REMOVE_UNESCORTED_TRANSPORTS, &self.battle_step))
	return out
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#checkUnprotectedUnits
// Java:
//   if (battleState.filterUnits(ALIVE, OFFENSE, DEFENSE).isEmpty()) return;
//   if (areFightingOrSupportingUnitsLeft(side)) return;
//   if (!areFightingOrSupportingUnitsLeft(side.getOpposite())) return;
//   final Collection<Unit> unprotectedUnits = getUnprotectedUnits(side);
//   battleActions.removeUnits(unprotectedUnits, bridge, battleState.getBattleSite(), side);
remove_unprotected_units_check_unprotected_units :: proc(
	self: ^Remove_Unprotected_Units,
	bridge: ^I_Delegate_Bridge,
	side: Battle_State_Side,
) {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	all_units := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE, .DEFENSE)
	if len(all_units) == 0 {
		return
	}
	if remove_unprotected_units_are_fighting_or_supporting_units_left(self, side) {
		return
	}
	if !remove_unprotected_units_are_fighting_or_supporting_units_left(
		self,
		battle_state_side_get_opposite(side),
	) {
		return
	}
	unprotected := remove_unprotected_units_get_unprotected_units(self, side)
	battle_actions_remove_units(
		self.battle_actions,
		unprotected,
		bridge,
		battle_state_get_battle_site(self.battle_state),
		side,
	)
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#checkUndefendedTransports
// Java:
//   final GamePlayer player = battleState.getPlayer(side);
//   final List<Unit> alliedTransports = getAlliedTransports(player);
//   if (alliedTransports.isEmpty()) return;
//   final Collection<Unit> alliedUnits = getAlliedUnits(player);
//   if (alliedTransports.size() != alliedUnits.size()) return;
//   final Collection<Unit> enemyUnits = getEnemyUnitsThatCanFire(player);
//   if (enemyUnits.isEmpty()) return;
//   final Change change =
//       ChangeFactory.markNoMovementChange(
//           CollectionUtils.getMatches(enemyUnits, Matches.unitIsSea()));
//   bridge.addChange(change);
//   battleActions.removeUnits(alliedUnits, bridge, battleState.getBattleSite(), side);
remove_unprotected_units_check_undefended_transports :: proc(
	self: ^Remove_Unprotected_Units,
	bridge: ^I_Delegate_Bridge,
	side: Battle_State_Side,
) {
	player := battle_state_get_player(self.battle_state, side)
	allied_transports := remove_unprotected_units_get_allied_transports(self, player)
	if len(allied_transports) == 0 {
		return
	}
	allied_units := remove_unprotected_units_get_allied_units(self, player)
	if len(allied_transports) != len(allied_units) {
		return
	}
	enemy_units := remove_unprotected_units_get_enemy_units_that_can_fire(self, player)
	if len(enemy_units) == 0 {
		return
	}
	sea_p, sea_c := matches_unit_is_sea()
	sea_enemies: [dynamic]^Unit
	for u in enemy_units {
		if sea_p(sea_c, u) {
			append(&sea_enemies, u)
		}
	}
	change := change_factory_mark_no_movement_change_collection(sea_enemies)
	i_delegate_bridge_add_change(bridge, change)
	battle_actions_remove_units(
		self.battle_actions,
		allied_units,
		bridge,
		battle_state_get_battle_site(self.battle_state),
		side,
	)
}


// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#removeUnprotectedUnits
// Java:
//   if (!Properties.getTransportCasualtiesRestricted(battleState.getGameData().getProperties())) return;
//   if (attackerHasRetreat(side)) return;
//   checkUndefendedTransports(bridge, side);
//   checkUnprotectedUnits(bridge, side);
remove_unprotected_units_remove_unprotected_units :: proc(
	self: ^Remove_Unprotected_Units,
	bridge: ^I_Delegate_Bridge,
	side: Battle_State_Side,
) {
	props := game_data_get_properties(battle_state_get_game_data(self.battle_state))
	if !properties_get_transport_casualties_restricted(props) {
		return
	}
	if remove_unprotected_units_attacker_has_retreat(self, side) {
		return
	}
	remove_unprotected_units_check_undefended_transports(self, bridge, side)
	remove_unprotected_units_check_unprotected_units(self, bridge, side)
}

// games.strategy.triplea.delegate.battle.steps.change.RemoveUnprotectedUnits#execute
// Java:
//   removeUnprotectedUnits(bridge, DEFENSE);
//   removeUnprotectedUnits(bridge, OFFENSE);
remove_unprotected_units_execute :: proc(
	self: ^Remove_Unprotected_Units,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	remove_unprotected_units_remove_unprotected_units(self, bridge, .DEFENSE)
	remove_unprotected_units_remove_unprotected_units(self, bridge, .OFFENSE)
}
