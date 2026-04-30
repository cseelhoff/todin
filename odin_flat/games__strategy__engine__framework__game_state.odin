package game

// games.strategy.engine.framework.GameState
// Holder for static 'game started' state. Java declares this as an
// enum with no instances and a single private static boolean field.

Game_State :: struct {}

game_state_started: bool = false

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameState

// Synthetic enum $values() accessor. The Java enum has no constants.
game_state_values :: proc() -> []Game_State {
	return []Game_State{}
}

// games.strategy.engine.framework.GameState#notStarted()
game_state_framework_not_started :: proc() -> bool {
	return !game_state_started
}

// games.strategy.engine.framework.GameState#setStarted()
game_state_framework_set_started :: proc() {
	game_state_started = true
}

