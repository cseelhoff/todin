package game

Random_Dice_Generator :: struct {
	apply: proc(max: i32, count: i32, player: ^Game_Player, dice_type: Dice_Type, annotation: string) -> [dynamic]i32,
}

