package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataFileUtils

Game_Data_File_Utils :: struct {}

game_data_file_utils_get_extension :: proc() -> string {
	return ".tsvg"
}

game_data_file_utils_lambda_is_candidate_file_name_0 :: proc(io_case: ^Io_Case, file_name: string, extension: string) -> bool {
	return io_case_check_ends_with(io_case, file_name, extension)
}

