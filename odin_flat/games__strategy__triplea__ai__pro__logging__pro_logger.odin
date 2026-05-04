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

// Static ProLogger.log(Level, String, Throwable). Mirrors the Java
// gate logic: load (cached) ProLogSettings, drop the message if
// logging is disabled or if the configured depth is coarser than
// the message's level, otherwise route the formatted message to
// the AI log UI sink. The snapshot harness has no AI log window,
// so the sink is a no-op — the formatted message is computed
// (matching the Java side effects of formatMessage) and discarded.
pro_logger_log :: proc(level: Level, message: string, t: ^Throwable) {
	settings := pro_log_settings_load_settings()
	if !pro_log_settings_is_log_enabled(settings) {
		return
	}
	log_depth := pro_log_settings_get_log_level(settings)
	level_value := level_int_value(level)
	fine := level_int_value(.Fine)
	finer := level_int_value(.Finer)
	finest := level_int_value(.Finest)
	if log_depth == fine && (level_value == finer || level_value == finest) {
		return
	}
	if log_depth == finer && level_value == finest {
		return
	}
	_ = pro_logger_format_message(message, t, level)
}

// Private ProLogger.log(Level, String) — forwards to the 3-arg
// form with a nil Throwable.
pro_logger_log_1 :: proc(level: Level, message: string) {
	pro_logger_log(level, message, nil)
}

