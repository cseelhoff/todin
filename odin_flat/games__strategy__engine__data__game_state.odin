package game

// Java owner: games.strategy.engine.data.GameState
//
// Java declares GameState as a pure-getter interface. Each abstract
// method is modeled as a proc-typed field; concrete implementers install
// their function at construction time. Dispatch procs (`game_state_*`)
// are the public entry points.

Game_State :: struct {
	get_alliance_tracker:     proc(self: ^Game_State) -> ^Alliance_Tracker,
	get_battle_records_list:  proc(self: ^Game_State) -> ^Battle_Records_List,
	get_map:                  proc(self: ^Game_State) -> ^Game_Map,
	get_player_list:          proc(self: ^Game_State) -> ^Player_List,
	get_production_frontier_list: proc(self: ^Game_State) -> ^Production_Frontier_List,
	get_production_rule_list: proc(self: ^Game_State) -> ^Production_Rule_List,
	get_properties:           proc(self: ^Game_State) -> ^Game_Properties,
	get_relationship_tracker: proc(self: ^Game_State) -> ^Relationship_Tracker,
	get_relationship_type_list: proc(self: ^Game_State) -> ^Relationship_Type_List,
	get_resource_list:        proc(self: ^Game_State) -> ^Resource_List,
	get_sequence:             proc(self: ^Game_State) -> ^Game_Sequence,
	get_tech_tracker:         proc(self: ^Game_State) -> ^Tech_Tracker,
	get_technology_frontier:  proc(self: ^Game_State) -> ^Technology_Frontier,
	get_unit_holder:          proc(self: ^Game_State, name: string, type: string) -> ^Unit_Holder,
	get_units:                proc(self: ^Game_State) -> ^Units_List,
	get_unit_type_list:       proc(self: ^Game_State) -> ^Unit_Type_List,
}

// games.strategy.engine.data.GameState#getMap()
game_state_get_map :: proc(self: ^Game_State) -> ^Game_Map {
	return self.get_map(self)
}

// games.strategy.engine.data.GameState#getAllianceTracker()
game_state_get_alliance_tracker :: proc(self: ^Game_State) -> ^Alliance_Tracker {
	return self.get_alliance_tracker(self)
}

// games.strategy.engine.data.GameState#getBattleRecordsList()
game_state_get_battle_records_list :: proc(self: ^Game_State) -> ^Battle_Records_List {
	return self.get_battle_records_list(self)
}

// games.strategy.engine.data.GameState#getPlayerList()
game_state_get_player_list :: proc(self: ^Game_State) -> ^Player_List {
	return self.get_player_list(self)
}

// games.strategy.engine.data.GameState#getProductionFrontierList()
game_state_get_production_frontier_list :: proc(self: ^Game_State) -> ^Production_Frontier_List {
	return self.get_production_frontier_list(self)
}

// games.strategy.engine.data.GameState#getProductionRuleList()
game_state_get_production_rule_list :: proc(self: ^Game_State) -> ^Production_Rule_List {
	return self.get_production_rule_list(self)
}

// games.strategy.engine.data.GameState#getProperties()
game_state_get_properties :: proc(self: ^Game_State) -> ^Game_Properties {
	return self.get_properties(self)
}

// games.strategy.engine.data.GameState#getRelationshipTracker()
game_state_get_relationship_tracker :: proc(self: ^Game_State) -> ^Relationship_Tracker {
	return self.get_relationship_tracker(self)
}

// games.strategy.engine.data.GameState#getRelationshipTypeList()
game_state_get_relationship_type_list :: proc(self: ^Game_State) -> ^Relationship_Type_List {
	return self.get_relationship_type_list(self)
}

// games.strategy.engine.data.GameState#getResourceList()
game_state_get_resource_list :: proc(self: ^Game_State) -> ^Resource_List {
	return self.get_resource_list(self)
}

// games.strategy.engine.data.GameState#getSequence()
game_state_get_sequence :: proc(self: ^Game_State) -> ^Game_Sequence {
	return self.get_sequence(self)
}

// games.strategy.engine.data.GameState#getTechTracker()
game_state_get_tech_tracker :: proc(self: ^Game_State) -> ^Tech_Tracker {
	return self.get_tech_tracker(self)
}

// games.strategy.engine.data.GameState#getTechnologyFrontier()
game_state_get_technology_frontier :: proc(self: ^Game_State) -> ^Technology_Frontier {
	return self.get_technology_frontier(self)
}

// games.strategy.engine.data.GameState#getUnitHolder(java.lang.String,java.lang.String)
game_state_get_unit_holder :: proc(self: ^Game_State, name: string, type: string) -> ^Unit_Holder {
	return self.get_unit_holder(self, name, type)
}

// games.strategy.engine.data.GameState#getUnitTypeList()
game_state_get_unit_type_list :: proc(self: ^Game_State) -> ^Unit_Type_List {
	return self.get_unit_type_list(self)
}

// games.strategy.engine.data.GameState#getUnits()
game_state_get_units :: proc(self: ^Game_State) -> ^Units_List {
	return self.get_units(self)
}

