package game

Pro_Non_Combat_Move_Ai :: struct {
	calc:               ^Pro_Odds_Calculator,
	pro_data:           ^Pro_Data,
	data:               ^Game_Data,
	player:             ^Game_Player,
	unit_territory_map: map[^Unit]^Territory,
	territory_manager:  ^Pro_Territory_Manager,
}

