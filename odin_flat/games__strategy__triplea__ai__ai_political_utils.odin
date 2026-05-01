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
