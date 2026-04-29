package game

Strategic_Bombing_Raid_Battle_Fire_Aa :: struct {
	dice:                                ^Dice_Roll,
	casualties:                          ^Casualty_Details,
	casualties_so_far:                   [dynamic]^Unit,
	valid_attacking_units_for_this_roll: [dynamic]^Unit,
	determine_attackers:                 bool,
}

