package game

Notify_Dice_Message :: struct {
	step_name:               string,
	dice_roll_data:          [dynamic]^I_Display_Die_Roll_Data,
	dice_roll_hits:          i32,
	dice_roll_expected_hits: f64,
	player_name:             string,
}

notify_dice_message_new :: proc(
	step_name: string,
	dice_roll_data: [dynamic]^I_Display_Die_Roll_Data,
	dice_roll_hits: i32,
	dice_roll_expected_hits: f64,
	player_name: string,
) -> ^Notify_Dice_Message {
	self := new(Notify_Dice_Message)
	self.step_name = step_name
	self.dice_roll_data = dice_roll_data
	self.dice_roll_hits = dice_roll_hits
	self.dice_roll_expected_hits = dice_roll_expected_hits
	self.player_name = player_name
	return self
}
