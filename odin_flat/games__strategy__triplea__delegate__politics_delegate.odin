package game

import "core:fmt"

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

