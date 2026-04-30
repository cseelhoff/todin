package game

// Java owner: games.strategy.engine.data.events.GameDataChangeListener (interface)
//
// Pure-callback interface modeled with proc-typed fields installed by
// concrete implementers. Dispatch procs (`game_data_change_listener_*`)
// are the public entry points.

Game_Data_Change_Listener :: struct {
	game_data_changed: proc(self: ^Game_Data_Change_Listener, change: ^Change),
}

// games.strategy.engine.data.events.GameDataChangeListener#gameDataChanged(games.strategy.engine.data.Change)
game_data_change_listener_game_data_changed :: proc(self: ^Game_Data_Change_Listener, change: ^Change) {
	self.game_data_changed(self, change)
}
