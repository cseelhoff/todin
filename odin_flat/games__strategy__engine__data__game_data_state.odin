package game

Game_Data_State :: struct {
	tech_tracker: ^Tech_Tracker,
}

game_data_state_get_tech_tracker :: proc(self: ^Game_Data_State) -> ^Tech_Tracker {
	return self.tech_tracker
}

game_data_state_new :: proc(game_data: ^Game_Data) -> ^Game_Data_State {
	self := new(Game_Data_State)
	self.tech_tracker = tech_tracker_new(game_data)
	return self
}

