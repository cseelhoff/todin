package game

Game_Data_State :: struct {
	tech_tracker: ^Tech_Tracker,
}

game_data_state_get_tech_tracker :: proc(self: ^Game_Data_State) -> ^Tech_Tracker {
	return self.tech_tracker
}

