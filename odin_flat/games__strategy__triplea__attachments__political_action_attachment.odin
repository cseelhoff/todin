package game

import "core:strings"

Political_Action_Attachment :: struct {
	using abstract_user_action_attachment: Abstract_User_Action_Attachment,
	relationship_change: [dynamic]string,
}

Political_Action_Attachment_Relationship_Change :: struct {
	player1: ^Game_Player,
	player2: ^Game_Player,
	relationship_type: ^Relationship_Type,
}

// Java: public static Collection<PoliticalActionAttachment> getPoliticalActionAttachments(GamePlayer player)
// Iterates the player's attachment map, keeps the entries whose name begins
// with `Constants.POLITICALACTION_ATTACHMENT_PREFIX` ("politicalActionAttachment"),
// and returns them as PoliticalActionAttachments. The Java filter also runs
// `PoliticalActionAttachment.class::isInstance`; in this port the map value
// is an opaque ^I_Attachment whose concrete type is determined by the
// attachment-name convention, so the prefix check is the operative test
// (every attachment registered under that prefix is a Political_Action_Attachment).
political_action_attachment_get_political_action_attachments :: proc(
	player: ^Game_Player,
) -> [dynamic]^Political_Action_Attachment {
	result: [dynamic]^Political_Action_Attachment
	attachments := named_attachable_get_attachments(&player.named_attachable)
	for name, att in attachments {
		if strings.has_prefix(name, "politicalActionAttachment") {
			append(&result, cast(^Political_Action_Attachment)att)
		}
	}
	return result
}

// Java: private List<String> getRelationshipChange()
// Mirrors `getListProperty(relationshipChange)`: returns the list, or an
// empty list if it is unset. Odin's nil [dynamic]string iterates as empty,
// so the helper is a pass-through.
political_action_attachment_get_relationship_change :: proc(
	self: ^Political_Action_Attachment,
) -> [dynamic]string {
	return default_attachment_get_list_property(self.relationship_change)
}
