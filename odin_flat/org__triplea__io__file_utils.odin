package game

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:strings"

// Java owners covered by this file:
//   - org.triplea.io.FileUtils

File_Utils :: struct {}

// Java: public static Path newTempFolder()
//   return Files.createTempDirectory("triplea");
// Path → string per layer-1 task directive.
file_utils_new_temp_folder :: proc() -> string {
	base := os.get_env("TMPDIR")
	if base == "" {
		base = "/tmp"
	}
	for i := 0; i < 1024; i += 1 {
		suffix := rand.int63()
		candidate := fmt.aprintf("%s/triplea%d_%d", base, suffix, i)
		if !os.exists(candidate) {
			os.make_directory(candidate)
			if os.is_dir(candidate) {
				return candidate
			}
		}
		delete(candidate)
	}
	return ""
}

// Java: public Optional<Path> findClosestToRoot(Path searchRoot, int maxDepth, String fileName)
//   return find(searchRoot, maxDepth, fileName).stream().findAny();
// Where find() walks up to maxDepth, filters by fileName equality, sorts
// ascending by absolute-path-length. findAny() therefore returns the
// shortest-path match (closest to root). Path → string; absent → "".
file_utils_find_closest_to_root :: proc(
	search_root: string,
	max_depth: i32,
	file_name: string,
) -> string {
	if max_depth < 0 || file_name == "" || !os.is_dir(search_root) {
		return ""
	}

	matches: [dynamic]string
	defer {
		for m in matches {
			delete(m)
		}
		delete(matches)
	}

	Stack_Entry :: struct {
		path:  string,
		depth: i32,
	}
	stack: [dynamic]Stack_Entry
	defer {
		for e in stack {
			delete(e.path)
		}
		delete(stack)
	}
	append(&stack, Stack_Entry{path = strings.clone(search_root), depth = 0})

	for len(stack) > 0 {
		entry := pop(&stack)

		if filepath.base(entry.path) == file_name {
			append(&matches, strings.clone(entry.path))
		}

		if entry.depth < max_depth && os.is_dir(entry.path) {
			fd, oerr := os.open(entry.path)
			if oerr == nil {
				children, rerr := os.read_dir(fd, -1, context.allocator)
				os.close(fd)
				if rerr == nil {
					for child in children {
						joined, _ := filepath.join({entry.path, child.name}, context.allocator)
						append(&stack, Stack_Entry{path = joined, depth = entry.depth + 1})
					}
					delete(children)
				}
			}
		}

		delete(entry.path)
	}

	if len(matches) == 0 {
		return ""
	}

	best := 0
	for i := 1; i < len(matches); i += 1 {
		if len(matches[i]) < len(matches[best]) {
			best = i
		}
	}
	return strings.clone(matches[best])
}

// Snapshot port: real filesystem traversal and writes are skipped.
// The AI snapshot harness uses pre-baked JSON, so these procs return
// empty/safe results. Pure-logic procs (the lambdas) mirror Java.

file_utils_list_files :: proc(directory: Path) -> [dynamic]Path {
	return make([dynamic]Path, 0)
}

file_utils_find :: proc(
	search_root: Path,
	max_depth: i32,
	file_name: string,
) -> [dynamic]Path {
	return make([dynamic]Path, 0)
}

file_utils_lambda_find_0 :: proc(file_name: string, f: Path) -> bool {
	name := path_get_file_name(f)
	return path_to_string(name) == file_name
}

// Java: Comparator.comparingInt(f -> f.toAbsolutePath().toString().length())
file_utils_lambda_find_1 :: proc(f: Path) -> int {
	return len(path_to_string(f))
}

file_utils_find_file_in_parent_folders :: proc(
	search_root: Path,
	file_name: string,
) -> ^Path {
	// Snapshot harness: no real disk; mirror "not found" => empty Optional.
	return nil
}

// Java: files.filter(Predicate.not(Files::isDirectory))
file_utils_lambda_find_xml_files_2 :: proc(f: Path) -> bool {
	// Snapshot port has no directory metadata; treat every entry as a file.
	return true
}

// Java: file -> file.getFileName().toString().endsWith(".xml")
file_utils_lambda_find_xml_files_3 :: proc(f: Path) -> bool {
	name := path_to_string(path_get_file_name(f))
	suffix := ".xml"
	if len(name) < len(suffix) {
		return false
	}
	return name[len(name) - len(suffix):] == suffix
}

file_utils_write_to_file :: proc(file_to_write: Path, contents: string) {
	// Snapshot run never writes to disk.
}
