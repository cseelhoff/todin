package game

Remove_Available_Tech :: struct {
	using change: Change,
	tech:     ^Tech_Advance,
	frontier: ^Technology_Frontier,
	player:   ^Game_Player,
}
