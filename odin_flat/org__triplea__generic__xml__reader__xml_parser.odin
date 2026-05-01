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

