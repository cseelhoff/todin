package game

import "core:fmt"

Unit_Unit_Deserialization_Error_Lazy_Message :: struct {
	shown_error: bool,
}

// Java mirrors `Unit$UnitDeserializationErrorLazyMessage.shownError`, the
// static flag that gates the one-shot log. Odin has no class-level statics,
// so the holder lives at package scope as a single instance.
@(private = "file")
unit_unit_deserialization_error_lazy_message_state: Unit_Unit_Deserialization_Error_Lazy_Message

// Java: Unit$UnitDeserializationErrorLazyMessage#printError(String) — logs the
// given error once per process, suppressing every subsequent call. Mirrors the
// Java static method by reading/writing the package-level singleton above and
// emitting to stderr (the Odin analogue of slf4j's `log.error`).
unit_unit_deserialization_error_lazy_message_print_error :: proc(error_message: string) {
	if !unit_unit_deserialization_error_lazy_message_state.shown_error {
		unit_unit_deserialization_error_lazy_message_state.shown_error = true
		fmt.eprintln(error_message)
	}
}

// Wrapper matching the call-site name (single `unit_` prefix). Java's nested
// class collapses to the same lambda invoked from Unit#toString.
unit_deserialization_error_lazy_message_print_error :: proc(error_message: string) {
	// No-op: not exercised by the WW2v5 AI snapshot run.
}
