package game

import "core:fmt"

Evader_Retreat :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#addHistoryRetreat(
//   games.strategy.engine.delegate.IDelegateBridge,
//   java.util.Collection,
//   java.lang.String)
//
// Java:
//   final String transcriptText = MyFormatter.unitsToText(units) + suffix;
//   bridge.getHistoryWriter().addChildToEvent(transcriptText, new ArrayList<>(units));
evader_retreat_add_history_retreat :: proc(
	bridge: ^I_Delegate_Bridge,
	units: [dynamic]^Unit,
	suffix: string,
) {
	transcript_text := fmt.aprintf("%s%s", my_formatter_units_to_text(units), suffix)
	writer := i_delegate_bridge_get_history_writer(bridge)
	history_writer_add_child_to_event(writer, transcript_text, units)
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#notifyRetreat(
//   games.strategy.triplea.delegate.battle.BattleState,
//   games.strategy.triplea.delegate.battle.BattleActions,
//   java.util.Collection,
//   games.strategy.triplea.delegate.battle.BattleState$Side,
//   games.strategy.engine.delegate.IDelegateBridge)
//
// Java:
//   if (battleState.filterUnits(ALIVE, side).isEmpty()) {
//     battleActions.endBattle(side.getOpposite().getWhoWon(), bridge);
//   } else {
//     if (ClientSetting.useWebsocketNetwork.getValue().orElse(false)) {
//       bridge.sendMessage(new IDisplay.NotifyUnitsRetreatingMessage(...));
//     } else {
//       bridge.getDisplayChannelBroadcaster().notifyRetreat(battleState.getBattleId(), retreating);
//     }
//   }
//
// The websocket branch is dormant for snapshot runs (the setting
// defaults to false); we always take the broadcaster path, mirroring
// the convention used in remove_non_combatants.odin.
evader_retreat_notify_retreat :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	retreating: [dynamic]^Unit,
	side: Battle_State_Side,
	bridge: ^I_Delegate_Bridge,
) {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	alive_units := battle_state_filter_units(battle_state, alive_filter, side)
	if len(alive_units) == 0 {
		battle_actions_end_battle(
			battle_actions,
			battle_state_side_get_who_won(battle_state_side_get_opposite(side)),
			bridge,
		)
	} else {
		display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
		i_display_notify_retreat_units(
			display,
			battle_state_get_battle_id(battle_state),
			retreating,
		)
	}
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#retreatUnits(
//   games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat$Parameters,
//   java.util.Collection,
//   java.lang.String)
//
// Java:
//   final GamePlayer retreatingPlayer = parameters.battleState.getPlayer(parameters.side);
//   final String text = retreatingPlayer.getName() + " retreat subs?";
//   ...broadcaster.gotoBattleStep(parameters.battleState.getBattleId(), step);
//   final boolean isAttemptingSubmerge =
//       possibleRetreatSites.size() == 1
//           && possibleRetreatSites.contains(parameters.battleState.getBattleSite());
//   final Optional<Territory> optionalRetreatTo =
//       isAttemptingSubmerge
//           ? parameters.battleActions.querySubmergeTerritory(...)
//           : parameters.battleActions.queryRetreatTerritory(...);
//   optionalRetreatTo.ifPresent(retreatTo -> retreatUnits(parameters, step, retreatTo));
//
// The websocket branch (sendMessage(GoToBattleStepMessage)) is omitted
// for the same reason as notifyRetreat above.
evader_retreat_retreat_units :: proc(
	parameters: ^Evader_Retreat_Parameters,
	possible_retreat_sites: [dynamic]^Territory,
	step: string,
) {
	retreating_player := battle_state_get_player(parameters.battle_state, parameters.side)
	text := fmt.aprintf("%s retreat subs?", retreating_player.named.base.name)

	display := i_delegate_bridge_get_display_channel_broadcaster(parameters.bridge)
	i_display_goto_battle_step(
		display,
		battle_state_get_battle_id(parameters.battle_state),
		step,
	)

	battle_site := battle_state_get_battle_site(parameters.battle_state)
	is_attempting_submerge := false
	if len(possible_retreat_sites) == 1 {
		for t in possible_retreat_sites {
			if t == battle_site {
				is_attempting_submerge = true
				break
			}
		}
	}

	optional_retreat_to: ^Territory
	if is_attempting_submerge {
		optional_retreat_to = battle_actions_query_submerge_territory(
			parameters.battle_actions,
			parameters.battle_state,
			parameters.bridge,
			retreating_player,
			possible_retreat_sites,
			text,
		)
	} else {
		optional_retreat_to = battle_actions_query_retreat_territory(
			parameters.battle_actions,
			parameters.battle_state,
			parameters.bridge,
			retreating_player,
			possible_retreat_sites,
			text,
		)
	}

	if optional_retreat_to != nil {
		evader_retreat_retreat_units_to_territory(parameters, step, optional_retreat_to)
	}
}
