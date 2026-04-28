package game

Fire_Round_Steps_Factory_Fire_Round_Steps_Factory_Builder :: struct {
	battle_state:          ^Battle_State,
	battle_actions:        ^Battle_Actions,
	firing_group_splitter: proc(^Battle_State) -> [dynamic]^Firing_Group,
	side:                  ^Battle_State_Side,
	return_fire:           ^Must_Fight_Battle_Return_Fire,
	dice_roller:           proc(^I_Delegate_Bridge, ^Roll_Dice_Step) -> ^Dice_Roll,
	casualty_selector:     proc(^I_Delegate_Bridge, ^Select_Casualties) -> ^Casualty_Details,
}
