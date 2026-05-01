package game

import "core:strings"

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataFileUtils

Game_Data_File_Utils :: struct {}

game_data_file_utils_get_extension :: proc() -> string {
	return ".tsvg"
}

game_data_file_utils_add_extension :: proc(file_name: string) -> string {
	return strings.concatenate({file_name, game_data_file_utils_get_extension()})
}

game_data_file_utils_lambda_is_candidate_file_name_0 :: proc(io_case: ^Io_Case, file_name: string, extension: string) -> bool {
	return io_case_check_ends_with(io_case, file_name, extension)
}

