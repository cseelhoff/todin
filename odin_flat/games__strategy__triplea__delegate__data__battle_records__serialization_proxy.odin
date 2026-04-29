package game

Serialization_Proxy :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}
