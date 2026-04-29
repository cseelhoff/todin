package game

Map_Description_Yaml :: struct {
	yaml_file_location: Path,
	map_name:           string,
	map_game_list:      [dynamic]^Map_Description_Yaml_Map_Game,
}
