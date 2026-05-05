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
// NOTE: Game_State is the first embedded field of Game_Data
// (`using game_state: Game_State`), so any ^Game_State at runtime is
// really a ^Game_Data. The proc-field vtable on Game_State is never
// wired by game_data_new, so reading those fields would return nil.
// All dispatchers below bypass the vtable and call the Game_Data
// concrete getters directly.
game_state_get_map :: proc(self: ^Game_State) -> ^Game_Map {
	return game_data_get_map(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getAllianceTracker()
game_state_get_alliance_tracker :: proc(self: ^Game_State) -> ^Alliance_Tracker {
	return game_data_get_alliance_tracker(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getBattleRecordsList()
game_state_get_battle_records_list :: proc(self: ^Game_State) -> ^Battle_Records_List {
	return game_data_get_battle_records_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getPlayerList()
game_state_get_player_list :: proc(self: ^Game_State) -> ^Player_List {
	return game_data_get_player_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getProductionFrontierList()
game_state_get_production_frontier_list :: proc(self: ^Game_State) -> ^Production_Frontier_List {
	return game_data_get_production_frontier_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getProductionRuleList()
game_state_get_production_rule_list :: proc(self: ^Game_State) -> ^Production_Rule_List {
	return game_data_get_production_rule_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getProperties()
game_state_get_properties :: proc(self: ^Game_State) -> ^Game_Properties {
	return game_data_get_properties(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getRelationshipTracker()
game_state_get_relationship_tracker :: proc(self: ^Game_State) -> ^Relationship_Tracker {
	return game_data_get_relationship_tracker(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getRelationshipTypeList()
game_state_get_relationship_type_list :: proc(self: ^Game_State) -> ^Relationship_Type_List {
	return game_data_get_relationship_type_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getResourceList()
game_state_get_resource_list :: proc(self: ^Game_State) -> ^Resource_List {
	return game_data_get_resource_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getSequence()
game_state_get_sequence :: proc(self: ^Game_State) -> ^Game_Sequence {
	return game_data_get_sequence(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getTechTracker()
game_state_get_tech_tracker :: proc(self: ^Game_State) -> ^Tech_Tracker {
	return game_data_get_tech_tracker(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getTechnologyFrontier()
game_state_get_technology_frontier :: proc(self: ^Game_State) -> ^Technology_Frontier {
	return game_data_get_technology_frontier(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getUnitHolder(java.lang.String,java.lang.String)
game_state_get_unit_holder :: proc(self: ^Game_State, name: string, type: string) -> ^Unit_Holder {
	return game_data_get_unit_holder(cast(^Game_Data)self, name, type)
}

// games.strategy.engine.data.GameState#getUnitTypeList()
game_state_get_unit_type_list :: proc(self: ^Game_State) -> ^Unit_Type_List {
	return game_data_get_unit_type_list(cast(^Game_Data)self)
}

// games.strategy.engine.data.GameState#getUnits()
game_state_get_units :: proc(self: ^Game_State) -> ^Units_List {
	return game_data_get_units(cast(^Game_Data)self)
}

