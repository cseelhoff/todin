package game

Random_Stats_Details :: struct {
	data:         map[^Game_Player]^Integer_Map,
	total_map:    ^Integer_Map,
	total_stats:  Dice_Statistic,
	player_stats: map[^Game_Player]Dice_Statistic,
}

