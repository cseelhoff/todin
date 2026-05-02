package game

import "core:fmt"
import "core:strconv"
import "core:strings"

Version :: struct {
	version_string: string,
	major:          i32,
	minor:          i32,
	point:          i32,
	build_number:   string,
}

version_new :: proc(version: string) -> ^Version {
	self := new(Version)
	self.version_string = strings.clone(version)

	truncated := string_utils_truncate_from(version, "+")
	parts := strings.split(truncated, ".")
	defer delete(parts)

	if len(parts) == 0 {
		panic(fmt.tprintf("Invalid version String: %s", version))
	}

	major_val, major_ok := strconv.parse_int(parts[0])
	if !major_ok {
		panic(fmt.tprintf("Invalid version String: %s", version))
	}
	self.major = i32(major_val)

	if len(parts) <= 1 {
		self.minor = 0
	} else {
		minor_val, minor_ok := strconv.parse_int(parts[1])
		if !minor_ok {
			panic(fmt.tprintf("Invalid version String: %s", version))
		}
		self.minor = i32(minor_val)
	}

	return self
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

