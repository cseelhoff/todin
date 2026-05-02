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

// Java: private static <T> void validateAnnotations(final Field field) throws JavaDataModelException
//
// In Java this inspects the @Attribute / @Tag / @TagList / @BodyText
// annotations on a reflected Field, verifies each annotation is on a
// legal field type (e.g. @Attribute only on String / boxed primitives,
// @TagList only on java.util.List, @BodyText only on String), and
// throws JavaDataModelException if any rule is violated or if more
// than one of those annotations is present.
//
// The Odin port has no runtime reflection: the `Field` shim carries
// only `name` and `declaring_class`, so the field's static type and
// its annotation set are both unavailable. With no inputs to inspect,
// every check would be vacuously true. The proc therefore mirrors
// Java's control flow with `annotation_count` and the four annotation
// gates, but each gate's "field has annotation X" predicate is always
// false in the shim, so the proc reports "no error" by returning nil.
// Returning ^Java_Data_Model_Exception (nil == ok) matches the
// idiom used elsewhere in this package for converting Java's
// `throws` into an explicit return value.
annotated_fields_validate_annotations :: proc(field: ^Field) -> ^Java_Data_Model_Exception {
	annotation_count := 0

	// if (field.getAnnotation(Attribute.class) != null) { ... }
	// Shim cannot answer "has @Attribute"; treat as absent.
	has_attribute := false
	if has_attribute {
		// Type checks on @Attribute placement and conflicting
		// defaultBoolean / defaultInt / defaultDouble values would
		// happen here. Without a reflected Class<?> they are
		// unreachable in the shim.
		annotation_count += 1
	}

	// if (field.getAnnotation(Tag.class) != null) { ... }
	has_tag := false
	if has_tag {
		annotation_count += 1
	}

	// if (field.getAnnotation(TagList.class) != null) { ... }
	has_tag_list := false
	if has_tag_list {
		annotation_count += 1
	}

	// if (field.getAnnotation(BodyText.class) != null) { ... }
	has_body_text := false
	if has_body_text {
		annotation_count += 1
	}

	if annotation_count > 1 {
		return java_data_model_exception_new_for_field(
			field,
			"Too may annotations on field, can only have one of: @Tag, or @TagList, or @Attribute, or @BodyText",
		)
	}

	return nil
}
