package game

// JDK shim: java.lang.reflect.Field — minimal value carrier.
// The TripleA port does not actually use reflection at runtime. The
// only sites that reference java.lang.reflect.Field (XmlMapper,
// AttributeValueCasting, AnnotatedFields, ReflectionUtils,
// JavaDataModelException, XmlDataException) need at most the field's
// name and declaring class for error formatting. No real reflective
// access is performed during the AI snapshot run.

// Field_Type_Tag is a shim-only enum that records the Java declared
// type of the underlying reflective field for the small subset of
// call sites that branch on it (notably AttributeValueCasting). The
// real port does not perform reflection, so no Field instances are
// constructed at runtime; this tag exists to give the cast helpers a
// faithful dispatch surface.
Field_Type_Tag :: enum {
	STRING,
	INTEGER,
	DOUBLE,
	BOOLEAN,
}

Field :: struct {
	name:            string,
	declaring_class: ^Class,
	field_type_tag:  Field_Type_Tag,
}

field_new :: proc(name: string, declaring_class: ^Class, field_type_tag: Field_Type_Tag = .STRING) -> ^Field {
	f := new(Field)
	f.name = name
	f.declaring_class = declaring_class
	f.field_type_tag = field_type_tag
	return f
}

field_get_name :: proc(self: ^Field) -> string {
	if self == nil {
		return ""
	}
	return self.name
}

field_get_declaring_class :: proc(self: ^Field) -> ^Class {
	if self == nil {
		return nil
	}
	return self.declaring_class
}

field_to_string :: proc(self: ^Field) -> string {
	if self == nil {
		return "<nil field>"
	}
	if self.declaring_class != nil {
		buf: [dynamic]u8
		for c in self.declaring_class.name {
			append(&buf, u8(c))
		}
		append(&buf, '.')
		for c in self.name {
			append(&buf, u8(c))
		}
		return string(buf[:])
	}
	return self.name
}
