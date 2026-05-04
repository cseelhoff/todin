package game

import "core:fmt"

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.ProPoliticsAi

// Pro politics AI.
Pro_Politics_Ai :: struct {
	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,
}

pro_politics_ai_new :: proc(ai: ^Abstract_Pro_Ai) -> ^Pro_Politics_Ai {
	self := new(Pro_Politics_Ai)
	self.calc = abstract_pro_ai_get_calc(ai)
	self.pro_data = abstract_pro_ai_get_pro_data(ai)
	return self
}

// Java: void doActions(List<PoliticalActionAttachment> actions)
// Resolves the politics delegate from the cached ProData, then for each
// requested action logs a debug line and dispatches the attempt through
// `politics_delegate_attempt_action` (which performs the cost/conditions
// checks and applies the relationship change on success).
pro_politics_ai_do_actions :: proc(
	self: ^Pro_Politics_Ai,
	actions: [dynamic]^Political_Action_Attachment,
) {
	data := pro_data_get_data(self.pro_data)
	politics_delegate := game_data_get_politics_delegate(data)
	for action in actions {
		pro_logger_debug(fmt.tprintf("Performing action: %s", action.name))
		politics_delegate_attempt_action(politics_delegate, action)
	}
}

