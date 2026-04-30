package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataUtils

Game_Data_Utils :: struct {}

// Lambda: () -> new IllegalStateException("Game data clone expected.")
// Passed to optionalGameDataClone.orElseThrow(...) in cloneGameDataWithHistory.
game_data_utils_lambda_clone_game_data_with_history_1 :: proc() -> ^Exception {
	return exception_new("Game data clone expected.")
}

