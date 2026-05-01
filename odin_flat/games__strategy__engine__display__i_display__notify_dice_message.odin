package game

Notify_Dice_Message :: struct {
	step_name:               string,
	dice_roll_data:          [dynamic]^I_Display_Die_Roll_Data,
	dice_roll_hits:          i32,
	dice_roll_expected_hits: f64,
	player_name:             string,
}

// games.strategy.engine.display.IDisplay$NotifyDiceMessage#<init>(games.strategy.triplea.delegate.DiceRoll,java.lang.String,java.lang.String)
notify_dice_message_new :: proc(
	dice_roll: ^Dice_Roll,
	step_name: string,
	player_name: string,
) -> ^Notify_Dice_Message {
	self := new(Notify_Dice_Message)
	self.step_name = step_name
	self.dice_roll_expected_hits = dice_roll_get_expected_hits(dice_roll)
	self.dice_roll_hits = dice_roll_get_hits(dice_roll)
	self.dice_roll_data = make([dynamic]^I_Display_Die_Roll_Data, 0, len(dice_roll.rolls))
	for d in dice_roll.rolls {
		append(&self.dice_roll_data, make_I_Display_Die_Roll_Data(d))
	}
	self.player_name = player_name
	return self
}

// games.strategy.engine.display.IDisplay$NotifyDiceMessage#accept(games.strategy.engine.display.IDisplay)
notify_dice_message_accept :: proc(self: ^Notify_Dice_Message, display: ^I_Display) {
	rolls := die_roll_data_to_die_list(self.dice_roll_data)
	dice_roll := dice_roll_new(rolls, self.dice_roll_hits, self.dice_roll_expected_hits, self.player_name)
	i_display_notify_dice(display, dice_roll, self.step_name)
}
