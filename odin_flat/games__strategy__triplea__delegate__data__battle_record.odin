package game

Battle_Record :: struct {
	battle_site:               ^Territory,
	attacker:                  ^Game_Player,
	defender:                  ^Game_Player,
	attacker_lost_tuv:         i32,
	defender_lost_tuv:         i32,
	battle_result_description: Battle_Record_Battle_Result_Description,
	battle_type:               I_Battle_Battle_Type,
	battle_results:            ^Battle_Results,
}

