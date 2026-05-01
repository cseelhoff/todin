package game

Battle_Records :: struct {
	records: map[^Game_Player]map[Uuid]^Battle_Record,
}

battle_records_new :: proc() -> ^Battle_Records {
	br := new(Battle_Records)
	br.records = make(map[^Game_Player]map[Uuid]^Battle_Record)
	return br
}

battle_records_new_with_records :: proc(records: map[^Game_Player]map[Uuid]^Battle_Record) -> ^Battle_Records {
	br := new(Battle_Records)
	br.records = records
	return br
}

battle_records_clear :: proc(self: ^Battle_Records) {
	clear(&self.records)
}

battle_records_is_empty :: proc(self: ^Battle_Records) -> bool {
	return len(self.records) == 0
}

battle_records_remove_battle :: proc(self: ^Battle_Records, current_player: ^Game_Player, battle_id: Uuid) {
	current, ok := self.records[current_player]
	if !ok || !(battle_id in current) {
		for player, inner in self.records {
			if inner != nil && (battle_id in inner) {
				inner_mut := inner
				delete_key(&inner_mut, battle_id)
				self.records[player] = inner_mut
				return
			}
		}
		panic("Trying to remove info from battle records that do not exist")
	}
	delete_key(&current, battle_id)
	self.records[current_player] = current
}
