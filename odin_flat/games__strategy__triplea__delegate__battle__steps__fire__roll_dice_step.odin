package game

Roll_Dice_Step :: struct {
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	roll_dice:        proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
}

roll_dice_step_new :: proc(
	battle_state: ^Battle_State,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	roll_dice: proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
) -> ^Roll_Dice_Step {
	self := new(Roll_Dice_Step)
	self.battle_state = battle_state
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.roll_dice = roll_dice
	return self
}

roll_dice_step_get_battle_state :: proc(self: ^Roll_Dice_Step) -> ^Battle_State {
	return self.battle_state
}

roll_dice_step_get_firing_group :: proc(self: ^Roll_Dice_Step) -> ^Firing_Group {
	return self.firing_group
}

roll_dice_step_get_side :: proc(self: ^Roll_Dice_Step) -> Battle_State_Side {
	return self.side
}
