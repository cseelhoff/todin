package game

import "core:fmt"

// JDK shim: java.nio.file.Path as a wrapped string.
// AI snapshot harness uses only path-string semantics; no real I/O.

Path :: struct {
	value: string,
}

path_of :: proc(value: string) -> Path {
	return Path{value = value}
}

path_to_string :: proc(self: Path) -> string {
	return self.value
}

path_get_file_name :: proc(self: Path) -> Path {
	s := self.value
	for i := len(s) - 1; i >= 0; i -= 1 {
		if s[i] == '/' || s[i] == '\\' {
			return Path{value = s[i + 1:]}
		}
	}
	return self
}

path_get_parent :: proc(self: Path) -> Path {
	s := self.value
	for i := len(s) - 1; i >= 0; i -= 1 {
		if s[i] == '/' || s[i] == '\\' {
			return Path{value = s[:i]}
		}
	}
	return Path{value = ""}
}

path_resolve :: proc(self: Path, other: string) -> Path {
	if len(self.value) == 0 {
		return Path{value = other}
	}
	last := self.value[len(self.value) - 1]
	if last == '/' || last == '\\' {
		return Path{value = fmt.tprintf("%s%s", self.value, other)}
	}
	return Path{value = fmt.tprintf("%s/%s", self.value, other)}
}

path_equals :: proc(a, b: Path) -> bool {
	return a.value == b.value
}
