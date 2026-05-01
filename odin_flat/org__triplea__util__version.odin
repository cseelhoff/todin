package game

import "core:fmt"

Version :: struct {
	version_string: string,
	major:          i32,
	minor:          i32,
	point:          i32,
	build_number:   string,
}

version_is_compatible_with_map_minimum_engine_version :: proc(self: ^Version, map_minimum_engine_version: ^Version) -> bool {
	assert(map_minimum_engine_version != nil)
	return self.major > map_minimum_engine_version.major ||
		(self.major == map_minimum_engine_version.major && self.minor >= map_minimum_engine_version.minor)
}

version_to_string_lambda_0 :: proc(self: ^Version) -> string {
	return fmt.aprintf("%d.%d", self.major, self.minor)
}

// Java owners covered by this file:
//   - org.triplea.util.Version

