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
