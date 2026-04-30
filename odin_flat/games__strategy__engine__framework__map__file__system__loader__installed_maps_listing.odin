package game

import "core:slice"
import "core:strings"

Installed_Maps_Listing :: struct {
	installed_maps: [dynamic]^Installed_Map,
}

installed_maps_listing_new :: proc(
	installed_maps: [dynamic]^Installed_Map,
) -> ^Installed_Maps_Listing {
	self := new(Installed_Maps_Listing)
	self.installed_maps = installed_maps
	return self
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

