package game

Battle_Records_List :: struct {
	using game_data_component: Game_Data_Component,
	battle_records: map[i32]^Battle_Records,
}

battle_records_list_get_battle_records_map :: proc(self: ^Battle_Records_List) -> map[i32]^Battle_Records {
	return self.battle_records
}

