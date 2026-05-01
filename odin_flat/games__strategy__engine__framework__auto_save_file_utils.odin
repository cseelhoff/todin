package game

// Java: games.strategy.engine.framework.AutoSaveFileUtils
// Utility class with only static methods.
Auto_Save_File_Utils :: struct {}

make_Auto_Save_File_Utils :: proc() -> Auto_Save_File_Utils {
	return Auto_Save_File_Utils{}
}

auto_save_file_utils_get_auto_save_file_name :: proc(self: ^Auto_Save_File_Utils, base_file_name: string) -> string {
	return base_file_name
}

auto_save_file_utils_get_auto_save_file :: proc(self: ^Auto_Save_File_Utils, base_file_name: string) -> Path {
	folder := path_resolve(path_client_setting_get_value_or_throw(client_setting_save_games_folder_path()), "autoSave")
	return path_resolve(folder, auto_save_file_utils_get_auto_save_file_name(self, base_file_name))
}

auto_save_file_utils_get_auto_save_step_name :: proc(self: ^Auto_Save_File_Utils, step_name: string) -> string {
	return step_name
}

auto_save_file_utils_lambda_get_auto_save_paths_0 :: proc(f: Path) -> bool {
	return !files_is_directory(f)
}

auto_save_file_utils_get_auto_save_paths :: proc() -> [dynamic]Path {
	auto_save_folder := path_resolve(path_client_setting_get_value_or_throw(client_setting_save_games_folder_path()), "autoSave")
	if !files_exists(auto_save_folder) {
		files_create_directories(auto_save_folder)
	}
	paths := files_list(auto_save_folder)
	result := make([dynamic]Path)
	for p in paths {
		if auto_save_file_utils_lambda_get_auto_save_paths_0(p) {
			append(&result, p)
		}
	}
	return result
}

