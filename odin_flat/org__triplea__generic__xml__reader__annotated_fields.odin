package game

// Port of org.triplea.generic.xml.reader.AnnotatedFields
// Java reflection helper that sorts fields by annotation (@Attribute, @Tag,
// @TagList, @BodyText). Odin has no equivalent runtime reflection, so the
// list-of-Field members are kept (for shape parity) but always remain empty
// in the shim. The pojo Class<T> is held as an opaque typeid marker.

Annotated_Fields :: struct {
	pojo:               typeid,
	attribute_fields:   [dynamic]^Field,
	tag_fields:         [dynamic]^Field,
	tag_list_fields:    [dynamic]^Field,
	body_text_fields:   [dynamic]^Field,
}

// Java: AnnotatedFields(final Class<T> pojo) throws JavaDataModelException
//
// In Java this iterates pojo.getDeclaredFields(), validates each field's
// annotations, sets it accessible, and bins it into one of four lists by
// annotation (@Attribute / @Tag / @TagList / @BodyText). It then enforces
// that there is at most one @BodyText field and that @BodyText is not
// combined with @Tag/@TagList.
//
// Odin has no runtime reflection, so getDeclaredFields() yields nothing in
// the shim. The constructor records the opaque typeid (so callers can still
// identify which Java class this AnnotatedFields was built for) and
// initializes the four lists empty. With no fields enumerated, both
// post-loop validation checks (bodyText size > 1, and the body-text /
// tag(list) combination check) are vacuously satisfied, so no
// JavaDataModelException is ever produced and the out-param exception
// pointer remains nil.
annotated_fields_new :: proc(pojo: typeid) -> (^Annotated_Fields, ^Java_Data_Model_Exception) {
	self := new(Annotated_Fields)
	self.pojo = pojo
	self.attribute_fields = make([dynamic]^Field, 0)
	self.tag_fields = make([dynamic]^Field, 0)
	self.tag_list_fields = make([dynamic]^Field, 0)
	self.body_text_fields = make([dynamic]^Field, 0)

	// for (final Field field : pojo.getDeclaredFields()) { ... }
	// No reflection: the declared-fields sequence is empty in the shim,
	// so the loop body (validateAnnotations + bin into the four lists)
	// never executes.

	// if (bodyTextFields.size() > 1) throw ...
	if len(self.body_text_fields) > 1 {
		return self, java_data_model_exception_new(
			"Too many body text fields, can only have one on any given class",
		)
	}
	// if (!bodyTextFields.isEmpty() && (!tagFields.isEmpty() && !tagListFields.isEmpty())) throw ...
	if len(self.body_text_fields) > 0 &&
	   (len(self.tag_fields) > 0 && len(self.tag_list_fields) > 0) {
		return self, java_data_model_exception_new(
			"Illegal combination of annoations, may only have attributes and a body text," +
			"or attributes and tags (or taglist), but may not have both body text and tags.",
		)
	}
	return self, nil
}

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
