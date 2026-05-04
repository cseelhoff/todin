package game

import "core:fmt"
import "core:strconv"
import "core:strings"

Politics_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PoliticsDelegate

// games.strategy.triplea.delegate.PoliticsDelegate#getTestedConditions()
// Java:
//   final Set<ICondition> allConditionsNeeded =
//       RulesAttachment.getAllConditionsRecursive(
//           new HashSet<>(PoliticalActionAttachment.getPoliticalActionAttachments(player)),
//           null);
//   return RulesAttachment.testAllConditionsRecursive(allConditionsNeeded, null, bridge);
// The static helpers live on the AbstractConditionsAttachment ancestor in
// the Odin port; PAAs widen to ^I_Condition through their offset-0 cast,
// matching the convention in abstract_conditions_attachment.odin.
politics_delegate_get_tested_conditions :: proc(
	self: ^Politics_Delegate,
) -> map[^I_Condition]bool {
	paas := political_action_attachment_get_political_action_attachments(self.player)
	starting := make(map[^I_Condition]struct {})
	for paa in paas {
		starting[cast(^I_Condition)rawptr(paa)] = {}
	}
	all_conditions_needed := abstract_conditions_attachment_get_all_conditions_recursive(
		starting,
		nil,
	)
	delete(starting)
	return abstract_conditions_attachment_test_all_conditions_recursive(
		all_conditions_needed,
		nil,
		self.bridge,
	)
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifyFailure(PoliticalActionAttachment)
// Java: plays the failure sound, writes a transcript line, then (if the
// bridge has a resource loader) sends notifications to the acting player
// and the other players via the politics-text strings.
politics_delegate_notify_failure :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) {
	sound := i_delegate_bridge_get_sound_channel_broadcaster(self.bridge)
	headless_sound_channel_play_sound_for_all(sound, "political_action_failure", self.player)
	transcript_text := fmt.tprintf(
		"%s fails on action: %s",
		i_delegate_bridge_get_game_player(self.bridge).named.base.name,
		my_formatter_attachment_name_to_text(paa.name),
	)
	history_writer_add_child_to_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		transcript_text,
	)
	resource_loader := i_delegate_bridge_get_resource_loader(self.bridge)
	if resource_loader != nil {
		politics_text := politics_text_new(resource_loader)
		politics_delegate_send_notification(
			self,
			politics_text_get_notification_failure(politics_text, paa.text),
		)
		politics_delegate_notify_other_players(
			self,
			politics_text_get_notification_failure_others(politics_text, paa.text),
		)
	}
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifyOtherPlayers(String)
// Java:
//   if (!"NONE".equals(notification)) {
//     final Collection<GamePlayer> currentPlayer = new ArrayList<>();
//     currentPlayer.add(player);
//     final Collection<GamePlayer> otherPlayers = getData().getPlayerList().getPlayers();
//     otherPlayers.removeAll(currentPlayer);
//     bridge.getDisplayChannelBroadcaster()
//         .reportMessageToPlayers(otherPlayers, currentPlayer, notification, notification);
//   }
politics_delegate_notify_other_players :: proc(
	self: ^Politics_Delegate,
	notification: string,
) {
	if notification == "NONE" {
		return
	}
	current_player := make([dynamic]^Game_Player)
	append(&current_player, self.player)
	data := i_delegate_bridge_get_data(self.bridge)
	all_players := player_list_get_players(game_data_get_player_list(data))
	other_players := make([dynamic]^Game_Player)
	for p in all_players {
		if p != self.player {
			append(&other_players, p)
		}
	}
	display := i_delegate_bridge_get_display_channel_broadcaster(self.bridge)
	i_display_report_message_to_players(
		display,
		other_players,
		current_player,
		notification,
		notification,
	)
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifySuccess(PoliticalActionAttachment)
// Mirrors notifyFailure with the success sound clip and success notification
// strings; Java omits the transcript-line write here (only sound + messages).
politics_delegate_notify_success :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) {
	sound := i_delegate_bridge_get_sound_channel_broadcaster(self.bridge)
	headless_sound_channel_play_sound_for_all(sound, "political_action_successful", self.player)
	resource_loader := i_delegate_bridge_get_resource_loader(self.bridge)
	if resource_loader != nil {
		politics_text := politics_text_new(resource_loader)
		politics_delegate_send_notification(
			self,
			politics_text_get_notification_success(politics_text, paa.text),
		)
		politics_delegate_notify_other_players(
			self,
			politics_text_get_notification_success_others(politics_text, paa.text),
		)
	}
}

// games.strategy.triplea.delegate.PoliticsDelegate#sendNotification(String)
// Java: if (!"NONE".equals(text)) bridge.getRemotePlayer().reportMessage(text, text);
politics_delegate_send_notification :: proc(self: ^Politics_Delegate, text: string) {
	if text == "NONE" {
		return
	}
	remote := i_delegate_bridge_get_remote_player(self.bridge)
	i_remote_player_report_message(remote, text, text)
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifyNoValidAction()
// Java: sendNotification("This action isn't available anymore (this shouldn't happen!?!)");
politics_delegate_notify_no_valid_action :: proc(self: ^Politics_Delegate) {
	politics_delegate_send_notification(
		self,
		"This action isn't available anymore (this shouldn't happen!?!)",
	)
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifyPoliticsTurnedOff()
// Java: sendNotification("Politics is turned off in the game options");
politics_delegate_notify_politics_turned_off :: proc(self: ^Politics_Delegate) {
	politics_delegate_send_notification(self, "Politics is turned off in the game options")
}

// AbstractConditionsAttachment stores `chance` as the colon-joined string
// "<hitTarget>:<diceSides>" (defaulting to "1:1"). The Java helpers
// `getChanceToHit` / `getChanceDiceSides` are not flagged for porting on
// their own, so we parse the field locally here to keep
// `politics_delegate_action_roll_succeeds` faithful.
@(private = "file")
parse_chance_field :: proc(chance: string) -> (hit_target: i32, dice_sides: i32) {
	parts := strings.split(chance, ":", context.temp_allocator)
	if len(parts) >= 1 {
		v, ok := strconv.parse_int(parts[0])
		if ok {
			hit_target = i32(v)
		}
	}
	if len(parts) >= 2 {
		v, ok := strconv.parse_int(parts[1])
		if ok {
			dice_sides = i32(v)
		}
	}
	return
}

// Inlined from AbstractConditionsAttachment#changeChanceDecrementOrIncrementOnSuccessOrFailure.
// On success, decrement the hit target by `chance_decrement_on_success`; on
// failure, increment by `chance_increment_on_failure`. New value is clamped
// to [0, diceSides]; a no-op delta exits early without writing history.
// `history_child` controls whether the failure branch logs as a child event
// (true) or starts a new event (false). Success always starts a new event.
@(private = "file")
apply_chance_change :: proc(
	paa: ^Political_Action_Attachment,
	bridge: ^I_Delegate_Bridge,
	success: bool,
	history_child: bool,
) {
	delta: i32
	label: string
	if success {
		if paa.chance_decrement_on_success == 0 {
			return
		}
		delta = -paa.chance_decrement_on_success
		label = "Success"
	} else {
		if paa.chance_increment_on_failure == 0 {
			return
		}
		delta = paa.chance_increment_on_failure
		label = "Failure"
	}
	old_to_hit, dice_sides := parse_chance_field(paa.chance)
	new_to_hit := old_to_hit + delta
	if new_to_hit < 0 {
		new_to_hit = 0
	}
	if new_to_hit > dice_sides {
		new_to_hit = dice_sides
	}
	if new_to_hit == old_to_hit {
		return
	}
	new_chance := fmt.aprintf("%d:%d", new_to_hit, dice_sides)
	msg := fmt.tprintf(
		"%s changes chance for %s to %s",
		label,
		my_formatter_attachment_name_to_text(paa.name),
		new_chance,
	)
	writer := i_delegate_bridge_get_history_writer(bridge)
	if success || !history_child {
		i_delegate_history_writer_start_event(writer, msg)
	} else {
		history_writer_add_child_to_event(writer, msg)
	}
	new_chance_ptr := new(string)
	new_chance_ptr^ = new_chance
	i_delegate_bridge_add_change(
		bridge,
		change_factory_attachment_property_change(
			cast(^I_Attachment)rawptr(paa),
			rawptr(new_chance_ptr),
			"chance",
		),
	)
}

// games.strategy.triplea.delegate.PoliticsDelegate#actionRollSucceeds(PoliticalActionAttachment)
// Java:
//   final int hitTarget = paa.getChanceToHit();
//   final int diceSides = paa.getChanceDiceSides();
//   if (diceSides <= 0 || hitTarget >= diceSides) { ...auto-success... }
//   else if (hitTarget <= 0) { ...auto-failure... }
//   final int rollResult = bridge.getRandom(diceSides, player, NONCOMBAT, ann) + 1;
//   final boolean success = rollResult <= hitTarget;
//   ...history line + sendNotification + changeChance...
politics_delegate_action_roll_succeeds :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) -> bool {
	hit_target, dice_sides := parse_chance_field(paa.chance)
	if dice_sides <= 0 || hit_target >= dice_sides {
		apply_chance_change(paa, self.bridge, true, true)
		return true
	} else if hit_target <= 0 {
		apply_chance_change(paa, self.bridge, false, true)
		return false
	}
	annotation := fmt.tprintf(
		"Attempting the Political Action: %s",
		my_formatter_attachment_name_to_text(paa.name),
	)
	rolls := i_delegate_bridge_get_random(
		self.bridge,
		dice_sides,
		1,
		self.player,
		I_Random_Stats_Dice_Type.NONCOMBAT,
		annotation,
	)
	roll_result := rolls[0] + 1
	success := roll_result <= hit_target
	result_word := "Failure!"
	if success {
		result_word = "Success!"
	}
	notification_message := fmt.aprintf(
		"rolling (%d out of %d) result: %d = %s",
		hit_target,
		dice_sides,
		roll_result,
		result_word,
	)
	history_writer_add_child_to_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		fmt.tprintf(
			"%s : %s",
			my_formatter_attachment_name_to_text(paa.name),
			notification_message,
		),
	)
	apply_chance_change(paa, self.bridge, success, true)
	politics_delegate_send_notification(self, notification_message)
	return success
}

// games.strategy.triplea.delegate.PoliticsDelegate#checkEnoughMoney(PoliticalActionAttachment)
// Java: return bridge.getGamePlayer().getResources().has(paa.getCostResources());
politics_delegate_check_enough_money :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) -> bool {
	gp := i_delegate_bridge_get_game_player(self.bridge)
	return resource_collection_has(game_player_get_resources(gp), &paa.cost_resources)
}

// games.strategy.triplea.delegate.PoliticsDelegate#lambda$actionIsAccepted$0
// Java lambda: politicsText -> politicsText.getAcceptanceQuestion(paa.getText())
// Captured: paa. Argument: politicsText. Returns the acceptance-question
// string keyed off the action's text id.
politics_delegate_lambda_action_is_accepted_0 :: proc(
	paa: ^Political_Action_Attachment,
	politics_text: ^Politics_Text,
) -> string {
	return politics_text_get_acceptance_question(politics_text, paa.text)
}

// games.strategy.triplea.delegate.PoliticsDelegate#lambda$givesBackOriginalTerritories$3
// Java lambda body inside OriginalOwnerTracker.getOriginalOwner(t).ifPresent:
//   if (originalOwner.equals(p2)) {
//     change.add(ChangeFactory.changeOwner(t, originalOwner));
//   }
// Captured: p2 (the candidate original-owner player) and change (the
// CompositeChange being accumulated). Argument: territory t and the
// originalOwner the tracker reports. Decompiled lambda parameter order is
// (p2, change, t, originalOwner).
politics_delegate_lambda_gives_back_original_territories_3 :: proc(
	p2: ^Game_Player,
	change: ^Composite_Change,
	t: ^Territory,
	original_owner: ^Game_Player,
) {
	if original_owner == p2 {
		composite_change_add(change, change_factory_change_owner(t, original_owner))
	}
}

// games.strategy.triplea.delegate.PoliticsDelegate#notifyMoney(PoliticalActionAttachment)
// Java: final String cost = ResourceCollection.toString(paa.getCostResources(), getData());
//       sendNotification("You don't have enough money, you need " + cost + " to perform this action");
politics_delegate_notify_money :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) {
	cost := resource_collection_to_string(
		&paa.cost_resources,
		i_delegate_bridge_get_data(self.bridge),
	)
	politics_delegate_send_notification(
		self,
		fmt.tprintf("You don't have enough money, you need %s to perform this action", cost),
	)
}

// games.strategy.triplea.delegate.PoliticsDelegate#actionIsAccepted(PoliticalActionAttachment)
// Java: builds a Predicate<PoliticalActionAttachment> that is true when the
// action enters an allied chain or enters/leaves war, then asks the relevant
// remote players whether they accept. Allies of `player` (and allies of each
// player in actionAccept) must also be polled when the action would change
// alliance/war status and alliances chain together.
politics_delegate_action_is_accepted :: proc(
	self: ^Politics_Delegate,
	paa: ^Political_Action_Attachment,
) -> bool {
	data := i_delegate_bridge_get_data(self.bridge)
	rt := game_data_get_relationship_tracker(data)

	// Inline the three-way OR predicate over paa's relationship changes:
	//   (current !alliedAndChain && new alliedAndChain) ||
	//   (current !atWar && new atWar) ||
	//   (current atWar && new !atWar)
	allied_pred, allied_ctx := matches_relationship_type_is_allied_and_alliances_can_chain_together()
	war_pred, war_ctx := matches_relationship_type_is_at_war()
	into_allied_chain_or_into_or_out_of_war := false
	for change in political_action_attachment_get_relationship_changes(paa) {
		current_type := relationship_tracker_get_relationship_type(rt, change.player1, change.player2)
		new_type := change.relationship_type
		cur_allied := allied_pred(allied_ctx, current_type)
		new_allied := allied_pred(allied_ctx, new_type)
		cur_war := war_pred(war_ctx, current_type)
		new_war := war_pred(war_ctx, new_type)
		if (!cur_allied && new_allied) || (!cur_war && new_war) || (cur_war && !new_war) {
			into_allied_chain_or_into_or_out_of_war = true
			break
		}
	}

	// acceptanceQuestion: bridge.getResourceLoader().map(PoliticsText::new)
	//     .map(politicsText -> politicsText.getAcceptanceQuestion(paa.getText()))
	//     .orElse("")
	acceptance_question := ""
	resource_loader := i_delegate_bridge_get_resource_loader(self.bridge)
	if resource_loader != nil {
		politics_text := politics_text_new(resource_loader)
		acceptance_question = politics_delegate_lambda_action_is_accepted_0(paa, politics_text)
	}

	if !properties_get_alliances_can_chain_together(game_data_get_properties(data)) ||
	   !into_allied_chain_or_into_or_out_of_war {
		for p in paa.action_accept {
			remote := i_delegate_bridge_get_remote_player(self.bridge, p)
			if !player_accept_action(remote, self.player, acceptance_question, true) {
				return false
			}
		}
		return true
	}

	// Otherwise: include allies of `player` and allies of each member of
	// actionAccept; LinkedHashSet preserves insertion order.
	all_players := player_list_get_players(game_data_get_player_list(data))
	players_who_need_to_accept: [dynamic]^Game_Player
	seen := make(map[^Game_Player]struct {})
	defer delete(seen)
	for p in paa.action_accept {
		if _, ok := seen[p]; !ok {
			seen[p] = {}
			append(&players_who_need_to_accept, p)
		}
	}
	pred1, ctx1 := matches_is_allied_and_alliances_can_chain_together(self.player)
	for q in all_players {
		if pred1(ctx1, q) {
			if _, ok := seen[q]; !ok {
				seen[q] = {}
				append(&players_who_need_to_accept, q)
			}
		}
	}
	for p in paa.action_accept {
		pred2, ctx2 := matches_is_allied_and_alliances_can_chain_together(p)
		for q in all_players {
			if pred2(ctx2, q) {
				if _, ok := seen[q]; !ok {
					seen[q] = {}
					append(&players_who_need_to_accept, q)
				}
			}
		}
	}
	// removeAll(paa.getActionAccept())
	exclude := make(map[^Game_Player]struct {})
	defer delete(exclude)
	for p in paa.action_accept {
		exclude[p] = {}
	}
	filtered: [dynamic]^Game_Player
	for q in players_who_need_to_accept {
		if _, ex := exclude[q]; !ex {
			append(&filtered, q)
		}
	}
	delete(players_who_need_to_accept)

	for p in filtered {
		action_text: string
		if acceptance_question == "NONE" {
			action_text = fmt.tprintf(
				"%s wants to take the following action: %s \r\n Do you approve?",
				self.player.named.base.name,
				my_formatter_attachment_name_to_text(paa.name),
			)
		} else {
			accept_list: [dynamic]^Default_Named
			defer delete(accept_list)
			for ap in paa.action_accept {
				append(&accept_list, cast(^Default_Named)ap)
			}
			action_text = fmt.tprintf(
				"%s wants to take the following action: %s.  Do you approve? \r\n\r\n %s will ask %s, the following question: \r\n %s",
				self.player.named.base.name,
				my_formatter_attachment_name_to_text(paa.name),
				self.player.named.base.name,
				my_formatter_default_named_to_text_list_simple(accept_list),
				acceptance_question,
			)
		}
		remote := i_delegate_bridge_get_remote_player(self.bridge, p)
		if !player_accept_action(remote, self.player, action_text, true) {
			delete(filtered)
			return false
		}
	}
	delete(filtered)
	for p in paa.action_accept {
		remote := i_delegate_bridge_get_remote_player(self.bridge, p)
		if !player_accept_action(remote, self.player, acceptance_question, true) {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.PoliticsDelegate#chainAlliancesTogether(IDelegateBridge)
// Static helper. With chain-alliances enabled, propagates ally-of-ally
// edges into direct allied relationships (using the single allied type
// that has canAlliancesChainTogether), then the same for war edges
// (using the relationship type whose attachment is the default war
// position). Each new edge is recorded in the history and the battle
// tracker's per-turn relationship-change list.
politics_delegate_chain_alliances_together :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_alliances_can_chain_together(game_data_get_properties(data)) {
		return
	}
	all_types := relationship_type_list_get_all_relationship_types(
		game_data_get_relationship_type_list(data),
	)
	allied_type: ^Relationship_Type
	war_type: ^Relationship_Type
	for type in all_types {
		rta := relationship_type_get_relationship_type_attachment(type)
		if relationship_type_attachment_is_default_war_position(rta) {
			war_type = type
		} else if relationship_type_attachment_can_alliances_chain_together(rta) {
			allied_type = type
		}
	}
	if allied_type == nil {
		return
	}
	tracker := game_data_get_relationship_tracker(data)
	bt := abstract_move_delegate_get_battle_tracker(data)
	writer := i_delegate_bridge_get_history_writer(bridge)
	players := player_list_get_players(game_data_get_player_list(data))
	// First do alliances.
	for p1 in players {
		p1_new_allies := make(map[^Game_Player]struct {})
		defer delete(p1_new_allies)
		pred_a1, ctx_a1 := matches_is_allied_and_alliances_can_chain_together(p1)
		p1_allied_with: [dynamic]^Game_Player
		defer delete(p1_allied_with)
		for q in players {
			if pred_a1(ctx_a1, q) {
				append(&p1_allied_with, q)
			}
		}
		for p2 in p1_allied_with {
			pred_a2, ctx_a2 := matches_is_allied_and_alliances_can_chain_together(p2)
			for q in players {
				if pred_a2(ctx_a2, q) {
					p1_new_allies[q] = {}
				}
			}
		}
		for q in p1_allied_with {
			delete_key(&p1_new_allies, q)
		}
		delete_key(&p1_new_allies, p1)
		for p3 in p1_new_allies {
			current := relationship_tracker_get_relationship_type(tracker, p1, p3)
			if current != allied_type {
				i_delegate_bridge_add_change(
					bridge,
					change_factory_relationship_change(p1, p3, current, allied_type),
				)
				history_writer_add_child_to_event(
					writer,
					fmt.tprintf(
						"%s and %s are joined together in an %s treaty",
						p1.named.base.name,
						p3.named.base.name,
						allied_type.named.base.name,
					),
				)
				battle_tracker_add_relationship_changes_this_turn(
					bt,
					p1,
					p3,
					current,
					allied_type,
				)
			}
		}
	}
	// Now war.
	if war_type == nil {
		return
	}
	for p1 in players {
		p1_new_war := make(map[^Game_Player]struct {})
		defer delete(p1_new_war)
		pred_w, ctx_w := matches_is_at_war(p1)
		p1_war_with: [dynamic]^Game_Player
		defer delete(p1_war_with)
		for q in players {
			if pred_w(ctx_w, q) {
				append(&p1_war_with, q)
			}
		}
		pred_a, ctx_a := matches_is_allied_and_alliances_can_chain_together(p1)
		p1_allied_with: [dynamic]^Game_Player
		defer delete(p1_allied_with)
		for q in players {
			if pred_a(ctx_a, q) {
				append(&p1_allied_with, q)
			}
		}
		for p2 in p1_allied_with {
			pred_w2, ctx_w2 := matches_is_at_war(p2)
			for q in players {
				if pred_w2(ctx_w2, q) {
					p1_new_war[q] = {}
				}
			}
		}
		for q in p1_war_with {
			delete_key(&p1_new_war, q)
		}
		delete_key(&p1_new_war, p1)
		for p3 in p1_new_war {
			current := relationship_tracker_get_relationship_type(tracker, p1, p3)
			if current != war_type {
				i_delegate_bridge_add_change(
					bridge,
					change_factory_relationship_change(p1, p3, current, war_type),
				)
				history_writer_add_child_to_event(
					writer,
					fmt.tprintf(
						"%s and %s declare %s on each other",
						p1.named.base.name,
						p3.named.base.name,
						war_type.named.base.name,
					),
				)
				battle_tracker_add_relationship_changes_this_turn(
					bt,
					p1,
					p3,
					current,
					war_type,
				)
			}
		}
	}
}

// games.strategy.triplea.delegate.PoliticsDelegate#getMyselfOutOfAlliance(
//     PoliticalActionAttachment, GamePlayer, IDelegateBridge)
// Static helper. When `player` is leaving an allied-and-chainable
// relationship, mirror the change against every other ally of `player`
// so the chain stays consistent.
politics_delegate_get_myself_out_of_alliance :: proc(
	paa: ^Political_Action_Attachment,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_alliances_can_chain_together(game_data_get_properties(data)) {
		return
	}
	players := player_list_get_players(game_data_get_player_list(data))
	pred_a, ctx_a := matches_is_allied_and_alliances_can_chain_together(player)
	p1_allied_with: [dynamic]^Game_Player
	defer delete(p1_allied_with)
	for q in players {
		if pred_a(ctx_a, q) {
			append(&p1_allied_with, q)
		}
	}
	for i := 0; i < len(p1_allied_with); i += 1 {
		if p1_allied_with[i] == player {
			ordered_remove(&p1_allied_with, i)
			break
		}
	}
	change := composite_change_new()
	tracker := game_data_get_relationship_tracker(data)
	bt := abstract_move_delegate_get_battle_tracker(data)
	writer := i_delegate_bridge_get_history_writer(bridge)
	pred_chain, ctx_chain := matches_relationship_type_is_allied_and_alliances_can_chain_together()
	for relationship_change in political_action_attachment_get_relationship_changes(paa) {
		p1 := relationship_change.player1
		p2 := relationship_change.player2
		if !(p1 == player || p2 == player) {
			continue
		}
		other_player := p2 if p1 == player else p1
		found := false
		for q in p1_allied_with {
			if q == other_player {
				found = true
				break
			}
		}
		if !found {
			continue
		}
		current_type := relationship_tracker_get_relationship_type(tracker, p1, p2)
		new_type := relationship_change.relationship_type
		if pred_chain(ctx_chain, current_type) && !pred_chain(ctx_chain, new_type) {
			for p3 in p1_allied_with {
				current_other := relationship_tracker_get_relationship_type(tracker, p3, player)
				if current_other != new_type {
					composite_change_add(
						change,
						change_factory_relationship_change(p3, player, current_other, new_type),
					)
					history_writer_add_child_to_event(
						writer,
						fmt.tprintf(
							"%s and %s sign a %s treaty",
							player.named.base.name,
							p3.named.base.name,
							new_type.named.base.name,
						),
					)
					battle_tracker_add_relationship_changes_this_turn(
						bt,
						p3,
						player,
						current_other,
						new_type,
					)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// games.strategy.triplea.delegate.PoliticsDelegate#getNeutralOutOfWarWithAllies(
//     PoliticalActionAttachment, GamePlayer, IDelegateBridge)
// Static helper. When `player` is exiting a war relationship, propagate
// the new (non-war) relationship to every (ally-of-player × ally-of-other)
// pair that is currently at war so the chained alliance graph is no
// longer at war with the freshly-non-war side.
politics_delegate_get_neutral_out_of_war_with_allies :: proc(
	paa: ^Political_Action_Attachment,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_alliances_can_chain_together(game_data_get_properties(data)) {
		return
	}
	players := player_list_get_players(game_data_get_player_list(data))
	pred_a, ctx_a := matches_is_allied_and_alliances_can_chain_together(player)
	p1_allied_with: [dynamic]^Game_Player
	defer delete(p1_allied_with)
	for q in players {
		if pred_a(ctx_a, q) {
			append(&p1_allied_with, q)
		}
	}
	change := composite_change_new()
	tracker := game_data_get_relationship_tracker(data)
	bt := abstract_move_delegate_get_battle_tracker(data)
	writer := i_delegate_bridge_get_history_writer(bridge)
	war_pred, war_ctx := matches_relationship_type_is_at_war()
	for relationship_change in political_action_attachment_get_relationship_changes(paa) {
		p1 := relationship_change.player1
		p2 := relationship_change.player2
		if !(p1 == player || p2 == player) {
			continue
		}
		other_player := p2 if p1 == player else p1
		current_type := relationship_tracker_get_relationship_type(tracker, p1, p2)
		new_type := relationship_change.relationship_type
		if war_pred(war_ctx, current_type) && !war_pred(war_ctx, new_type) {
			pred_other, ctx_other := matches_is_allied_and_alliances_can_chain_together(other_player)
			other_players_allied_with: [dynamic]^Game_Player
			defer delete(other_players_allied_with)
			for q in players {
				if pred_other(ctx_other, q) {
					append(&other_players_allied_with, q)
				}
			}
			contains_other := false
			for q in other_players_allied_with {
				if q == other_player {
					contains_other = true
					break
				}
			}
			if !contains_other {
				append(&other_players_allied_with, other_player)
			}
			contains_player := false
			for q in p1_allied_with {
				if q == player {
					contains_player = true
					break
				}
			}
			if !contains_player {
				append(&p1_allied_with, player)
			}
			for p3 in p1_allied_with {
				for p4 in other_players_allied_with {
					current_other := relationship_tracker_get_relationship_type(tracker, p3, p4)
					if current_other != new_type && war_pred(war_ctx, current_other) {
						composite_change_add(
							change,
							change_factory_relationship_change(p3, p4, current_other, new_type),
						)
						history_writer_add_child_to_event(
							writer,
							fmt.tprintf(
								"%s and %s sign a %s treaty",
								p3.named.base.name,
								p4.named.base.name,
								new_type.named.base.name,
							),
						)
						battle_tracker_add_relationship_changes_this_turn(
							bt,
							p3,
							p4,
							current_other,
							new_type,
						)
					}
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

