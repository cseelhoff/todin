package game

// games.strategy.engine.display.IDisplay$NotifyDiceMessage$NotifyDiceMessageBuilder
// Lombok @Builder generated builder for NotifyDiceMessage.

I_Display_Notify_Dice_Message_Notify_Dice_Message_Builder :: struct {
	step_name:               string,
	dice_roll_data:          [dynamic]^I_Display_Die_Roll_Data,
	dice_roll_hits:          i32,
	dice_roll_expected_hits: f64,
	player_name:             string,
}

make_I_Display_Notify_Dice_Message_Notify_Dice_Message_Builder :: proc() -> ^I_Display_Notify_Dice_Message_Notify_Dice_Message_Builder {
	self := new(I_Display_Notify_Dice_Message_Notify_Dice_Message_Builder)
	return self
}

