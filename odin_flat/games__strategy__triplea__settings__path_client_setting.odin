package game

// games.strategy.triplea.settings.PathClientSetting
//
// Phase A produced an empty marker for this struct because no harness
// field references it. The orchestrator augments it with the minimum
// state needed to back ClientSetting static globals (e.g.
// `client_setting_save_games_folder_path`) used by transitively-included
// procs like `AutoSaveFileUtils.getAutoSavePaths()`.
//
// Single-process, no `java.util.prefs` backing — the AI snapshot harness
// never reads/writes user prefs. The default Path is the only value
// required.

Path_Client_Setting :: struct {
	name:          string,
	default_value: Path,
	current_value: Path,
	has_current:   bool,
}

path_client_setting_new :: proc(name: string, default_value: Path) -> ^Path_Client_Setting {
	s := new(Path_Client_Setting)
	s.name = name
	s.default_value = default_value
	s.current_value = default_value
	s.has_current = false
	return s
}

// Mirrors GameSetting<T>.getValueOrThrow() for the Path specialization:
// returns the current value if set, otherwise the default.
path_client_setting_get_value_or_throw :: proc(self: ^Path_Client_Setting) -> Path {
	if self.has_current {
		return self.current_value
	}
	return self.default_value
}

path_client_setting_get_value :: proc(self: ^Path_Client_Setting) -> Path {
	return path_client_setting_get_value_or_throw(self)
}

path_client_setting_set_value :: proc(self: ^Path_Client_Setting, value: Path) {
	self.current_value = value
	self.has_current = true
}

path_client_setting_reset_value :: proc(self: ^Path_Client_Setting) {
	self.current_value = self.default_value
	self.has_current = false
}
