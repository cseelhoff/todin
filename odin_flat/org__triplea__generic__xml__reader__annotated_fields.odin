package game

// Port of org.triplea.generic.xml.reader.AnnotatedFields
// Java reflection helper that sorts fields by annotation (@Attribute, @Tag,
// @TagList, @BodyText). Odin has no equivalent runtime reflection, so this
// is a placeholder type with no fields.

Annotated_Fields :: struct {}

annotated_fields_get_attribute_fields :: proc(self: ^Annotated_Fields) -> [dynamic]^Field {
	_ = self
	return make([dynamic]^Field, 0)
}

annotated_fields_get_body_text_fields :: proc(self: ^Annotated_Fields) -> [dynamic]^Field {
	_ = self
	return make([dynamic]^Field, 0)
}

annotated_fields_get_tag_fields :: proc(self: ^Annotated_Fields) -> [dynamic]^Field {
	_ = self
	return make([dynamic]^Field, 0)
}

annotated_fields_get_tag_list_fields :: proc(self: ^Annotated_Fields) -> [dynamic]^Field {
	_ = self
	return make([dynamic]^Field, 0)
}
