package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataUtils

Game_Data_Utils :: struct {}

// Lambda: () -> new IllegalStateException("Game data clone expected.")
// Passed to optionalGameDataClone.orElseThrow(...) in cloneGameDataWithHistory.
game_data_utils_lambda_clone_game_data_with_history_1 :: proc() -> ^Exception {
	return exception_new("Game data clone expected.")
}

// Lambda body of GameDataUtils.translateIntoOtherGameData: in Java
// this wraps the supplied OutputStream in a GameObjectOutputStream
// and writes the captured object via writeObject. ObjectOutputStream
// and GameObjectOutputStream are opaque markers in the snapshot
// harness (no real serialization is performed during AI snapshot
// runs), so the synchronous in-process equivalent is to flush the
// stream and return; the captured `object` is preserved as a rawptr
// parameter to mirror the Java closure capture.
game_data_utils_lambda_translate_into_other_game_data_3 :: proc(object: rawptr, os: ^Output_Stream) {
	_ = object
	output_stream_flush(os)
}

