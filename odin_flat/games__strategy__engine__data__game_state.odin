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
}

// games.strategy.engine.data.GameState#getAllianceTracker()
game_state_get_alliance_tracker :: proc(self: ^Game_State) -> ^Alliance_Tracker {
	return self.get_alliance_tracker(self)
}

// games.strategy.engine.data.GameState#getBattleRecordsList()
game_state_get_battle_records_list :: proc(self: ^Game_State) -> ^Battle_Records_List {
	return self.get_battle_records_list(self)
}

