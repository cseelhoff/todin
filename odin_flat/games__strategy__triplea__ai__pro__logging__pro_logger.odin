package game

import "core:strings"

// Class to log messages to log window and console.
// Utility class with only static methods → empty struct in Phase A.
// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.logging.ProLogger
Pro_Logger :: struct {}

// Adds extra spaces to get logs to line up correctly. (Adds two spaces to
// fine, one to finer, none to finest, etc.) Mirrors Java
// ProLogger#formatMessage(String, Throwable, Level).
pro_logger_format_message :: proc(message: string, t: ^Throwable, level: Level) -> string {
	level_name := level_get_name(level)
	compensate_length := (i32(len(level_name)) - 4) * 2
	if compensate_length < 0 {
		compensate_length = 0
	}
	builder: strings.Builder
	strings.builder_init(&builder)
	for i in 0 ..< int(compensate_length) {
		strings.write_byte(&builder, ' ')
	}
	strings.write_string(&builder, message)
	if t != nil {
		strings.write_string(&builder, " (error: ")
		strings.write_string(&builder, t.message)
		strings.write_string(&builder, ")")
	}
	return strings.to_string(builder)
}

