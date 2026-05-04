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

// Java: public static List<PoliticalActionAttachment> getPoliticalActionsTowardsWar(
//           GamePlayer gamePlayer, Map<ICondition, Boolean> testedConditions, GameState data)
ai_political_utils_get_political_actions_towards_war :: proc(
	game_player: ^Game_Player,
	tested_conditions: map[^I_Condition]bool,
	data: ^Game_State,
) -> [dynamic]^Political_Action_Attachment {
	acceptable_actions: [dynamic]^Political_Action_Attachment
	valid_actions := political_action_attachment_get_valid_actions(game_player, tested_conditions, data)
	for next_action in valid_actions {
		if ai_political_utils_want_to_perform_action_towards_war(next_action, game_player, data) {
			append(&acceptable_actions, next_action)
		}
	}
	return acceptable_actions
}

// Java: private static boolean isAcceptableCost(
//           PoliticalActionAttachment nextAction, GamePlayer player, GameState data)
// If we have 21 or more PUs and the cost of the action is 10% or less of our
// total money, then it is an acceptable price.
ai_political_utils_is_acceptable_cost :: proc(
	next_action: ^Political_Action_Attachment,
	player: ^Game_Player,
	data: ^Game_State,
) -> bool {
	owned := game_map_get_territories_owned_by(game_state_get_map(data), player)
	defer delete(owned)
	production := f32(abstract_end_turn_delegate_get_production(owned, data))
	r := resource_list_get_resource_or_throw(game_state_get_resource_list(data), "PUs")
	cost: i32 = next_action.cost_resources[r]
	return production >= 21 && f32(cost) <= (production / 10)
}
