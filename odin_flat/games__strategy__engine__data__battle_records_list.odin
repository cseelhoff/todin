package game

Battle_Records_List :: struct {
	using parent: Game_Data_Component,
	battle_records: map[i32]^Battle_Records,
}

