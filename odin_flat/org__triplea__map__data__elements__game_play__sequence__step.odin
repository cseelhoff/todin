package game

Game_Play_Sequence_Step :: struct {
	name:            string,
	delegate:        string,
	player:          string,
	max_run_count:   ^i32,
	display:         string,
	step_properties: [dynamic]^Game_Play_Sequence_Step_Step_Property,
}

game_play_sequence_step_get_delegate :: proc(self: ^Game_Play_Sequence_Step) -> string {
	return self.delegate
}

game_play_sequence_step_get_display :: proc(self: ^Game_Play_Sequence_Step) -> string {
	return self.display
}

game_play_sequence_step_get_max_run_count :: proc(self: ^Game_Play_Sequence_Step) -> ^i32 {
	return self.max_run_count
}

game_play_sequence_step_get_name :: proc(self: ^Game_Play_Sequence_Step) -> string {
	return self.name
}

game_play_sequence_step_get_player :: proc(self: ^Game_Play_Sequence_Step) -> string {
	return self.player
}

game_play_sequence_step_get_step_properties :: proc(self: ^Game_Play_Sequence_Step) -> [dynamic]^Game_Play_Sequence_Step_Step_Property {
	return self.step_properties
}

