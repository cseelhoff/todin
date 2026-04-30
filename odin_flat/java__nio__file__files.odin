package game

// JDK shim: java.nio.file.Files. Implements only the operations the
// AI snapshot harness invokes during setup. Single-process semantics.
// Path is a value type per java__nio__file__path.odin.

import "core:os"
import "core:strings"

files_exists :: proc(p: Path) -> bool {
	return os.exists(p.value)
}

files_is_directory :: proc(p: Path) -> bool {
	return os.is_dir(p.value)
}

files_is_regular_file :: proc(p: Path) -> bool {
	return os.is_file(p.value)
}

files_create_directories :: proc(p: Path) -> Path {
	parts := strings.split(p.value, "/")
	defer delete(parts)
	b := strings.Builder{}
	strings.builder_init(&b)
	defer strings.builder_destroy(&b)
	if strings.has_prefix(p.value, "/") {
		strings.write_byte(&b, '/')
	}
	for part, i in parts {
		if part == "" {
			continue
		}
		if i > 0 || strings.has_prefix(p.value, "/") {
			cur := strings.to_string(b)
			if len(cur) > 0 && !strings.has_suffix(cur, "/") {
				strings.write_byte(&b, '/')
			}
		}
		strings.write_string(&b, part)
		dir := strings.to_string(b)
		if !os.exists(dir) {
			os.make_directory(dir)
		}
	}
	return p
}

files_list :: proc(p: Path) -> [dynamic]Path {
	out: [dynamic]Path
	fd, err := os.open(p.value)
	if err != nil {
		return out
	}
	defer os.close(fd)
	entries, ferr := os.read_dir(fd, -1)
	if ferr != nil {
		return out
	}
	defer delete(entries)
	for entry in entries {
		append(&out, Path{value = strings.concatenate({p.value, "/", entry.name})})
	}
	return out
}

files_delete :: proc(p: Path) {
	os.remove(p.value)
}
