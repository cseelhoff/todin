package game

import "core:strings"
import "core:fmt"

Map_Description_Yaml :: struct {
	yaml_file_location: Path,
	map_name:           string,
	map_game_list:      [dynamic]^Map_Description_Yaml_Map_Game,
}

// Java: public static final String MAP_YAML_FILE_NAME = "map.yml".
MAP_YAML_FILE_NAME :: "map.yml"

// Java: public static Optional<MapDescriptionYaml> fromFile(Path
// mapDescriptionYamlFile). Provisioned (orchestrator-level) for the
// AI snapshot port: the snapshot harness never parses XML maps, so
// the call site (GameParser#lambda$parse$1) is unreachable at
// runtime. Returns (nil, false) — the Optional.empty() equivalent.
map_description_yaml_from_file :: proc(
	map_description_yaml_file: Path,
) -> (
	^Map_Description_Yaml,
	bool,
) {
	return nil, false
}

// Provisioned stub for installed-maps-listing discovery (launcher
// path, not exercised by the AI snapshot harness).
map_description_yaml_from_map :: proc(folder: Path) -> (^Map_Description_Yaml, bool) {
	return nil, false
}

// Lombok @Getter for `mapName`.
map_description_yaml_get_map_name :: proc(self: ^Map_Description_Yaml) -> string {
	return self.map_name
}

// Java: private Optional<String> findFileNameForGame(String gameName).
// Modeled in Odin as (value, ok) to mirror Optional. Original `log.warn`
// on miss is elided (snapshot harness has no logger).
map_description_yaml_find_file_name_for_game :: proc(
	self: ^Map_Description_Yaml,
	game_name: string,
) -> (
	string,
	bool,
) {
	for entry in self.map_game_list {
		if strings.equal_fold(entry.game_name, game_name) {
			return entry.xml_file_name, true
		}
	}
	return "", false
}

// Java: String findGameNameFromXmlFileName(Path xmlFile). Throws
// IllegalStateException if no entry matches; mirrored via fmt.panicf.
map_description_yaml_find_game_name_from_xml_file_name :: proc(
	self: ^Map_Description_Yaml,
	xml_file: Path,
) -> string {
	file_name := path_to_string(path_get_file_name(xml_file))
	for entry in self.map_game_list {
		if entry.xml_file_name == file_name {
			return entry.game_name
		}
	}
	fmt.panicf(
		"map.yml file at: %s, did not contain an entryfor %s",
		path_to_string(self.yaml_file_location),
		path_to_string(xml_file),
	)
}

// Java: private Optional<Path> findGamesFolder(). Walks the parent of
// `yamlFileLocation` looking for a 'games' subdirectory (max depth 5)
// via FileUtils.findClosestToRoot. log.warn on miss is elided.
map_description_yaml_find_games_folder :: proc(
	self: ^Map_Description_Yaml,
) -> (
	Path,
	bool,
) {
	map_folder := path_get_parent(self.yaml_file_location)
	found := file_utils_find_closest_to_root(path_to_string(map_folder), 5, "games")
	if found == "" {
		return Path{}, false
	}
	return path_of(found), true
}

// Java: private Optional<Path> searchForGameFile(Path gamesFolder,
// String xmlFileName). Searches under `gamesFolder` (max depth 3) for a
// file matching `xml_file_name`. log.warn on miss elided.
map_description_yaml_search_for_game_file :: proc(
	self: ^Map_Description_Yaml,
	games_folder: Path,
	xml_file_name: string,
) -> (
	Path,
	bool,
) {
	found := file_utils_find_closest_to_root(path_to_string(games_folder), 3, xml_file_name)
	if found == "" {
		return Path{}, false
	}
	return path_of(found), true
}

// Java: public Optional<Path> getGameXmlPathByGameName(String gameName).
// Looks up the XML file name for `game_name` in the map.yml entries,
// finds the 'games' folder relative to yamlFileLocation, then searches
// for the matching file underneath. Returns (Path{}, false) if any
// step fails (Optional.empty equivalent).
map_description_yaml_get_game_xml_path_by_game_name :: proc(
	self: ^Map_Description_Yaml,
	game_name: string,
) -> (
	Path,
	bool,
) {
	xml_file_name, has_xml := map_description_yaml_find_file_name_for_game(self, game_name)
	games_folder, has_folder := map_description_yaml_find_games_folder(self)
	if !has_xml || !has_folder {
		return Path{}, false
	}
	return map_description_yaml_search_for_game_file(self, games_folder, xml_file_name)
}
