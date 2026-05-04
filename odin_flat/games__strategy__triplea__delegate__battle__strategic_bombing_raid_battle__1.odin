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

