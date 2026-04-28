package game

Fire_Round_Steps_Factory :: struct {
	battle_state:          ^Battle_State,
	battle_actions:        ^Battle_Actions,
	firing_group_splitter: proc(state: ^Battle_State) -> [dynamic]^Firing_Group,
	side:                  Battle_State_Side,
	return_fire:           Must_Fight_Battle_Return_Fire,
	dice_roller:           proc(bridge: ^I_Delegate_Bridge, step: ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector:     proc(bridge: ^I_Delegate_Bridge, step: ^Select_Casualties) -> ^Casualty_Details,
}
