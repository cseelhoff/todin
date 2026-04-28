package game

// games.strategy.engine.data.GameStep
//
// One delegate step within a GameSequence (e.g. "russianBid", "germanCombatMove").

Game_Step :: struct {
	name:          string,
	display_name:  string,
	delegate_name: string,
	max_run_count: i32,
	player:        ^Game_Player,
}
