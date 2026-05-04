package game

import "core:fmt"

Retreater_General :: struct {
	using retreater: Retreater,
	battle_state: ^Battle_State,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral

retreater_general_new :: proc(battle_state: ^Battle_State) -> ^Retreater_General {
	self := new(Retreater_General)
	self.battle_state = battle_state
	return self
}

retreater_general_get_retreat_type :: proc(self: ^Retreater_General) -> Must_Fight_Battle_Retreat_Type {
	return .DEFAULT
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#getRetreatUnits()
// Java:
//   final Collection<Unit> retreatUnits = new HashSet<>(battleState.filterUnits(ALIVE, OFFENSE));
//   retreatUnits.addAll(
//       battleState.getBattleSite().getUnitCollection().getMatches(
//           Matches.unitIsOwnedBy(battleState.getPlayer(OFFENSE))
//               .and(Matches.unitIsSubmerged().negate())));
//   retreatUnits.removeAll(battleState.filterUnits(REMOVED_CASUALTY));
//   return retreatUnits;
retreater_general_get_retreat_units :: proc(self: ^Retreater_General) -> [dynamic]^Unit {
	seen := make(map[^Unit]bool)
	defer delete(seen)
	result: [dynamic]^Unit

	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	alive_offense := battle_state_filter_units(self.battle_state, alive_filter, .OFFENSE)
	for u in alive_offense {
		if !(u in seen) {
			seen[u] = true
			append(&result, u)
		}
	}

	battle_site := battle_state_get_battle_site(self.battle_state)
	offense_player := battle_state_get_player(self.battle_state, .OFFENSE)
	uc := territory_get_unit_collection(battle_site)

	owned_p, owned_c := matches_unit_is_owned_by(offense_player)
	sub_p, sub_c := matches_unit_is_submerged()
	for u in uc.units {
		if owned_p(owned_c, u) && !sub_p(sub_c, u) {
			if !(u in seen) {
				seen[u] = true
				append(&result, u)
			}
		}
	}

	casualty_filter := battle_state_unit_battle_filter_new(.Removed_Casualty)
	casualty_units := battle_state_filter_units(self.battle_state, casualty_filter, .OFFENSE)
	casualty_set := make(map[^Unit]bool)
	defer delete(casualty_set)
	for u in casualty_units {
		casualty_set[u] = true
	}

	filtered: [dynamic]^Unit
	for u in result {
		if !(u in casualty_set) {
			append(&filtered, u)
		}
	}
	delete(result)
	return filtered
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#getPossibleRetreatSites(java.util.Collection)
// Java:
//   final Collection<Territory> allRetreatTerritories = battleState.getAttackerRetreatTerritories();
//   return retreatUnits.stream().anyMatch(Matches.unitIsSea())
//       ? CollectionUtils.getMatches(allRetreatTerritories, Matches.territoryIsWater())
//       : new ArrayList<>(allRetreatTerritories);
retreater_general_get_possible_retreat_sites :: proc(
	self: ^Retreater_General,
	retreat_units: [dynamic]^Unit,
) -> [dynamic]^Territory {
	all_retreat_territories := battle_state_get_attacker_retreat_territories(self.battle_state)

	sea_pred, sea_ctx := matches_unit_is_sea()
	any_sea := false
	for u in retreat_units {
		if sea_pred(sea_ctx, u) {
			any_sea = true
			break
		}
	}

	result: [dynamic]^Territory
	if any_sea {
		water_pred, water_ctx := matches_territory_is_water()
		for t in all_retreat_territories {
			if water_pred(water_ctx, t) {
				append(&result, t)
			}
		}
	} else {
		for t in all_retreat_territories {
			append(&result, t)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#retreatNonCombatTransportedItems(java.util.Collection,games.strategy.engine.data.Territory)
// Java:
//   final CompositeChange change = new CompositeChange();
//   final Collection<Unit> transports =
//       CollectionUtils.getMatches(units, Matches.unitIsSeaTransport());
//   for (final Unit transport : transports) {
//     final Collection<Unit> retreated =
//         battleState.getTransportDependents(List.of(transport));
//     if (!retreated.isEmpty()) {
//       final Territory retreatedFrom =
//           TransportTracker.getTerritoryTransportHasUnloadedTo(transport);
//       if (retreatedFrom != null) {
//         TransportTracker.reloadTransports(transports, change);
//         change.add(ChangeFactory.moveUnits(retreatedFrom, retreatTo, retreated));
//       }
//     }
//   }
//   return change;
retreater_general_retreat_non_combat_transported_items :: proc(
	self: ^Retreater_General,
	units: [dynamic]^Unit,
	retreat_to: ^Territory,
) -> ^Change {
	change := composite_change_new()

	transport_p, transport_c := matches_unit_is_sea_transport()
	transports: [dynamic]^Unit
	for u in units {
		if transport_p(transport_c, u) {
			append(&transports, u)
		}
	}

	for transport in transports {
		one := make([dynamic]^Unit)
		append(&one, transport)
		retreated := battle_state_get_transport_dependents(self.battle_state, one)
		delete(one)
		if len(retreated) != 0 {
			retreated_from := transport_tracker_get_territory_transport_has_unloaded_to(transport)
			if retreated_from != nil {
				transport_tracker_reload_transports(transports, change)
				composite_change_add(
					change,
					change_factory_move_units(retreated_from, retreat_to, retreated),
				)
			}
		}
	}

	delete(transports)
	return &change.change
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#retreatCombatTransportedItems(java.util.Collection,games.strategy.engine.data.Territory,java.util.Collection)
// Java:
//   final CompositeChange change = new CompositeChange();
//   for (final IBattle dependent : dependentBattles) {
//     final Route route = new Route(battleState.getBattleSite(), dependent.getTerritory());
//     final Collection<Unit> retreatedUnits = dependent.getDependentUnits(units);
//     change.add(dependent.removeAttack(route, retreatedUnits));
//     TransportTracker.reloadTransports(units, change);
//     change.add(ChangeFactory.moveUnits(dependent.getTerritory(), retreatTo, retreatedUnits));
//   }
//   return change;
retreater_general_retreat_combat_transported_items :: proc(
	self: ^Retreater_General,
	units: [dynamic]^Unit,
	retreat_to: ^Territory,
	dependent_battles: [dynamic]^I_Battle,
) -> ^Change {
	change := composite_change_new()

	battle_site := battle_state_get_battle_site(self.battle_state)
	for dependent in dependent_battles {
		dependent_territory := i_battle_get_territory(dependent)
		route := route_new_from_start_and_steps(battle_site, dependent_territory)
		retreated_units := i_battle_get_dependent_units(dependent, units)
		composite_change_add(change, i_battle_remove_attack(dependent, route, retreated_units))
		transport_tracker_reload_transports(units, change)
		composite_change_add(
			change,
			change_factory_move_units(dependent_territory, retreat_to, retreated_units),
		)
	}

	return &change.change
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#computeDependentUnitChanges(games.strategy.engine.data.Territory,java.util.Collection)
// Java:
//   final Collection<IBattle> dependentBattles = battleState.getDependentBattles();
//   if (dependentBattles.isEmpty()) {
//     return retreatNonCombatTransportedItems(retreatUnits, retreatTo);
//   } else {
//     return retreatCombatTransportedItems(retreatUnits, retreatTo, dependentBattles);
//   }
retreater_general_compute_dependent_unit_changes :: proc(
	self: ^Retreater_General,
	retreat_to: ^Territory,
	retreat_units: [dynamic]^Unit,
) -> ^Change {
	dependent_battles := battle_state_get_dependent_battles(self.battle_state)
	if len(dependent_battles) == 0 {
		delete(dependent_battles)
		return retreater_general_retreat_non_combat_transported_items(self, retreat_units, retreat_to)
	}
	list: [dynamic]^I_Battle
	for b, _ in dependent_battles {
		append(&list, b)
	}
	delete(dependent_battles)
	result := retreater_general_retreat_combat_transported_items(self, retreat_units, retreat_to, list)
	delete(list)
	return result
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#computeChanges(games.strategy.engine.data.Territory)
// Java:
//   final Collection<Unit> retreatUnits = getRetreatUnits();
//   final CompositeChange change = new CompositeChange();
//   final List<RetreatHistoryChild> historyChildren = new ArrayList<>();
//   change.add(computeDependentUnitChanges(retreatTo, retreatUnits));
//   final Collection<Unit> airRetreating = CollectionUtils.getMatches(retreatUnits,
//       Matches.unitIsAir().and(Matches.unitIsOwnedBy(battleState.getPlayer(OFFENSE))));
//   if (!airRetreating.isEmpty()) {
//     battleState.retreatUnits(OFFENSE, airRetreating);
//     final String transcriptText = MyFormatter.unitsToText(airRetreating) + " retreated";
//     historyChildren.add(RetreatHistoryChild.of(transcriptText, new ArrayList<>(airRetreating)));
//   }
//   final Collection<Unit> nonAirRetreating = new HashSet<>(retreatUnits);
//   nonAirRetreating.removeAll(airRetreating);
//   nonAirRetreating.addAll(battleState.getDependentUnits(nonAirRetreating));
//   if (!nonAirRetreating.isEmpty()) {
//     battleState.retreatUnits(OFFENSE, nonAirRetreating);
//     historyChildren.add(RetreatHistoryChild.of(
//         MyFormatter.unitsToText(nonAirRetreating) + " retreated to " + retreatTo.getName(),
//         new ArrayList<>(nonAirRetreating)));
//     change.add(ChangeFactory.moveUnits(battleState.getBattleSite(), retreatTo, nonAirRetreating));
//   }
//   return RetreatChanges.of(change, historyChildren);
retreater_general_compute_changes :: proc(
	self: ^Retreater_General,
	retreat_to: ^Territory,
) -> ^Retreater_Retreat_Changes {
	retreat_units := retreater_general_get_retreat_units(self)

	change := composite_change_new()
	history_children: [dynamic]^Retreater_Retreat_History_Child

	composite_change_add(
		change,
		retreater_general_compute_dependent_unit_changes(self, retreat_to, retreat_units),
	)

	offense_player := battle_state_get_player(self.battle_state, .OFFENSE)
	air_p, air_c := matches_unit_is_air()
	owned_p, owned_c := matches_unit_is_owned_by(offense_player)

	air_retreating: [dynamic]^Unit
	air_set := make(map[^Unit]bool)
	defer delete(air_set)
	for u in retreat_units {
		if air_p(air_c, u) && owned_p(owned_c, u) {
			if !(u in air_set) {
				air_set[u] = true
				append(&air_retreating, u)
			}
		}
	}

	if len(air_retreating) != 0 {
		battle_state_retreat_units(self.battle_state, .OFFENSE, air_retreating)
		transcript := fmt.aprintf("%s retreated", my_formatter_units_to_text(air_retreating))
		copy_air: [dynamic]^Unit
		for u in air_retreating {
			append(&copy_air, u)
		}
		append(&history_children, retreat_history_child_of(transcript, copy_air))
	}

	non_air_seen := make(map[^Unit]bool)
	defer delete(non_air_seen)
	non_air_retreating: [dynamic]^Unit
	for u in retreat_units {
		if !(u in air_set) && !(u in non_air_seen) {
			non_air_seen[u] = true
			append(&non_air_retreating, u)
		}
	}
	deps := battle_state_get_dependent_units(self.battle_state, non_air_retreating)
	for d in deps {
		if !(d in non_air_seen) {
			non_air_seen[d] = true
			append(&non_air_retreating, d)
		}
	}
	delete(deps)

	if len(non_air_retreating) != 0 {
		battle_state_retreat_units(self.battle_state, .OFFENSE, non_air_retreating)
		transcript := fmt.aprintf(
			"%s retreated to %s",
			my_formatter_units_to_text(non_air_retreating),
			retreat_to.named.base.name,
		)
		copy_nonair: [dynamic]^Unit
		for u in non_air_retreating {
			append(&copy_nonair, u)
		}
		append(&history_children, retreat_history_child_of(transcript, copy_nonair))
		composite_change_add(
			change,
			change_factory_move_units(
				battle_state_get_battle_site(self.battle_state),
				retreat_to,
				non_air_retreating,
			),
		)
	}

	delete(retreat_units)
	return retreat_changes_of(&change.change, history_children)
}

