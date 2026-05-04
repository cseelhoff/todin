package game

import "core:fmt"
import "core:strings"

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.EndRoundDelegate

End_Round_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	game_over:    bool,
	winners:      [dynamic]^Game_Player,
}

// games.strategy.triplea.delegate.EndRoundDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
end_round_delegate_get_remote_type :: proc(self: ^End_Round_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.EndRoundDelegate#getProduction(GamePlayer)
// Java body:
//   return StreamSupport.stream(getData().getMap().spliterator(), false)
//       .filter(Matches.isTerritoryOwnedBy(gamePlayer))
//       .mapToInt(TerritoryAttachment::getProduction)
//       .sum();
// `TerritoryAttachment::getProduction` resolves to the static overload
// `TerritoryAttachment.getProduction(Territory)` (the only single-arg
// match for a Territory stream element), which returns 0 when the
// territory has no attachment. We inline that null-safe lookup here.
end_round_delegate_get_production :: proc(
	self: ^End_Round_Delegate,
	game_player: ^Game_Player,
) -> i32 {
	pred, pred_ctx := matches_is_territory_owned_by(game_player)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	territories := game_map_get_territories(game_data_get_map(data))
	sum: i32 = 0
	for t in territories {
		if !pred(pred_ctx, t) {
			continue
		}
		if t == nil || t.territory_attachment == nil {
			continue
		}
		sum += territory_attachment_get_production(t.territory_attachment)
	}
	return sum
}

// games.strategy.triplea.delegate.EndRoundDelegate#loadState(Serializable)
// Java body:
//   final EndRoundExtendedDelegateState s = (EndRoundExtendedDelegateState) state;
//   super.loadState(s.superState);
//   gameOver = s.gameOver;
//   winners = s.winners;
end_round_delegate_load_state :: proc(self: ^End_Round_Delegate, state: rawptr) {
	s := cast(^End_Round_Extended_Delegate_State)state
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)s.super_state,
	)
	self.game_over = s.game_over
	self.winners = s.winners
}

// games.strategy.triplea.delegate.EndRoundDelegate#<init>()
// Java body is empty (`public EndRoundDelegate() {}`); the implicit
// constructor only runs the field initializers `gameOver = false`
// and `winners = new ArrayList<>()`. The parent
// `BaseTripleADelegate` has no field initializers worth replaying
// here (its own state is set up by the engine after construction),
// matching the convention used by `abstract_end_turn_delegate_new`.
end_round_delegate_new :: proc() -> ^End_Round_Delegate {
	self := new(End_Round_Delegate)
	self.game_over = false
	self.winners = make([dynamic]^Game_Player)
	return self
}

// games.strategy.triplea.delegate.EndRoundDelegate#saveState()
// Java body:
//   final EndRoundExtendedDelegateState state = new EndRoundExtendedDelegateState();
//   state.superState = super.saveState();
//   state.gameOver = gameOver;
//   state.winners = winners;
//   return state;
// Java returns `Serializable`; the Odin port returns the concrete
// state pointer (callers downcast in `loadState`, mirroring the
// pattern used elsewhere in this package, e.g.
// `abstract_end_turn_delegate_save_state`).
end_round_delegate_save_state :: proc(
	self: ^End_Round_Delegate,
) -> ^End_Round_Extended_Delegate_State {
	state := end_round_extended_delegate_state_new()
	state.super_state = base_triple_a_delegate_save_state(&self.base_triple_a_delegate)
	state.game_over = self.game_over
	state.winners = self.winners
	return state
}

// games.strategy.triplea.delegate.EndRoundDelegate#getEconomicVictoryAmount(GameState, String)
// Java body:
//   return data.getProperties().get(alliance + " Economic Victory", 200);
end_round_delegate_get_economic_victory_amount :: proc(
	data: ^Game_State,
	alliance: string,
) -> i32 {
	key := strings.concatenate({alliance, " Economic Victory"})
	defer delete(key)
	return game_properties_get_int_with_default(game_state_get_properties(data), key, 200)
}

// games.strategy.triplea.delegate.EndRoundDelegate#getVcAmount(GameState, String, String)
// Java body:
//   int defaultVc = 20;
//   switch (type) {
//     case " Total Victory VCs":         defaultVc = 18; break;
//     case " Honorable Victory VCs":     defaultVc = 15; break;
//     case " Projection of Power VCs":   defaultVc = 13; break;
//     default: break;
//   }
//   return data.getProperties().get((alliance + type), defaultVc);
end_round_delegate_get_vc_amount :: proc(
	data: ^Game_State,
	alliance: string,
	type: string,
) -> i32 {
	default_vc: i32 = 20
	switch type {
	case " Total Victory VCs":
		default_vc = 18
	case " Honorable Victory VCs":
		default_vc = 15
	case " Projection of Power VCs":
		default_vc = 13
	}
	key := strings.concatenate({alliance, type})
	defer delete(key)
	return game_properties_get_int_with_default(game_state_get_properties(data), key, default_vc)
}

// games.strategy.triplea.delegate.EndRoundDelegate#signalGameOver(String, Collection<GamePlayer>, IDelegateBridge)
// Java body (websocket branch is dormant for snapshot runs; we always
// take the broadcaster path, matching the convention used by
// `evader_retreat_notify_retreat` and the other delegate ports):
//   if (!gameOver) {
//     gameOver = true;
//     this.winners = winners;
//     bridge.getSoundChannelBroadcaster().playSoundForAll(
//         SoundPath.CLIP_GAME_WON,
//         (winners != null && !winners.isEmpty())
//             ? CollectionUtils.getAny(winners)
//             : getData().getPlayerList().getNullPlayer());
//     final String title = "Victory Achieved" + (winners.isEmpty() ? "" : " by " + MyFormatter.defaultNamedToTextList(winners));
//     bridge.getDisplayChannelBroadcaster().reportMessageToAll("<html>" + status + "</html>", title, true, false, true);
//     bridge.stopGameSequence(status, title);
//   }
end_round_delegate_signal_game_over :: proc(
	self: ^End_Round_Delegate,
	status: string,
	winners: [dynamic]^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	if self.game_over {
		return
	}
	self.game_over = true
	self.winners = winners

	sound_player: ^Game_Player
	if len(self.winners) > 0 {
		sound_player = self.winners[0]
	} else {
		data := abstract_delegate_get_data(&self.abstract_delegate)
		sound_player = player_list_get_null_player(game_data_get_player_list(data))
	}
	headless_sound_channel_play_sound_for_all(
		i_delegate_bridge_get_sound_channel_broadcaster(bridge),
		"game_won",
		sound_player,
	)

	title: string
	if len(winners) == 0 {
		title = "Victory Achieved"
	} else {
		named_winners: [dynamic]^Default_Named
		defer delete(named_winners)
		for w in winners {
			append(&named_winners, &w.named_attachable.default_named)
		}
		players_text := my_formatter_default_named_to_text_list_simple(named_winners)
		title = strings.concatenate({"Victory Achieved by ", players_text})
	}

	html := strings.concatenate({"<html>", status, "</html>"})
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_report_message_to_all(display, html, title, true, false, true)
	i_delegate_bridge_stop_game_sequence(bridge, status, title)
}

// games.strategy.triplea.delegate.EndRoundDelegate#checkVictoryCities(IDelegateBridge, String, String)
// Java body:
//   final GameState data = bridge.getData();
//   final Collection<Territory> territories = data.getMap().getTerritories();
//   for (final String allianceName : data.getAllianceTracker().getAlliances()) {
//     final int vcAmount = getVcAmount(data, allianceName, victoryType);
//     final Set<GamePlayer> teamMembers =
//         data.getAllianceTracker().getPlayersInAlliance(allianceName);
//     int teamVCs = 0;
//     for (final Territory t : territories) {
//       if (Matches.isTerritoryOwnedByAnyOf(teamMembers).test(t)) {
//         teamVCs += TerritoryAttachment.get(t).map(TerritoryAttachment::getVictoryCity).orElse(0);
//       }
//     }
//     if (teamVCs >= vcAmount) {
//       bridge.getHistoryWriter().startEvent(allianceName + victoryMessage + vcAmount + " Victory Cities!");
//       final Collection<GamePlayer> winners =
//           data.getAllianceTracker().getPlayersInAlliance(allianceName);
//       signalGameOver(allianceName + victoryMessage + vcAmount + " Victory Cities!", winners, bridge);
//     }
//   }
//
// Notes:
//   - `Matches.isTerritoryOwnedByAnyOf` takes an `Iterable<GamePlayer>`;
//     the Odin port takes a `[dynamic]^Game_Player`, so the alliance
//     team-member set is materialised into a temporary dynamic array.
//   - `TerritoryAttachment.get(t).map(getVictoryCity).orElse(0)`
//     reduces to a null-safe field access on the cached attachment
//     pointer, matching the convention used by
//     `end_round_delegate_get_production`.
end_round_delegate_check_victory_cities :: proc(
	self: ^End_Round_Delegate,
	bridge: ^I_Delegate_Bridge,
	victory_message: string,
	victory_type: string,
) {
	data := i_delegate_bridge_get_data(bridge)
	territories := game_map_get_territories(game_data_get_map(data))
	for alliance_name in alliance_tracker_get_alliances(game_data_get_alliance_tracker(data)) {
		vc_amount := end_round_delegate_get_vc_amount(&data.game_state, alliance_name, victory_type)
		team_members_set := alliance_tracker_get_players_in_alliance(
			game_data_get_alliance_tracker(data),
			alliance_name,
		)
		team_members: [dynamic]^Game_Player
		defer delete(team_members)
		for p in team_members_set {
			append(&team_members, p)
		}
		pred, pred_ctx := matches_is_territory_owned_by_any_of(team_members)
		team_vcs: i32 = 0
		for t in territories {
			if !pred(pred_ctx, t) {
				continue
			}
			if t.territory_attachment == nil {
				continue
			}
			team_vcs += t.territory_attachment.victory_city
		}
		if team_vcs >= vc_amount {
			event_msg := fmt.aprintf(
				"%s%s%d Victory Cities!",
				alliance_name,
				victory_message,
				vc_amount,
			)
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				event_msg,
			)
			winners_set := alliance_tracker_get_players_in_alliance(
				game_data_get_alliance_tracker(data),
				alliance_name,
			)
			winners: [dynamic]^Game_Player
			for p in winners_set {
				append(&winners, p)
			}
			end_round_delegate_signal_game_over(self, event_msg, winners, bridge)
		}
	}
}

