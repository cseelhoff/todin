package game

Installed_Map :: struct {
	map_description_yaml: ^Map_Description_Yaml,
	last_modified_date:   ^Instant,
	content_root:         ^Path,
}

make_Installed_Map :: proc(map_description_yaml: ^Map_Description_Yaml) -> Installed_Map {
	return Installed_Map{
		map_description_yaml = map_description_yaml,
		last_modified_date   = nil,
		content_root         = nil,
	}
}

make_Installed_Map_3 :: proc(
	map_description_yaml: ^Map_Description_Yaml,
	last_modified: Instant,
	install_path: Path,
) -> Installed_Map {
	return Installed_Map{
		map_description_yaml = map_description_yaml,
		last_modified_date   = new_clone(last_modified),
		content_root         = new_clone(install_path),
	}
}

// Provisioned stubs: the launcher's installed-maps discovery code is
// not on the WW2v5 AI snapshot path (snapshots load a pre-resolved
// XML), so these getters return zero-values.
installed_map_get_map_name :: proc(self: ^Installed_Map) -> string {
	return ""
}

installed_map_find_content_root :: proc(self: ^Installed_Map) -> (Path, bool) {
	return Path{}, false
}

installed_map_get_game_names :: proc(self: ^Installed_Map) -> []string {
	return nil
}

installed_map_get_game_xml_file_path :: proc(
	self: ^Installed_Map,
	name: string,
) -> (Path, bool) {
	return Path{}, false
}
