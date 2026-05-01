package game

import "core:strings"

// Java owners covered by this file:
//   - org.triplea.java.StringUtils

String_Utils :: struct {}

string_utils_capitalize :: proc(s: string) -> string {
	if len(s) == 0 {
		return s
	}
	first := s[0]
	if first >= 'a' && first <= 'z' {
		buf := make([]u8, len(s))
		for i in 0 ..< len(s) {
			buf[i] = s[i]
		}
		buf[0] = first - ('a' - 'A')
		return string(buf)
	}
	return strings.clone(s)
}

string_utils_truncate_from :: proc(s: string, terminator: string) -> string {
	idx := strings.index(s, terminator)
	if idx < 0 {
		return s
	}
	return s[:idx]
}

