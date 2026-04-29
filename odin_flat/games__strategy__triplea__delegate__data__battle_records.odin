package game

Battle_Records :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}

Battle_Records_Serialization_Proxy :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}
