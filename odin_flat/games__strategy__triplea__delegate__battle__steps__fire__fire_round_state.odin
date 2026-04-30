package game

Fire_Round_State :: struct {
	dice:       ^Dice_Roll,
	casualties: ^Casualty_Details,
}

fire_round_state_new :: proc() -> ^Fire_Round_State {
	self := new(Fire_Round_State)
	return self
}

fire_round_state_get_dice :: proc(self: ^Fire_Round_State) -> ^Dice_Roll {
	return self.dice
}

fire_round_state_get_casualties :: proc(self: ^Fire_Round_State) -> ^Casualty_Details {
	return self.casualties
}

fire_round_state_set_dice :: proc(self: ^Fire_Round_State, dice: ^Dice_Roll) {
	self.dice = dice
}

fire_round_state_set_casualties :: proc(self: ^Fire_Round_State, casualties: ^Casualty_Details) {
	self.casualties = casualties
}
