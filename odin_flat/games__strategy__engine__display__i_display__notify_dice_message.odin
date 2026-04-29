package game

Notify_Dice_Message :: struct {
	step_name:               string,
	dice_roll_data:          [dynamic]^I_Display_Die_Roll_Data,
	dice_roll_hits:          i32,
	dice_roll_expected_hits: f64,
	player_name:             string,
}
