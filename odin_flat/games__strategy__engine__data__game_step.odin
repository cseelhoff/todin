package game

// games.strategy.engine.data.GameStep
//
// One delegate step within a GameSequence (e.g. "russianBid", "germanCombatMove").

Game_Step :: struct {
	using game_data_component: Game_Data_Component,
	name:          string,
	display_name:  string,
	player:        ^Game_Player,
	delegate_name: string,
	run_count:     i32,
	max_run_count: i32,
	properties:    map[string]string,
}

// games.strategy.engine.data.GameStep.PropertyKeys
Game_Step_Property_Keys :: struct {}
