package game

import "core:strings"

Game_Parse_Exception :: struct {
	message: string,
	cause:   ^Throwable,
}

make_Game_Parse_Exception :: proc(message: string) -> ^Game_Parse_Exception {
	self := new(Game_Parse_Exception)
	self.message = message
	return self
}

make_Game_Parse_Exception_with_cause :: proc(message: string, cause: ^Throwable) -> ^Game_Parse_Exception {
	self := new(Game_Parse_Exception)
	self.message = message
	self.cause = cause
	return self
}

game_parse_exception_format_error_message :: proc(errors: []string) -> string {
	b := strings.builder_make()
	for error in errors {
		strings.write_string(&b, error)
	}
	return strings.to_string(b)
}

lambda_game_parse_exception_format_error_message_0 :: proc(builder: ^String_Builder, error: ^Sax_Parse_Exception) {
	string_builder_append(builder, "SAXParseException: Line: ")
	string_builder_append_int(builder, i64(sax_parse_exception_get_line_number(error)))
	string_builder_append(builder, ", column: ")
	string_builder_append_int(builder, i64(sax_parse_exception_get_column_number(error)))
	string_builder_append(builder, ", error: ")
	string_builder_append(builder, sax_parse_exception_get_message(error))
}
