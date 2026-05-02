package game

Battle_Records_List :: struct {
	using game_data_component: Game_Data_Component,
	battle_records: map[i32]^Battle_Records,
}

battle_records_list_get_battle_records_map :: proc(self: ^Battle_Records_List) -> map[i32]^Battle_Records {
	return self.battle_records
}

battle_records_list_new :: proc(data: ^Game_Data) -> ^Battle_Records_List {
	self := new(Battle_Records_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.battle_records = make(map[i32]^Battle_Records)
	return self
}

battle_records_list_add_records :: proc(record_list: ^map[i32]^Battle_Records, current_round: i32, other: ^Battle_Records) {
	current, ok := record_list[current_round]
	if !ok || current == nil {
		record_list[current_round] = other
		return
	}
	battle_records_add_record(current, other)
	record_list[current_round] = current
}

