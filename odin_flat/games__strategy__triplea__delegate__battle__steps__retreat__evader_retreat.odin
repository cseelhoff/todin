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
	units_local := units
	i_delegate_history_writer_add_child_to_event(writer, transcript_text, rawptr(&units_local))
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
		evader_retreat_lambda_retreat_units_0(parameters, step, optional_retreat_to)
	}
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#lambda$retreatUnits$0(
//   games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat$Parameters,
//   java.lang.String,
//   games.strategy.engine.data.Territory)
//
// Java (synthetic lambda body for
//   optionalRetreatTo.ifPresent(retreatTo -> retreatUnits(parameters, step, retreatTo)) ):
//   javac lifts the captured `parameters` and `step` to explicit
//   parameters of the synthetic lambda$retreatUnits$0 method; its body
//   is just the private retreatUnits(Parameters, String, Territory)
//   overload invocation.
evader_retreat_lambda_retreat_units_0 :: proc(
	parameters: ^Evader_Retreat_Parameters,
	step: string,
	retreat_to: ^Territory,
) {
	evader_retreat_retreat_units_to_territory(parameters, step, retreat_to)
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#submergeEvaders(
//   games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat$Parameters)
//
// Java:
//   final CompositeChange change = new CompositeChange();
//   for (final Unit u : parameters.units) {
//     change.add(ChangeFactory.unitPropertyChange(u, true, Unit.PropertyName.SUBMERGED));
//   }
//   parameters.bridge.addChange(change);
//   parameters.battleState.retreatUnits(parameters.side, parameters.units);
//   addHistoryRetreat(parameters.bridge, parameters.units, " submerged");
//   notifyRetreat(parameters.battleState, parameters.battleActions,
//                 parameters.units, parameters.side, parameters.bridge);
evader_retreat_submerge_evaders :: proc(parameters: ^Evader_Retreat_Parameters) {
	change := composite_change_new()
	for u in parameters.units {
		boxed := new(bool)
		boxed^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				u,
				rawptr(boxed),
				.Submerged,
			),
		)
	}
	i_delegate_bridge_add_change(parameters.bridge, &change.change)
	battle_state_retreat_units(parameters.battle_state, parameters.side, parameters.units)

	evader_retreat_add_history_retreat(parameters.bridge, parameters.units, " submerged")
	evader_retreat_notify_retreat(
		parameters.battle_state,
		parameters.battle_actions,
		parameters.units,
		parameters.side,
		parameters.bridge,
	)
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#retreatEvaders(
//   games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat$Parameters,
//   games.strategy.engine.data.Territory)
//
// Java:
//   final CompositeChange change = new CompositeChange();
//   change.add(ChangeFactory.moveUnits(
//       parameters.battleState.getBattleSite(), retreatTo, parameters.units));
//   parameters.bridge.addChange(change);
//   parameters.battleState.retreatUnits(parameters.side, parameters.units);
//   addHistoryRetreat(parameters.bridge, parameters.units,
//       " retreated to " + retreatTo.getName());
//   notifyRetreat(parameters.battleState, parameters.battleActions,
//                 parameters.units, parameters.side, parameters.bridge);
evader_retreat_retreat_evaders :: proc(
	parameters: ^Evader_Retreat_Parameters,
	retreat_to: ^Territory,
) {
	change := composite_change_new()
	composite_change_add(
		change,
		change_factory_move_units(
			battle_state_get_battle_site(parameters.battle_state),
			retreat_to,
			parameters.units,
		),
	)
	i_delegate_bridge_add_change(parameters.bridge, &change.change)
	battle_state_retreat_units(parameters.battle_state, parameters.side, parameters.units)

	retreat_to_name := default_named_get_name(&retreat_to.named_attachable.default_named)
	evader_retreat_add_history_retreat(
		parameters.bridge,
		parameters.units,
		fmt.aprintf(" retreated to %s", retreat_to_name),
	)
	evader_retreat_notify_retreat(
		parameters.battle_state,
		parameters.battle_actions,
		parameters.units,
		parameters.side,
		parameters.bridge,
	)
}

// games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat#retreatUnits(
//   games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat$Parameters,
//   java.lang.String,
//   games.strategy.engine.data.Territory)
//
// Java (private overload):
//   final GamePlayer retreatingPlayer = parameters.battleState.getPlayer(parameters.side);
//   SoundUtils.playRetreatType(retreatingPlayer, parameters.units,
//       MustFightBattle.RetreatType.SUBS, parameters.bridge);
//   if (parameters.battleState.getBattleSite().equals(retreatTo)) {
//     submergeEvaders(parameters);
//     longMessage = shortMessage = retreatingPlayer.getName() + " submerges subs";
//   } else {
//     retreatEvaders(parameters, retreatTo);
//     shortMessage = retreatingPlayer.getName() + " retreats";
//     longMessage = retreatingPlayer.getName() + " retreats subs to " + retreatTo.getName();
//   }
//   ...broadcaster.notifyRetreat(shortMessage, longMessage, step, retreatingPlayer);
//
// The websocket sendMessage(NotifyRetreatMessage) branch is dormant for
// snapshot runs (mirroring notifyRetreat / public retreatUnits above).
evader_retreat_retreat_units_to_territory :: proc(
	parameters: ^Evader_Retreat_Parameters,
	step: string,
	retreat_to: ^Territory,
) {
	retreating_player := battle_state_get_player(parameters.battle_state, parameters.side)

	sound_utils_play_retreat_type(
		retreating_player,
		parameters.units,
		.SUBS,
		parameters.bridge,
	)

	short_message: string
	long_message: string
	if battle_state_get_battle_site(parameters.battle_state) == retreat_to {
		evader_retreat_submerge_evaders(parameters)
		short_message = fmt.aprintf("%s submerges subs", retreating_player.named.base.name)
		long_message = short_message
	} else {
		evader_retreat_retreat_evaders(parameters, retreat_to)
		short_message = fmt.aprintf("%s retreats", retreating_player.named.base.name)
		retreat_to_name := default_named_get_name(&retreat_to.named_attachable.default_named)
		long_message = fmt.aprintf(
			"%s retreats subs to %s",
			retreating_player.named.base.name,
			retreat_to_name,
		)
	}

	display := i_delegate_bridge_get_display_channel_broadcaster(parameters.bridge)
	i_display_notify_retreat(
		display,
		short_message,
		long_message,
		step,
		retreating_player,
	)
}
