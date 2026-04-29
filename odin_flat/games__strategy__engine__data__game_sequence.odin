package game

// games.strategy.engine.data.GameSequence
//
// Ordered list of GameStep + cursor (round, step index).

Game_Sequence :: struct {
	using game_data_component: Game_Data_Component,
	steps:         [dynamic]^Game_Step,
	current_index: i32,
	round:         i32,
	round_offset:  i32,
}
