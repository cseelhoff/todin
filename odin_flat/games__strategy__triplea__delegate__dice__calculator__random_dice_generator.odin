package game

Random_Dice_Generator :: struct {
	apply: proc(max: i32, count: i32, player: ^Game_Player, dice_type: I_Random_Stats_Dice_Type, annotation: string) -> [dynamic]i32,
}

