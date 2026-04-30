package game

Client_Setting :: struct {
	using game_setting: Game_Setting,
	type: typeid,
	name: string,
	default_value: rawptr,
	listeners: [dynamic]proc(^Game_Setting),
}

// ClientSetting static fields. The Java class declares ~100 such
// fields via `<clinit>`; the AI snapshot harness only transitively
// references `saveGamesFolderPath` (through
// `AutoSaveFileUtils.getAutoSavePaths()`, itself dead in the snapshot
// path but pulled in by the methods-table transitive closure). Add
// further globals here as they're needed by future included procs.
//
// Initialized lazily on first access so we don't depend on Odin
// package-init ordering or on `Client_File_System_Helper`'s own
// initialization having run.
@(private="file") _client_setting_save_games_folder_path: ^Path_Client_Setting

client_setting_save_games_folder_path :: proc() -> ^Path_Client_Setting {
        if _client_setting_save_games_folder_path == nil {
                // Java: new PathClientSetting("SAVE_GAMES_FOLDER_PATH",
                //   ClientFileSystemHelper.getUserRootFolder().resolve("savedGames"))
                root := client_file_system_helper_get_user_root_folder()
                default_path := path_resolve(root, "savedGames")
                _client_setting_save_games_folder_path = path_client_setting_new(
                        "SAVE_GAMES_FOLDER_PATH", default_path,
                )
        }
        return _client_setting_save_games_folder_path
}
