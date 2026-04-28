package game

// games.strategy.engine.data.GameSequence
//
// Ordered list of GameStep + cursor (round, step index).

Game_Sequence :: struct {
	round:         i32,
	current_index: i32,
	steps:         [dynamic]^Game_Step,
}
