package game

Roll_Dice_Step :: struct {
	battle_state:     ^Battle_State,
	side:             Battle_State_Side,
	firing_group:     ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	roll_dice:        proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
}
