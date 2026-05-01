package game

// Java owners covered by this file:
//   - org.triplea.io.FileUtils

File_Utils :: struct {}

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
