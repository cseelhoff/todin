package game

import "core:fmt"
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

// Java: public List<RelationshipChange> getRelationshipChanges()
//   return getRelationshipChange().stream()
//       .map(this::parseRelationshipChange)
//       .collect(Collectors.toList());
// Inlines the private `parseRelationshipChange(String)` helper: each entry of
// `relationshipChange` is a "player1:player2:relationType" triple split on ':'
// (Java asserts length == 3); the two players are resolved against the player
// list and the relationship type against the relationship-type list. Java's
// `getPlayerByName` (DefaultAttachment) and `getData()` are inlined here as
// they are elsewhere in the port. An unknown player or relationship-type name
// would cause Java to throw IllegalStateException; the Odin port preserves
// the failure mode via panic.
political_action_attachment_get_relationship_changes :: proc(
	self: ^Political_Action_Attachment,
) -> [dynamic]^Political_Action_Attachment_Relationship_Change {
	result: [dynamic]^Political_Action_Attachment_Relationship_Change
	encoded := political_action_attachment_get_relationship_change(self)
	game_data := game_data_component_get_data(&self.game_data_component)
	player_list := game_data_get_player_list(game_data)
	rel_type_list := game_data_get_relationship_type_list(game_data)
	for entry in encoded {
		tokens := default_attachment_split_on_colon(entry)
		defer delete(tokens)
		assert(len(tokens) == 3)
		p1 := player_list_get_player_id(player_list, tokens[0])
		if p1 == nil {
			err := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(err)
			fmt.panicf(
				"Invalid relationshipChange declaration: %s \n first player: %s unknown%s",
				entry,
				tokens[0],
				err,
			)
		}
		p2 := player_list_get_player_id(player_list, tokens[1])
		if p2 == nil {
			err := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(err)
			fmt.panicf(
				"Invalid relationshipChange declaration: %s \n second player: %s unknown%s",
				entry,
				tokens[1],
				err,
			)
		}
		change := new(Political_Action_Attachment_Relationship_Change)
		change.player1 = p1
		change.player2 = p2
		change.relationship_type = relationship_type_list_get_relationship_type(
			rel_type_list,
			tokens[2],
		)
		append(&result, change)
	}
	return result
}

// Java: public static Collection<PoliticalActionAttachment> getValidActions(
//     final GamePlayer player,
//     final Map<ICondition, Boolean> testedConditions,
//     final GameState data)
//   if (!Properties.getUsePolitics(data.getProperties()) || !player.amNotDeadYet()) {
//     return new ArrayList<>();
//   }
//   return CollectionUtils.getMatches(
//       getPoliticalActionAttachments(player),
//       Matches.politicalActionAffectsAtLeastOneAlivePlayer(player)
//           .and(Matches.abstractUserActionAttachmentCanBeAttempted(testedConditions)));
// The two project Matches helpers expose `(proc(rawptr, ^T) -> bool, rawptr)`
// pairs; rather than bridge them through `collection_utils_get_matches`
// (whose signature is `[dynamic]rawptr` + `proc(rawptr) -> bool` and
// cannot carry the captured player / tested-conditions context), we
// inline the filter, mirroring the pattern used by other attachment
// procs in this package (see `canal_attachment_get_excluded_units`).
political_action_attachment_get_valid_actions :: proc(
	player: ^Game_Player,
	tested_conditions: map[^I_Condition]bool,
	data: ^Game_State,
) -> [dynamic]^Political_Action_Attachment {
	result: [dynamic]^Political_Action_Attachment
	if !properties_get_use_politics(game_state_get_properties(data)) ||
	   !game_player_am_not_dead_yet(player) {
		return result
	}
	candidates := political_action_attachment_get_political_action_attachments(player)
	affects_pred, affects_ctx := matches_political_action_affects_at_least_one_alive_player(player)
	can_be_attempted_pred, can_be_attempted_ctx := matches_abstract_user_action_attachment_can_be_attempted(
		tested_conditions,
	)
	for paa in candidates {
		if !affects_pred(affects_ctx, paa) {
			continue
		}
		if !can_be_attempted_pred(can_be_attempted_ctx, &paa.abstract_user_action_attachment) {
			continue
		}
		append(&result, paa)
	}
	return result
}
