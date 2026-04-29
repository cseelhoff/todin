package game

Add_Battle_Records_Change :: struct {
	using parent: Change,
	records_to_add: ^Battle_Records,
	round: i32,
}
