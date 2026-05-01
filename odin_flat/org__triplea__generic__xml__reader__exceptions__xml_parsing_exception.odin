package game

import "core:fmt"

// Java owners covered by this file:
//   - org.triplea.generic.xml.reader.exceptions.XmlParsingException

Xml_Parsing_Exception :: struct {
	using exception: Exception,
}

// Java: public <T> XmlParsingException(final String message, final Throwable e)
//   super(message, e);
xml_parsing_exception_new_with_cause :: proc(message: string, cause: ^Throwable) -> ^Xml_Parsing_Exception {
	self := new(Xml_Parsing_Exception)
	self.exception.message = message
	if cause != nil {
		wrapped := new(Exception)
		wrapped.message = cause.message
		self.exception.cause = wrapped
	}
	return self
}

// Java: public <T> XmlParsingException(
//           final XMLStreamReader xmlStreamReader,
//           final Class<T> pojo,
//           final Throwable e)
//   super(String.format(
//       "Parsing halted at line: %s, column: %s, while mapping to: %s, error: %s",
//       xmlStreamReader.getLocation().getLineNumber(),
//       xmlStreamReader.getLocation().getColumnNumber(),
//       pojo.getCanonicalName(),
//       e.getMessage()),
//     e);
xml_parsing_exception_new_at_location :: proc(reader: ^Xml_Stream_Reader, type_class: ^Class, cause: ^Throwable) -> ^Xml_Parsing_Exception {
	location := xml_stream_reader_get_location(reader)
	line := xml_stream_reader_get_line_number(location)
	column := xml_stream_reader_get_column_number(location)
	canonical_name := ""
	if type_class != nil {
		canonical_name = class_get_name(type_class)
	}
	cause_message := ""
	if cause != nil {
		cause_message = cause.message
	}
	message := fmt.aprintf(
		"Parsing halted at line: %d, column: %d, while mapping to: %s, error: %s",
		line,
		column,
		canonical_name,
		cause_message,
	)
	self := new(Xml_Parsing_Exception)
	self.exception.message = message
	if cause != nil {
		wrapped := new(Exception)
		wrapped.message = cause.message
		self.exception.cause = wrapped
	}
	return self
}
