package game

Abstract_Trigger_Attachment :: struct {
	using parent: Abstract_Conditions_Attachment,
	uses: i32,
	used_this_round: bool,
	notification: string,
	when_triggers: [dynamic]^Tuple(string, string),
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.AbstractTriggerAttachment

