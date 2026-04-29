package game

// Java owner: games.strategy.triplea.odds.calculator.OrderOfLossesInputPanel
// Swing JPanel; UI widget fields omitted. Non-UI state preserved.

OOL_SEPARATOR :: ';'
OOL_AMOUNT_DESCRIPTOR :: '^'
OOL_ALL :: "*"

Order_Of_Losses_Input_Panel :: struct {
	land:           bool,
	attacker_order: string,
	defender_order: string,
	// data:                ^Game_Data,
	// ui_context:          ^Ui_Context,
	// attacker_categories: [dynamic]^Unit_Category,
	// defender_categories: [dynamic]^Unit_Category,
}

