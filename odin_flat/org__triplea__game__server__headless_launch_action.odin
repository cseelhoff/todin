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

// Java:
//   public void startGame(LocalPlayers localPlayers, IGame game,
//                         Set<Player> players, Chat chat) {
//     GameData gameData = game.getData();
//     List<Path> mapPath = skipMapResourceLoading
//         ? List.of()
//         : List.of(InstalledMapsListing.searchAllMapsForMapName(gameData.getMapName())
//             .orElseThrow(() -> new IllegalStateException(
//                 "Unable to find map: " + gameData.getMapName())));
//     game.setResourceLoader(new ResourceLoader(mapPath));
//     game.setDisplay(new HeadlessDisplay());
//     game.setSoundChannel(new HeadlessSoundChannel());
//   }
headless_launch_action_start_game :: proc(
	self: ^Headless_Launch_Action,
	local_players: ^Local_Players,
	game: ^I_Game,
	players: map[^Player]struct{},
	chat: ^Chat,
) {
	_ = self
	_ = local_players
	_ = players
	_ = chat
	game_data := i_game_get_data(game)
	asset_paths: [dynamic]string
	if !headless_launch_action_skip_map_resource_loading {
		map_path, ok := installed_maps_listing_search_all_maps_for_map_name(
			game_data_get_map_name(game_data),
		)
		if !ok {
			// Java: throw new IllegalStateException("Unable to find map: " + ...)
			// Mirrors the orElseThrow supplier (lambda$startGame$0).
			_ = headless_launch_action_lambda_start_game_0(game_data)
			return
		}
		append(&asset_paths, path_to_string(map_path))
	}
	i_game_set_resource_loader(game, resource_loader_new(asset_paths))
	i_game_set_display(game, &headless_display_new().i_display)
	i_game_set_sound_channel(game, &headless_sound_channel_new().i_sound)
}

