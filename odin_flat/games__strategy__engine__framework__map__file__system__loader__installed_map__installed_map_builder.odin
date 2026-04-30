package game

// Ported from games.strategy.engine.framework.map.file.system.loader.InstalledMap$InstalledMapBuilder
// (Lombok @Builder for InstalledMap).
Installed_Map_Installed_Map_Builder :: struct {
	map_description_yaml: ^Map_Description_Yaml,
	last_modified_date:   ^Instant,
	content_root:         ^Path,
}

// Ported from InstalledMap$InstalledMapBuilder#<init>() (Lombok no-arg builder constructor).
make_Installed_Map_Installed_Map_Builder :: proc() -> Installed_Map_Installed_Map_Builder {
	return Installed_Map_Installed_Map_Builder{}
}

