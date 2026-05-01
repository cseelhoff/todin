package game

import "core:fmt"

Battle_Record :: struct {
	battle_site:               ^Territory,
	attacker:                  ^Game_Player,
	defender:                  ^Game_Player,
	attacker_lost_tuv:         i32,
	defender_lost_tuv:         i32,
	battle_result_description: Battle_Record_Battle_Result_Description,
	battle_type:               I_Battle_Battle_Type,
	battle_results:            ^Battle_Results,
}

// games.strategy.triplea.delegate.data.BattleRecord#<init>(Territory, GamePlayer, BattleType)
battle_record_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	battle_type: I_Battle_Battle_Type,
) -> ^Battle_Record {
	self := new(Battle_Record)
	self.battle_site = battle_site
	self.attacker = attacker
	self.battle_type = battle_type
	return self
}

// games.strategy.triplea.delegate.data.BattleRecord#<init>(BattleRecord) — copy ctor.
battle_record_new_copy :: proc(record: ^Battle_Record) -> ^Battle_Record {
	self := new(Battle_Record)
	self.battle_site = record.battle_site
	self.attacker = record.attacker
	self.defender = record.defender
	self.attacker_lost_tuv = record.attacker_lost_tuv
	self.defender_lost_tuv = record.defender_lost_tuv
	self.battle_result_description = record.battle_result_description
	self.battle_type = record.battle_type
	self.battle_results = record.battle_results
	return self
}

// games.strategy.triplea.delegate.data.BattleRecord#setResult
battle_record_set_result :: proc(
	self: ^Battle_Record,
	defender: ^Game_Player,
	attacker_lost_tuv: i32,
	defender_lost_tuv: i32,
	battle_result_description: Battle_Record_Battle_Result_Description,
	battle_results: ^Battle_Results,
) {
	self.defender = defender
	self.attacker_lost_tuv = attacker_lost_tuv
	self.defender_lost_tuv = defender_lost_tuv
	self.battle_result_description = battle_result_description
	self.battle_results = battle_results
}

// games.strategy.triplea.delegate.data.BattleRecord#toString
battle_record_to_string :: proc(self: ^Battle_Record) -> string {
	site_name := ""
	if self.battle_site != nil {
		site_name = territory_to_string(self.battle_site)
	}
	// Java: return battleType + " battle in " + battleSite;
	// Java enum toString() defaults to name().
	return fmt.tprintf("%v battle in %s", self.battle_type, site_name)
}

