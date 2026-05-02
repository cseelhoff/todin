package game

import "core:strings"

Xml_Parser :: struct {
	tag_name:           string,
	child_tag_handlers: map[string]proc() -> bool,
	body_handler:       proc(_: string),
}

xml_parser_new :: proc(tag_name: string) -> ^Xml_Parser {
	self := new(Xml_Parser)
	self.tag_name = strings.to_upper(tag_name)
	self.child_tag_handlers = make(map[string]proc() -> bool)
	self.body_handler = nil
	return self
}

xml_parser_body_handler :: proc(self: ^Xml_Parser, handler: proc(_: string)) -> ^Xml_Parser {
	self.body_handler = handler
	return self
}

xml_parser_child_tag_handler :: proc(self: ^Xml_Parser, name: string, handler: proc() -> bool) -> ^Xml_Parser {
	self.child_tag_handlers[strings.to_upper(name)] = handler
	return self
}

xml_parser_parse :: proc(self: ^Xml_Parser, stream_reader: ^Xml_Stream_Reader) {
	text_element_builder := strings.builder_make()
	defer strings.builder_destroy(&text_element_builder)
	for xml_stream_reader_has_next(stream_reader) {
		event := xml_stream_reader_next(stream_reader)
		switch event {
		case XML_STREAM_START_ELEMENT:
			child_tag := strings.to_upper(xml_stream_reader_get_local_name(stream_reader))
			handler, ok := self.child_tag_handlers[child_tag]
			if ok && handler != nil {
				handler()
			}
		case XML_STREAM_CHARACTERS:
			if xml_stream_reader_has_text(stream_reader) && self.body_handler != nil {
				text := xml_stream_reader_get_text(stream_reader)
				strings.write_string(&text_element_builder, text)
			}
		case XML_STREAM_END_ELEMENT:
			if self.body_handler != nil {
				body := strings.trim_space(strings.to_string(text_element_builder))
				self.body_handler(body)
			}
			strings.builder_reset(&text_element_builder)

			end_tag_name := xml_stream_reader_get_local_name(stream_reader)
			if strings.equal_fold(end_tag_name, self.tag_name) {
				return
			}
		}
	}
}

