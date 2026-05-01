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

// games.strategy.triplea.delegate.data.BattleRecords#<init>(BattleRecords) — copy ctor.
battle_records_new_copy :: proc(records: ^Battle_Records) -> ^Battle_Records {
	br := new(Battle_Records)
	br.records = make(map[^Game_Player]map[Uuid]^Battle_Record)
	for p, record in records.records {
		m := make(map[Uuid]^Battle_Record)
		for k, v in record {
			m[k] = battle_record_new_copy(v)
		}
		br.records[p] = m
	}
	return br
}

// games.strategy.triplea.delegate.data.BattleRecords#writeReplace
battle_records_write_replace :: proc(self: ^Battle_Records) -> ^Battle_Records_Serialization_Proxy {
	return battle_records_serialization_proxy_new(self)
}

// games.strategy.triplea.delegate.data.BattleRecords#addBattle
battle_records_add_battle :: proc(
	self: ^Battle_Records,
	current_player_and_attacker: ^Game_Player,
	battle_id: Uuid,
	battle_site: ^Territory,
	battle_type: I_Battle_Battle_Type,
) {
	current, ok := self.records[current_player_and_attacker]
	if !ok {
		current = make(map[Uuid]^Battle_Record)
	}
	initial := battle_record_new(battle_site, current_player_and_attacker, battle_type)
	current[battle_id] = initial
	self.records[current_player_and_attacker] = current
}

// games.strategy.triplea.delegate.data.BattleRecords#addRecord
battle_records_add_record :: proc(self: ^Battle_Records, other: ^Battle_Records) {
	for p, additional_records in other.records {
		current_record, ok := self.records[p]
		if ok {
			for guid, br in additional_records {
				if guid in current_record {
					panic("Should not be adding battle record for player when they are already on the record.")
				}
				current_record[guid] = br
			}
			self.records[p] = current_record
		} else {
			self.records[p] = additional_records
		}
	}
}

// games.strategy.triplea.delegate.data.BattleRecords#addResultToBattle
battle_records_add_result_to_battle :: proc(
	self: ^Battle_Records,
	current_player: ^Game_Player,
	battle_id: Uuid,
	defender: ^Game_Player,
	attacker_lost_tuv: i32,
	defender_lost_tuv: i32,
	battle_result_description: Battle_Record_Battle_Result_Description,
	battle_results: ^Battle_Results,
) {
	current, ok := self.records[current_player]
	if !ok {
		panic("Trying to add info to battle records that do not exist")
	}
	if !(battle_id in current) {
		panic("Trying to add info to a battle that does not exist")
	}
	record := current[battle_id]
	battle_record_set_result(
		record,
		defender,
		attacker_lost_tuv,
		defender_lost_tuv,
		battle_result_description,
		battle_results,
	)
}
