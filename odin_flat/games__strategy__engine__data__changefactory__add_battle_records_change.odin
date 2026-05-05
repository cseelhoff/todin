package game

Add_Battle_Records_Change :: struct {
	using change: Change,
	records_to_add: ^Battle_Records,
	round: i32,
}

add_battle_records_change_new :: proc(battle_records: ^Battle_Records, data: ^Game_State) -> ^Add_Battle_Records_Change {
	c := new(Add_Battle_Records_Change)
	c.kind = .Add_Battle_Records_Change
	c.round = game_sequence_get_round(game_state_get_sequence(data))
	// make a copy because this is only done once, and only externally from battle
	// tracker, and the source will be cleared (battle tracker clears out the records each turn)
	c.records_to_add = battle_records_new_copy(battle_records)
	return c
}

// Java: protected void perform(GameState data)
add_battle_records_change_perform :: proc(self: ^Add_Battle_Records_Change, data: ^Game_State) {
	current_records := &game_state_get_battle_records_list(data).battle_records
	// make a copy because otherwise ours will be cleared when we RemoveBattleRecordsChange
	battle_records_list_add_records(current_records, self.round, battle_records_new_copy(self.records_to_add))
}
