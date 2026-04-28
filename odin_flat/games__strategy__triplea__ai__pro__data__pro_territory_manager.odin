package game

Pro_Territory_Manager :: struct {
	calc:                     ^Pro_Odds_Calculator,
	pro_data:                 ^Pro_Data,
	player:                   ^Game_Player,
	attack_options:           ^Pro_My_Move_Options,
	potential_attack_options: ^Pro_My_Move_Options,
	defend_options:           ^Pro_My_Move_Options,
	allied_attack_options:    ^Pro_Other_Move_Options,
	enemy_defend_options:     ^Pro_Other_Move_Options,
	enemy_attack_options:     ^Pro_Other_Move_Options,
}

