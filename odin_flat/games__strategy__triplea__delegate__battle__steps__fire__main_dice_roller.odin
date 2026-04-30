package game

Main_Dice_Roller :: struct {
}

main_dice_roller_new :: proc() -> ^Main_Dice_Roller {
	self := new(Main_Dice_Roller)
	return self
}
