package game

import "core:slice"
import "core:strings"

Installed_Maps_Listing :: struct {
	installed_maps: [dynamic]^Installed_Map,
}

installed_maps_listing_new_from_maps :: proc(
	installed_maps: [dynamic]^Installed_Map,
) -> ^Installed_Maps_Listing {
	self := new(Installed_Maps_Listing)
	self.installed_maps = installed_maps
	return self
}

// Java: private InstalledMapsListing(Path folder) {
//   this(readMapYamlsAndGenerateMissingMapYamls(folder));
// }
// Path → string per port convention; wrap via path_of for the
// helper that still takes a Path.
installed_maps_listing_new :: proc(folder: string) -> ^Installed_Maps_Listing {
	maps := installed_maps_listing_read_map_yamls_and_generate_missing_map_yamls(
		path_of(folder),
	)
	return installed_maps_listing_new_from_maps(maps)
}

installed_maps_listing_find_content_root_for_map_name :: proc(
	self: ^Installed_Maps_Listing,
	map_name: string,
) -> (Path, bool) {
	name_to_find := installed_maps_listing_normalize_name(map_name)
	defer delete(name_to_find)
	for d in self.installed_maps {
		candidate := installed_maps_listing_normalize_name(installed_map_get_map_name(d))
		matched := candidate == name_to_find
		delete(candidate)
		if matched {
			return installed_map_find_content_root(d)
		}
	}
	return Path{}, false
}

installed_maps_listing_find_game_xml_path_by_game_name :: proc(
	self: ^Installed_Maps_Listing,
	game_name: string,
) -> (Path, bool) {
	for installed_map in self.installed_maps {
		names := installed_map_get_game_names(installed_map)
		found := false
		for n in names {
			if n == game_name {
				found = true
				break
			}
		}
		if found {
			return installed_map_get_game_xml_file_path(installed_map, game_name)
		}
	}
	return Path{}, false
}

installed_maps_listing_get_sorted_game_list :: proc(
	self: ^Installed_Maps_Listing,
) -> [dynamic]string {
	result: [dynamic]string
	for installed_map in self.installed_maps {
		names := installed_map_get_game_names(installed_map)
		for n in names {
			append(&result, n)
		}
	}
	slice.sort(result[:])
	return result
}

installed_maps_listing_lambda_find_installed_maps_from_download_list_11 :: proc(
	installed: ^map[^Map_Download_Item]^Installed_Map,
	download: ^Map_Download_Item,
	installed_map: ^Installed_Map,
) {
	installed[download] = installed_map
}

installed_maps_listing_lambda_find_out_of_date_maps_10 :: proc(
	out_of_date: ^map[^Map_Download_Item]^Installed_Map,
	download: ^Map_Download_Item,
	installed_map: ^Installed_Map,
) {
	out_of_date[download] = installed_map
}

installed_maps_listing_lambda_read_map_yamls_and_generate_missing_map_yamls_0 :: proc(
	p: Path,
) -> bool {
	return files_is_directory(p)
}

// Java: private static Collection<InstalledMap>
//   readMapYamlsAndGenerateMissingMapYamls(Path folder).
// Mirrors the stream pipeline: list folder children, keep only
// directories, parse each as a MapDescriptionYaml, drop empties,
// wrap remaining yamls in an InstalledMap. The Java name implies
// generation of missing yamls, but the body never writes — it only
// reads via fromMap. file_utils_list_files / files_is_directory /
// map_description_yaml_from_map are JDK/library shims.
installed_maps_listing_read_map_yamls_and_generate_missing_map_yamls :: proc(
	folder: Path,
) -> [dynamic]^Installed_Map {
	result: [dynamic]^Installed_Map
	files := file_utils_list_files(folder)
	defer delete(files)
	for f in files {
		if !installed_maps_listing_lambda_read_map_yamls_and_generate_missing_map_yamls_0(f) {
			continue
		}
		yaml, ok := map_description_yaml_from_map(f)
		if !ok {
			continue
		}
		im := new(Installed_Map)
		im^ = make_Installed_Map(yaml)
		append(&result, im)
	}
	return result
}

// Java: public static synchronized InstalledMapsListing parseMapFiles(Path folder)
// { return new InstalledMapsListing(folder); }
// Synchronization is dropped (single-threaded port). The string-based
// constructor wraps with path_of, so first convert the Path back to a string.
installed_maps_listing_parse_map_files :: proc(folder: Path) -> ^Installed_Maps_Listing {
	return installed_maps_listing_new(path_to_string(folder))
}

installed_maps_listing_normalize_name :: proc(map_name: string) -> string {
	lower := strings.to_lower(map_name)
	defer delete(lower)
	b := strings.builder_make()
	for r in lower {
		if r == '_' || r == ' ' || r == '-' {
			continue
		}
		strings.write_rune(&b, r)
	}
	return strings.to_string(b)
}

