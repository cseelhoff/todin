package game

// JDK shim: org.xml.sax.SAXParseException
//
// XML parse error with location info. The TripleA port surfaces these
// from XML validation; we keep just the fields the game-parser code
// actually inspects.

Sax_Parse_Exception :: struct {
	message:      string,
	line_number:  i32,
	column_number: i32,
	public_id:    string,
	system_id:    string,
}

make_Sax_Parse_Exception :: proc(message: string, line: i32, column: i32) -> ^Sax_Parse_Exception {
	self := new(Sax_Parse_Exception)
	self.message = message
	self.line_number = line
	self.column_number = column
	return self
}

sax_parse_exception_get_line_number :: proc(self: ^Sax_Parse_Exception) -> i32 {
	return self.line_number
}

sax_parse_exception_get_column_number :: proc(self: ^Sax_Parse_Exception) -> i32 {
	return self.column_number
}

sax_parse_exception_get_message :: proc(self: ^Sax_Parse_Exception) -> string {
	return self.message
}
