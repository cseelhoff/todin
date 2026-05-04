package game

import "core:fmt"

Strategic_Bombing_Raid_Battle_1 :: struct {
	using i_executable: I_Executable,
	outer:        ^Strategic_Bombing_Raid_Battle,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1

strategic_bombing_raid_battle_1_new :: proc(outer: ^Strategic_Bombing_Raid_Battle) -> ^Strategic_Bombing_Raid_Battle_1 {
	self := new(Strategic_Bombing_Raid_Battle_1)
	self.outer = outer
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1#addPostBombingToHistory
//
// Java:
//   if (Properties.getDamageFromBombingDoneToUnitsInsteadOfTerritories(
//           gameData.getProperties())) {
//     bridge.getHistoryWriter().addChildToEvent(MessageFormat.format(
//         "Bombing raid in {0} causes {1} damage total. {2}",
//         battleSite.getName(), bombingRaidTotal,
//         bombingRaidDamage.size() > 1
//             ? MessageFormat.format(" Damaged units is as follows: {0}",
//                 MyFormatter.integerUnitMapToString(
//                     bombingRaidDamage, ", ", " = ", false))
//             : ""));
//   } else {
//     bridge.getHistoryWriter().addChildToEvent(MessageFormat.format(
//         "Bombing raid costs {0} {1}",
//         bombingRaidTotal, MyFormatter.pluralize("PU", bombingRaidTotal)));
//   }
strategic_bombing_raid_battle_1_add_post_bombing_to_history :: proc(
	self: ^Strategic_Bombing_Raid_Battle_1,
	bridge: ^I_Delegate_Bridge,
) {
	outer := self.outer
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(outer.game_data),
	) {
		suffix: string
		if integer_map_size(&outer.bombing_raid_damage) > 1 {
			suffix = fmt.aprintf(
				" Damaged units is as follows: %s",
				my_formatter_integer_unit_map_to_string(&outer.bombing_raid_damage, ", ", " = ", false),
			)
		} else {
			suffix = ""
		}
		msg := fmt.aprintf(
			"Bombing raid in %s causes %d damage total. %s",
			outer.battle_site.name,
			outer.bombing_raid_total,
			suffix,
		)
		history_writer_add_child_to_event(history_writer, msg)
	} else {
		msg := fmt.aprintf(
			"Bombing raid costs %d %s",
			outer.bombing_raid_total,
			my_formatter_pluralize_quantity("PU", outer.bombing_raid_total),
		)
		history_writer_add_child_to_event(history_writer, msg)
	}
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1#killAnyWithMaxDamageReached
//
// Java:
//   if (targets.keySet().stream().anyMatch(Matches.unitCanDieFromReachingMaxDamage())) {
//     final List<Unit> unitsCanDie = CollectionUtils.getMatches(
//         targets.keySet(), Matches.unitCanDieFromReachingMaxDamage());
//     unitsCanDie.retainAll(CollectionUtils.getMatches(
//         unitsCanDie, Matches.unitIsAtMaxDamageOrNotCanBeDamaged(battleSite)));
//     if (!unitsCanDie.isEmpty()) {
//       HistoryChangeFactory.removeUnitsFromTerritory(battleSite, unitsCanDie).perform(bridge);
//       final IntegerMap<UnitType> costs = bridge.getCostsForTuv(defender);
//       final int tuvLostDefender = TuvUtils.getTuv(unitsCanDie, defender, costs, gameData);
//       defenderLostTuv += tuvLostDefender;
//     }
//   }
strategic_bombing_raid_battle_1_kill_any_with_max_damage_reached :: proc(
	self: ^Strategic_Bombing_Raid_Battle_1,
	bridge: ^I_Delegate_Bridge,
) {
	outer := self.outer
	can_die_p, can_die_c := matches_unit_can_die_from_reaching_max_damage()
	max_p, max_c := matches_unit_is_at_max_damage_or_not_can_be_damaged(outer.battle_site)

	any_match := false
	for u, _ in outer.targets {
		if can_die_p(can_die_c, u) {
			any_match = true
			break
		}
	}
	if !any_match {
		return
	}

	units_can_die: [dynamic]^Unit
	for u, _ in outer.targets {
		if can_die_p(can_die_c, u) && max_p(max_c, u) {
			append(&units_can_die, u)
		}
	}

	if len(units_can_die) == 0 {
		return
	}

	remove_units_history_change_perform(
		history_change_factory_remove_units_from_territory(outer.battle_site, units_can_die),
		bridge,
	)

	costs_map := i_delegate_bridge_get_costs_for_tuv(bridge, outer.defender)
	costs := new(Integer_Map_Unit_Type)
	defer free(costs)
	costs.entries = costs_map
	tuv_lost_defender := tuv_utils_get_tuv_for_player(
		units_can_die,
		outer.defender,
		costs,
		outer.game_data,
	)
	outer.defender_lost_tuv += tuv_lost_defender
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1#killAnySuicideAttackers
//
// Java:
//   if (attackingUnits.stream().anyMatch(Matches.unitIsSuicideOnAttack())) {
//     final List<Unit> suicideUnits = CollectionUtils.getMatches(
//         attackingUnits, Matches.unitIsSuicideOnAttack());
//     attackingUnits.removeAll(suicideUnits);
//     HistoryChangeFactory.removeUnitsFromTerritory(battleSite, suicideUnits).perform(bridge);
//     final IntegerMap<UnitType> costs = bridge.getCostsForTuv(attacker);
//     final int tuvLostAttacker = TuvUtils.getTuv(suicideUnits, attacker, costs, gameData);
//     attackerLostTuv += tuvLostAttacker;
//   }
strategic_bombing_raid_battle_1_kill_any_suicide_attackers :: proc(
	self: ^Strategic_Bombing_Raid_Battle_1,
	bridge: ^I_Delegate_Bridge,
) {
	outer := self.outer
	soa_p, soa_c := matches_unit_is_suicide_on_attack()

	any_match := false
	for u in outer.attacking_units {
		if soa_p(soa_c, u) {
			any_match = true
			break
		}
	}
	if !any_match {
		return
	}

	suicide_units: [dynamic]^Unit
	for u in outer.attacking_units {
		if soa_p(soa_c, u) {
			append(&suicide_units, u)
		}
	}

	suicide_set: map[^Unit]struct{}
	defer delete(suicide_set)
	for u in suicide_units {
		suicide_set[u] = {}
	}
	kept: [dynamic]^Unit
	for u in outer.attacking_units {
		if _, found := suicide_set[u]; !found {
			append(&kept, u)
		}
	}
	delete(outer.attacking_units)
	outer.attacking_units = kept

	remove_units_history_change_perform(
		history_change_factory_remove_units_from_territory(outer.battle_site, suicide_units),
		bridge,
	)

	costs_map := i_delegate_bridge_get_costs_for_tuv(bridge, outer.attacker)
	costs := new(Integer_Map_Unit_Type)
	defer free(costs)
	costs.entries = costs_map
	tuv_lost_attacker := tuv_utils_get_tuv_for_player(
		suicide_units,
		outer.attacker,
		costs,
		outer.game_data,
	)
	outer.attacker_lost_tuv += tuv_lost_attacker
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1#execute
//
// Java:
//   bridge.getDisplayChannelBroadcaster().gotoBattleStep(battleId, RAID);
//   addPostBombingToHistory(bridge);
//   if ((Properties.getPacificTheater(gameData.getProperties())
//           || Properties.getSbrVictoryPoints(gameData.getProperties()))
//       && defender.getName().equals(Constants.PLAYER_NAME_JAPANESE)) {
//     final PlayerAttachment pa = PlayerAttachment.get(defender);
//     if (pa != null) {
//       final Change changeVp = ChangeFactory.attachmentPropertyChange(
//           pa, (-(bombingRaidTotal / 10) + pa.getVps()), "vps");
//       bridge.addChange(changeVp);
//       bridge.getHistoryWriter().addChildToEvent(MessageFormat.format(
//           "Bombing raid costs {0} {1}",
//           bombingRaidTotal / 10,
//           MyFormatter.pluralize("vp", (bombingRaidTotal / 10))));
//     }
//   }
//   killAnySuicideAttackers(bridge);
//   killAnyWithMaxDamageReached(bridge);
strategic_bombing_raid_battle_1_execute :: proc(
	self: ^Strategic_Bombing_Raid_Battle_1,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	outer := self.outer
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_goto_battle_step(display, outer.battle_id, "Strategic bombing raid")
	strategic_bombing_raid_battle_1_add_post_bombing_to_history(self, bridge)

	props := game_data_get_properties(outer.game_data)
	if (properties_get_pacific_theater(props) || properties_get_sbr_victory_points(props)) &&
	   outer.defender.name == "Japanese" {
		pa := player_attachment_get(outer.defender)
		if pa != nil {
			new_value := new(i32)
			new_value^ = -(outer.bombing_raid_total / 10) + player_attachment_get_vps(pa)
			change_vp := change_factory_attachment_property_change(
				cast(^I_Attachment)rawptr(pa),
				rawptr(new_value),
				"vps",
			)
			i_delegate_bridge_add_change(bridge, change_vp)
			history_writer := i_delegate_bridge_get_history_writer(bridge)
			msg := fmt.aprintf(
				"Bombing raid costs %d %s",
				outer.bombing_raid_total / 10,
				my_formatter_pluralize_quantity("vp", outer.bombing_raid_total / 10),
			)
			history_writer_add_child_to_event(history_writer, msg)
		}
	}
	strategic_bombing_raid_battle_1_kill_any_suicide_attackers(self, bridge)
	strategic_bombing_raid_battle_1_kill_any_with_max_damage_reached(self, bridge)
}

