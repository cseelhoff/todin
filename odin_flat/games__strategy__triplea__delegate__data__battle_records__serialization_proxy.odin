package game

Battle_Records_Serialization_Proxy :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}

battle_records_serialization_proxy_new :: proc(battle_records: ^Battle_Records) -> ^Battle_Records_Serialization_Proxy {
	this := new(Battle_Records_Serialization_Proxy)
	this.records = battle_records.records
	return this
}
