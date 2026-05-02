package game

// JDK shim: javax.xml.stream.XMLStreamReader — opaque marker. The AI
// snapshot harness loads pre-baked JSON snapshots and never actually
// parses XML at runtime. Sites that reference XMLStreamReader (XmlMapper,
// XmlParsingException, XmlParser plumbing) only need the type to exist
// plus a few accessors that return safe defaults.

Xml_Stream_Reader :: struct {
	location_line:   i32,
	location_column: i32,
}

xml_stream_reader_new :: proc() -> ^Xml_Stream_Reader {
	return new(Xml_Stream_Reader)
}

xml_stream_reader_get_line_number :: proc(self: ^Xml_Stream_Reader) -> i32 {
	if self == nil { return 0 }
	return self.location_line
}

xml_stream_reader_get_column_number :: proc(self: ^Xml_Stream_Reader) -> i32 {
	if self == nil { return 0 }
	return self.location_column
}

// XMLStreamReader.getLocation() returns a Location object in Java; here
// we collapse it to the reader itself (it carries the line/column).
xml_stream_reader_get_location :: proc(self: ^Xml_Stream_Reader) -> ^Xml_Stream_Reader {
	return self
}

xml_stream_reader_get_attribute_value :: proc(self: ^Xml_Stream_Reader, namespace_uri: string, local_name: string) -> string {
	_ = self
	_ = namespace_uri
	_ = local_name
	return ""
}

xml_stream_reader_get_local_name :: proc(self: ^Xml_Stream_Reader) -> string {
	_ = self
	return ""
}

xml_stream_reader_has_next :: proc(self: ^Xml_Stream_Reader) -> bool {
	_ = self
	return false
}

xml_stream_reader_next :: proc(self: ^Xml_Stream_Reader) -> i32 {
	_ = self
	return 0
}

xml_stream_reader_has_text :: proc(self: ^Xml_Stream_Reader) -> bool {
	_ = self
	return false
}

xml_stream_reader_get_text :: proc(self: ^Xml_Stream_Reader) -> string {
	_ = self
	return ""
}

xml_stream_reader_close :: proc(self: ^Xml_Stream_Reader) {
	_ = self
}

// XMLStreamConstants event-type values, mirroring javax.xml.stream.XMLStreamConstants.
XML_STREAM_START_ELEMENT :: 1
XML_STREAM_END_ELEMENT   :: 2
XML_STREAM_CHARACTERS    :: 4
