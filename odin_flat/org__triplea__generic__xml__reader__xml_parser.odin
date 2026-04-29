package game

Xml_Parser :: struct {
	tag_name:           string,
	child_tag_handlers: map[string]proc() -> bool,
	body_handler:       proc(_: string),
}

