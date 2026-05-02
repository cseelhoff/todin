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

