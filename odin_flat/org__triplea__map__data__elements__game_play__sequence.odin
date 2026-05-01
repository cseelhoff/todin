package game

Game_Play_Sequence :: struct {
	steps: [dynamic]^Game_Play_Sequence_Step,
}

game_play_sequence_get_steps :: proc(self: ^Game_Play_Sequence) -> [dynamic]^Game_Play_Sequence_Step {
	return self.steps
}

