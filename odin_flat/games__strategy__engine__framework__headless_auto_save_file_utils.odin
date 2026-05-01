package game

import "core:os"
import "core:strings"

Headless_Auto_Save_File_Utils :: struct {
	using auto_save_file_utils: Auto_Save_File_Utils,
}

headless_auto_save_file_utils_new :: proc() -> ^Headless_Auto_Save_File_Utils {
	self := new(Headless_Auto_Save_File_Utils)
	self.auto_save_file_utils = make_Auto_Save_File_Utils()
	return self
}

headless_auto_save_file_utils_lambda_get_auto_save_file_name_0 :: proc(v: string) -> string {
	return strings.concatenate({v, "_"})
}

headless_auto_save_file_utils_get_auto_save_file_name :: proc(self: ^Headless_Auto_Save_File_Utils, base_file_name: string) -> string {
	env := os.get_env("triplea.name")
	prefix := ""
	if len(env) > 0 {
		prefix = headless_auto_save_file_utils_lambda_get_auto_save_file_name_0(env)
	}
	return strings.concatenate({"autosave_", prefix, base_file_name})
}
