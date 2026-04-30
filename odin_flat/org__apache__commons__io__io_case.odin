package game

// External-library shim: org.apache.commons.io.IOCase.
// Implements only the constants and methods called from TripleA.

import "core:strings"

Io_Case :: struct {
	name:      string,
	sensitive: bool,
}

io_case_sensitive := Io_Case{name = "Sensitive", sensitive = true}
io_case_insensitive := Io_Case{name = "Insensitive", sensitive = false}
// SYSTEM uses platform default; the AI snapshot harness runs Linux,
// where filesystem comparisons are case-sensitive.
io_case_system := Io_Case{name = "System", sensitive = true}

io_case_check_ends_with :: proc(self: ^Io_Case, str: string, suffix: string) -> bool {
	if len(suffix) > len(str) {
		return false
	}
	tail := str[len(str) - len(suffix):]
	if self.sensitive {
		return tail == suffix
	}
	return strings.equal_fold(tail, suffix)
}

io_case_check_starts_with :: proc(self: ^Io_Case, str: string, prefix: string) -> bool {
	if len(prefix) > len(str) {
		return false
	}
	head := str[:len(prefix)]
	if self.sensitive {
		return head == prefix
	}
	return strings.equal_fold(head, prefix)
}

io_case_check_equals :: proc(self: ^Io_Case, a: string, b: string) -> bool {
	if self.sensitive {
		return a == b
	}
	return strings.equal_fold(a, b)
}

io_case_is_case_sensitive :: proc(self: ^Io_Case) -> bool {
	return self.sensitive
}

io_case_get_name :: proc(self: ^Io_Case) -> string {
	return self.name
}
