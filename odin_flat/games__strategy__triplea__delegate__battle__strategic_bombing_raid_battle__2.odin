package game

import "core:fmt"

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$2
// Anonymous IExecutable returned by StrategicBombingRaidBattle.end().
// Java declares only `static final long serialVersionUID` (no instance fields);
// outer-class references are implicit captures of the enclosing
// StrategicBombingRaidBattle instance.
Strategic_Bombing_Raid_Battle_2 :: struct {
	using i_executable: I_Executable,
	outer:              ^Strategic_Bombing_Raid_Battle,
}

strategic_bombing_raid_battle_2_new :: proc(outer: ^Strategic_Bombing_Raid_Battle) -> ^Strategic_Bombing_Raid_Battle_2 {
	self := new(Strategic_Bombing_Raid_Battle_2)
	self.outer = outer
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$2#execute
//
//   if (Properties.getDamageFromBombingDoneToUnitsInsteadOfTerritories(
//       gameData.getProperties())) {
//     bridge.getDisplayChannelBroadcaster().battleEnd(
//         battleId,
//         MessageFormat.format("Raid causes {0} damage total.{1}",
//             bombingRaidTotal,
//             bombingRaidDamage.size() > 1
//                 ? MessageFormat.format(" To units: {0}",
//                     MyFormatter.integerUnitMapToString(
//                         bombingRaidDamage, ", ", " = ", false))
//                 : ""));
//   } else {
//     bridge.getDisplayChannelBroadcaster().battleEnd(
//         battleId,
//         MessageFormat.format("Bombing raid cost {0} {1}",
//             bombingRaidTotal,
//             MyFormatter.pluralize("PU", bombingRaidTotal)));
//   }
//   if (bombingRaidTotal > 0) {
//     whoWon = WhoWon.ATTACKER;
//     battleResultDescription = BattleRecord.BattleResultDescription.BOMBED;
//   } else {
//     whoWon = WhoWon.DEFENDER;
//     battleResultDescription = BattleRecord.BattleResultDescription.LOST;
//   }
//   battleTracker.getBattleRecords().addResultToBattle(
//       attacker, battleId, defender,
//       attackerLostTuv, defenderLostTuv, battleResultDescription,
//       new BattleResults(StrategicBombingRaidBattle.this, gameData));
//   isOver = true;
//   battleTracker.removeBattle(StrategicBombingRaidBattle.this, gameData);
strategic_bombing_raid_battle_2_execute :: proc(
	self:   ^Strategic_Bombing_Raid_Battle_2,
	stack:  ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	outer := self.outer
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)

	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(outer.game_data),
	) {
		suffix: string = ""
		if integer_map_size(&outer.bombing_raid_damage) > 1 {
			suffix = fmt.aprintf(
				" To units: %s",
				my_formatter_integer_unit_map_to_string(
					&outer.bombing_raid_damage,
					", ",
					" = ",
					false,
				),
			)
		}
		i_display_battle_end(
			display,
			outer.battle_id,
			fmt.aprintf("Raid causes %d damage total.%s", outer.bombing_raid_total, suffix),
		)
	} else {
		i_display_battle_end(
			display,
			outer.battle_id,
			fmt.aprintf(
				"Bombing raid cost %d %s",
				outer.bombing_raid_total,
				my_formatter_pluralize_quantity("PU", outer.bombing_raid_total),
			),
		)
	}

	if outer.bombing_raid_total > 0 {
		outer.who_won = .ATTACKER
		outer.battle_result_description = .BOMBED
	} else {
		outer.who_won = .DEFENDER
		outer.battle_result_description = .LOST
	}
	battle_records_add_result_to_battle(
		battle_tracker_get_battle_records(outer.battle_tracker),
		outer.attacker,
		outer.battle_id,
		outer.defender,
		outer.attacker_lost_tuv,
		outer.defender_lost_tuv,
		outer.battle_result_description,
		battle_results_new(cast(^I_Battle)&outer.abstract_battle, outer.game_data),
	)
	outer.is_over = true
	battle_tracker_remove_battle(
		outer.battle_tracker,
		cast(^I_Battle)&outer.abstract_battle,
		outer.game_data,
	)
}
