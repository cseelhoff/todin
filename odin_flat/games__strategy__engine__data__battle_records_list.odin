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

