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

// games.strategy.triplea.delegate.EndRoundDelegate#end()
// Java body:
//   super.end();
//   final GameState data = getData();
//   if (Properties.getTriggers(data.getProperties())) {
//     final CompositeChange change = new CompositeChange();
//     for (final GamePlayer player : data.getPlayerList().getPlayers()) {
//       change.add(AbstractTriggerAttachment.triggerSetUsedForThisRound(player));
//     }
//     if (!change.isEmpty()) {
//       bridge.getHistoryWriter().startEvent("Setting uses for triggers used this round.");
//       bridge.addChange(change);
//     }
//   }
end_round_delegate_end :: proc(self: ^End_Round_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if properties_get_triggers(game_data_get_properties(data)) {
		change := composite_change_new()
		for player in player_list_get_players(game_data_get_player_list(data)) {
			inner := abstract_trigger_attachment_trigger_set_used_for_this_round(player)
			composite_change_add(change, &inner.change)
		}
		if !composite_change_is_empty(change) {
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(self.bridge),
				"Setting uses for triggers used this round.",
			)
			i_delegate_bridge_add_change(self.bridge, &change.change)
		}
	}
}

// AND-chained Predicate<TriggerAttachment> used by start():
//   availableUses
//     .and(whenOrDefaultMatch(null, null))
//     .and(activateTriggerMatch().or(victoryMatch()))
// `availableUses`, `activateTriggerMatch`, and `victoryMatch` are
// non-capturing bare procs; `whenOrDefaultMatch` carries a captured
// (proc, rawptr) pair. The composite predicate therefore stores only
// the when-pair and short-circuits the rest inline.
End_Round_Delegate_Ctx_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

end_round_delegate_lambda_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^End_Round_Delegate_Ctx_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	if trigger_attachment_lambda_activate_trigger_match(t) {
		return true
	}
	return trigger_attachment_lambda_victory_match(t)
}

// games.strategy.triplea.delegate.EndRoundDelegate#start()
// Java body translated branch-for-branch. Constants.PLAYER_NAME_*
// resolve to literal strings (verified against
// games/strategy/triplea/Constants.java): "Japanese", "Germans",
// "British", "Russians", "Americans".
end_round_delegate_start :: proc(self: ^End_Round_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	if self.game_over {
		return
	}
	data := abstract_delegate_get_data(&self.abstract_delegate)
	props := game_data_get_properties(data)

	// Pacific theater VP victory.
	if properties_get_pacific_theater(props) {
		japanese := player_list_get_player_id(
			game_data_get_player_list(data),
			"Japanese",
		)
		pa := player_attachment_get(japanese)
		if pa != nil && player_attachment_get_vps(pa) >= 22 {
			victory_message := "Axis achieve VP victory"
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(self.bridge),
				victory_message,
			)
			// CollectionUtils.getAny over the alliance-name set ⇒ pick the
			// first key from the map (iteration order does not matter for
			// the snapshot harness because the AI test setup has Japanese
			// in exactly one alliance).
			alliance_name: string
			any_alliance := false
			for an in alliance_tracker_get_alliances_player_is_in(
				game_data_get_alliance_tracker(data),
				japanese,
			) {
				alliance_name = an
				any_alliance = true
				break
			}
			if any_alliance {
				winners_set := alliance_tracker_get_players_in_alliance(
					game_data_get_alliance_tracker(data),
					alliance_name,
				)
				winners: [dynamic]^Game_Player
				for p in winners_set {
					append(&winners, p)
				}
				end_round_delegate_signal_game_over(
					self,
					victory_message,
					winners,
					self.bridge,
				)
			}
		}
	}

	// Win by Victory Cities.
	if properties_get_total_victory(props) {
		end_round_delegate_check_victory_cities(
			self,
			self.bridge,
			" achieve TOTAL VICTORY with ",
			" Total Victory VCs",
		)
	}
	if properties_get_honorable_surrender(props) {
		end_round_delegate_check_victory_cities(
			self,
			self.bridge,
			" achieve an HONORABLE VICTORY with ",
			" Honorable Victory VCs",
		)
	}
	if properties_get_projection_of_power(props) {
		end_round_delegate_check_victory_cities(
			self,
			self.bridge,
			" achieve victory through a PROJECTION OF POWER with ",
			" Projection of Power VCs",
		)
	}

	// Regular economic victory.
	if properties_get_economic_victory(props) {
		for alliance_name in alliance_tracker_get_alliances(
			game_data_get_alliance_tracker(data),
		) {
			victory_amount := end_round_delegate_get_economic_victory_amount(
				&data.game_state,
				alliance_name,
			)
			team_members := alliance_tracker_get_players_in_alliance(
				game_data_get_alliance_tracker(data),
				alliance_name,
			)
			team_prod: i32 = 0
			for player in team_members {
				team_prod += end_round_delegate_get_production(self, player)
				if team_prod >= victory_amount {
					victory_message := strings.concatenate(
						{alliance_name, " achieve economic victory"},
					)
					i_delegate_history_writer_start_event(
						i_delegate_bridge_get_history_writer(self.bridge),
						victory_message,
					)
					winners_set := alliance_tracker_get_players_in_alliance(
						game_data_get_alliance_tracker(data),
						alliance_name,
					)
					winners: [dynamic]^Game_Player
					for p in winners_set {
						append(&winners, p)
					}
					end_round_delegate_signal_game_over(
						self,
						victory_message,
						winners,
						self.bridge,
					)
				}
			}
		}
	}

	// Generic trigger-based victories.
	if properties_get_triggered_victory(props) {
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
		match_ctx := new(End_Round_Delegate_Ctx_trigger_match)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx

		players_set := make(map[^Game_Player]struct {})
		defer delete(players_set)
		for p in player_list_get_players(game_data_get_player_list(data)) {
			players_set[p] = {}
		}

		to_fire_possible := trigger_attachment_collect_for_all_triggers_matching(
			players_set,
			end_round_delegate_lambda_trigger_match,
			rawptr(match_ctx),
		)
		if len(to_fire_possible) != 0 {
			tested_conditions := trigger_attachment_collect_tests_for_all_triggers_simple(
				to_fire_possible,
				self.bridge,
			)
			satisfied_pred, satisfied_ctx := abstract_trigger_attachment_is_satisfied_match(
				tested_conditions,
			)
			to_fire_satisfied := make(map[^Trigger_Attachment]struct {})
			defer delete(to_fire_satisfied)
			for t in to_fire_possible {
				if satisfied_pred(satisfied_ctx, t) {
					to_fire_satisfied[t] = {}
				}
			}
			fire_trigger_params := fire_trigger_params_new("", "", true, true, true, true)
			trigger_attachment_trigger_activate_trigger_other(
				tested_conditions,
				to_fire_satisfied,
				self.bridge,
				fire_trigger_params,
			)
			trigger_attachment_trigger_victory(
				to_fire_satisfied,
				self.bridge,
				fire_trigger_params,
			)
		}
	}

	if properties_get_ww2_v2(props) || properties_get_ww2_v3(props) {
		return
	}

	// Older 5-player maps: simple "who still owns their capital" check.
	player_list := game_data_get_player_list(data)
	russians := player_list_get_player_id(player_list, "Russians")
	germans := player_list_get_player_id(player_list, "Germans")
	british := player_list_get_player_id(player_list, "British")
	japanese := player_list_get_player_id(player_list, "Japanese")
	americans := player_list_get_player_id(player_list, "Americans")
	if germans == nil ||
	   russians == nil ||
	   british == nil ||
	   japanese == nil ||
	   americans == nil ||
	   player_list_size(player_list) > 5 {
		return
	}

	game_map := game_data_get_map(data)
	russia :=
		territory_get_owner(
			territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw(
				russians,
				game_map,
			),
		) ==
		russians
	germany :=
		territory_get_owner(
			territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw(
				germans,
				game_map,
			),
		) ==
		germans
	britain :=
		territory_get_owner(
			territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw(
				british,
				game_map,
			),
		) ==
		british
	japan :=
		territory_get_owner(
			territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw(
				japanese,
				game_map,
			),
		) ==
		japanese
	america :=
		territory_get_owner(
			territory_attachment_get_first_owned_capital_or_first_unowned_capital_or_throw(
				americans,
				game_map,
			),
		) ==
		americans

	count: i32 = 0
	if !russia {
		count += 1
	}
	if !britain {
		count += 1
	}
	if !america {
		count += 1
	}
	military_msg := " achieve a military victory"
	if germany && japan && count >= 2 {
		event := strings.concatenate({"Axis", military_msg})
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			event,
		)
		winners_set := alliance_tracker_get_players_in_alliance(
			game_data_get_alliance_tracker(data),
			"Axis",
		)
		winners: [dynamic]^Game_Player
		for p in winners_set {
			append(&winners, p)
		}
		end_round_delegate_signal_game_over(self, event, winners, self.bridge)
	}
	if russia && !germany && britain && !japan && america {
		event := strings.concatenate({"Allies", military_msg})
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			event,
		)
		winners_set := alliance_tracker_get_players_in_alliance(
			game_data_get_alliance_tracker(data),
			"Allies",
		)
		winners: [dynamic]^Game_Player
		for p in winners_set {
			append(&winners, p)
		}
		end_round_delegate_signal_game_over(self, event, winners, self.bridge)
	}
}

