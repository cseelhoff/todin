package game

Pro_Purchase_Ai :: struct {
	calc:               ^Pro_Odds_Calculator,
	pro_data:           ^Pro_Data,
	data:               ^Game_Data,
	start_of_turn_data: ^Game_State,
	player:             ^Game_Player,
	resource_tracker:   ^Pro_Resource_Tracker,
	territory_manager:  ^Pro_Territory_Manager,
	is_bid:             bool,
}

