package game

// Java owner: games.strategy.triplea.ai.AiPoliticalUtils
// Utility class with only static methods; no instance state.

Ai_Political_Utils :: struct {}

ai_political_utils_political_action_has_no_resource_cost :: proc() -> proc(^Political_Action_Attachment) -> bool {
	return proc(paa: ^Political_Action_Attachment) -> bool {
		return len(paa.cost_resources) == 0
	}
}

// Java: private static boolean isFree(final PoliticalActionAttachment nextAction)
ai_political_utils_is_free :: proc(next_action: ^Political_Action_Attachment) -> bool {
	return len(next_action.cost_resources) == 0
}

// Java: private static boolean goesTowardsWar(PoliticalActionAttachment, GamePlayer p0, GameState data)
// Returns true iff any RelationshipChange in nextAction transitions a relationship
// involving p0 from a Neutral relationship to a War relationship.
ai_political_utils_goes_towards_war :: proc(
	next_action: ^Political_Action_Attachment,
	p0: ^Game_Player,
	data: ^Game_State,
) -> bool {
	relationship_changes := political_action_attachment_get_relationship_changes(next_action)
	for relationship_change in relationship_changes {
		p1 := relationship_change.player1
		p2 := relationship_change.player2
		// only continue if p1 or p2 is the AI
		if p0 == p1 || p0 == p2 {
			current_type := relationship_tracker_get_relationship_type(
				game_state_get_relationship_tracker(data),
				p1,
				p2,
			)
			new_type := relationship_change.relationship_type
			if relationship_type_attachment_is_neutral(
				   relationship_type_get_relationship_type_attachment(current_type),
			   ) &&
			   relationship_type_attachment_is_war(
				   relationship_type_get_relationship_type_attachment(new_type),
			   ) {
				return true
			}
		}
	}
	return false
}

// Java: private static boolean awayFromAlly(PoliticalActionAttachment, GamePlayer p0, GameState data)
// Returns true iff any RelationshipChange in nextAction transitions a relationship
// involving p0 from an Allied relationship to a Neutral or War relationship.
ai_political_utils_away_from_ally :: proc(
	next_action: ^Political_Action_Attachment,
	p0: ^Game_Player,
	data: ^Game_State,
) -> bool {
	relationship_changes := political_action_attachment_get_relationship_changes(next_action)
	for relationship_change in relationship_changes {
		p1 := relationship_change.player1
		p2 := relationship_change.player2
		// only continue if p1 or p2 is the AI
		if p0 == p1 || p0 == p2 {
			current_type := relationship_tracker_get_relationship_type(
				game_state_get_relationship_tracker(data),
				p1,
				p2,
			)
			new_type := relationship_change.relationship_type
			new_attachment := relationship_type_get_relationship_type_attachment(new_type)
			if relationship_type_attachment_is_allied(
				   relationship_type_get_relationship_type_attachment(current_type),
			   ) &&
			   (relationship_type_attachment_is_neutral(new_attachment) ||
					   relationship_type_attachment_is_war(new_attachment)) {
				return true
			}
		}
	}
	return false
}

// Java: private static boolean wantToPerFormActionTowardsWar(PoliticalActionAttachment, GamePlayer, GameState)
ai_political_utils_want_to_perform_action_towards_war :: proc(
	next_action: ^Political_Action_Attachment,
	game_player: ^Game_Player,
	data: ^Game_State,
) -> bool {
	return(
		ai_political_utils_is_free(next_action) &&
		ai_political_utils_goes_towards_war(next_action, game_player, data) \
	)
}
