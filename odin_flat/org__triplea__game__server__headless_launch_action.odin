package game

import "core:fmt"

Headless_Launch_Action :: struct {
	headless_game_server: ^Headless_Game_Server,
}

@(private="file")
headless_launch_action_skip_map_resource_loading: bool = false

headless_launch_action_new :: proc(server: ^Headless_Game_Server) -> ^Headless_Launch_Action {
	self := new(Headless_Launch_Action)
	self.headless_game_server = server
	return self
}

headless_launch_action_set_skip_map_resource_loading :: proc(self: ^Headless_Launch_Action, value: bool) {
	headless_launch_action_skip_map_resource_loading = value
}

headless_launch_action_get_auto_save_file_utils :: proc(self: ^Headless_Launch_Action) -> ^Headless_Auto_Save_File_Utils {
	return headless_auto_save_file_utils_new()
}

// proc:org.triplea.game.server.HeadlessLaunchAction#lambda$startGame$0(games.strategy.engine.data.GameData)
// Java synthetic backing the orElseThrow supplier inside startGame:
//   () -> new IllegalStateException("Unable to find map: " + gameData.getMapName())
// The captured `gameData` local is hoisted to a parameter by javac.
// Builds the IllegalStateException (modeled as ^Exception) with the
// same message Java would throw when InstalledMapsListing fails to
// locate the requested map.
headless_launch_action_lambda_start_game_0 :: proc(game_data: ^Game_Data) -> ^Exception {
	msg := fmt.aprintf("Unable to find map: %s", game_data_get_map_name(game_data))
	return exception_new(msg)
}

