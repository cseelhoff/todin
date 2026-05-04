package game

Step_History_Serializer :: struct {
	using serialization_writer: Serialization_Writer,
	step_name:     string,
	delegate_name: string,
	game_player:   ^Game_Player,
	display_name:  string,
}

step_history_serializer_new :: proc(
	step_name:     string,
	delegate_name: string,
	game_player:   ^Game_Player,
	display_name:  string,
) -> ^Step_History_Serializer {
	self := new(Step_History_Serializer)
	self.step_name = step_name
	self.delegate_name = delegate_name
	self.game_player = game_player
	self.display_name = display_name
	return self
}

// games.strategy.engine.history.StepHistorySerializer#write(games.strategy.engine.history.HistoryWriter)
step_history_serializer_write :: proc(self: ^Step_History_Serializer, writer: ^History_Writer) {
	history_writer_start_next_step(
		writer,
		self.step_name,
		self.delegate_name,
		self.game_player,
		self.display_name,
	)
}
