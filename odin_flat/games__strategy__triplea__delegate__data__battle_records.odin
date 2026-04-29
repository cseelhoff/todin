package game

Battle_Records :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}
