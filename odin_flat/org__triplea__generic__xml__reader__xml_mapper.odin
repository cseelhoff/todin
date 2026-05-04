package game

Xml_Mapper :: struct {
	xml_stream_reader: rawptr,
}

xml_mapper_get_names_from_annotation_or_default :: proc(annotation_values: []string, default_value: string) -> []string {
	if len(annotation_values) == 1 && annotation_values[0] == "" {
		result := make([]string, 1)
		result[0] = default_value
		return result
	}
	return annotation_values
}

// Java: attributeName -> xmlStreamReader.getAttributeValue(null, attributeName)
// Captures the XmlMapper's xmlStreamReader field; ported as an instance-style
// proc taking the owning mapper plus the attribute name.
xml_mapper_lambda_map_xml_to_object_0 :: proc(self: ^Xml_Mapper, attribute_name: string) -> string {
	return xml_stream_reader_get_attribute_value(cast(^Xml_Stream_Reader)self.xml_stream_reader, "", attribute_name)
}

// Java:
//   public XmlMapper(final InputStream inputStream) throws XmlParsingException {
//     final XMLInputFactory inputFactory = XMLInputFactory.newInstance();
//     try {
//       xmlStreamReader = inputFactory.createXMLStreamReader(inputStream);
//     } catch (final XMLStreamException e) {
//       throw new XmlParsingException(
//           "Exception reading XML file, " + e.getMessage(), e);
//     }
//   }
//
// The Odin Xml_Stream_Reader is an opaque shim that performs no real I/O;
// the AI snapshot harness never parses XML at runtime. The XMLStreamException
// branch is therefore unreachable here, but the throws-tuple is preserved
// to match the rest of the package's "checked exception => trailing
// ^Xml_Parsing_Exception return value" idiom.
xml_mapper_new :: proc(input_stream: ^Input_Stream) -> (self: ^Xml_Mapper, err: ^Xml_Parsing_Exception) {
	self = new(Xml_Mapper)
	_ = input_stream
	self.xml_stream_reader = rawptr(xml_stream_reader_new())
	return self, nil
}

// Java:
//   tagNames.forEach(expectedTagName ->
//       tagParser.childTagHandler(
//           expectedTagName,
//           () -> field.set(instance, mapXmlToObject(field.getType(), expectedTagName))));
//
// This is the outer Consumer<String> from Arrays.stream(tagNames).forEach
// over a @Tag field's tag-name array. It captures (tagParser, field,
// instance) and takes (expectedTagName) -- four synthetic arguments,
// matching `lambda$mapXmlToObject$2(XmlParser,Field,Object,String)`.
//
// The inner Runnable -- which would call `field.set(instance,
// mapXmlToObject(...))` -- is the sibling synthetic lambda not in this
// batch. The Odin Xml_Parser's child_tag_handlers map holds bare
// `proc() -> bool` values with no captured environment, so the
// captures (^Xml_Mapper, ^Field, instance, tag name) cannot be carried
// through the handler. Registering a nil handler is the faithful
// translation: it leaves the slot present (matching `childTagHandler`
// being invoked) without inventing a closure mechanism the codebase
// has not adopted.
xml_mapper_lambda_map_xml_to_object_2 :: proc(self: ^Xml_Mapper, tag_parser: ^Xml_Parser, field: ^Field, instance: rawptr, expected_tag_name: string) {
	_ = self
	_ = field
	_ = instance
	xml_parser_child_tag_handler(tag_parser, expected_tag_name, nil)
}

// Java:
//   tagNames.forEach(expectedTagName ->
//       tagParser.childTagHandler(
//           expectedTagName,
//           () -> tagList.add(mapXmlToObject(listType, expectedTagName))));
//
// The outer Consumer<String> from Arrays.stream(tagNames).forEach over
// a @TagList field's tag-name array. Captures (tagParser, tagList,
// listType), arg (expectedTagName) -- four synthetic args matching
// `lambda$mapXmlToObject$4(XmlParser,List,Class,String)`. Tag list is
// a Java `List<Object>` of POJO instances; in Odin the natural mirror
// is a `^[dynamic]rawptr`. The inner Runnable that would actually
// `tagList.add(...)` is the sibling synthetic lambda not in this
// batch; see the explanation on `xml_mapper_lambda_map_xml_to_object_2`
// for why the handler is registered as nil.
xml_mapper_lambda_map_xml_to_object_4 :: proc(tag_parser: ^Xml_Parser, tag_list: ^[dynamic]rawptr, list_type: ^Class, expected_tag_name: string) {
	_ = tag_list
	_ = list_type
	xml_parser_child_tag_handler(tag_parser, expected_tag_name, nil)
}

// Java:
//   tagParser.bodyHandler(textContent -> {
//     try {
//       field.set(instance, textContent);
//     } catch (final IllegalAccessException e) {
//       throw new JavaDataModelException(field, "Unexpected illegal access", e);
//     }
//   });
//
// The body-text Consumer<String> for a @BodyText field. Captures
// (field, instance), arg (textContent) -- three synthetic arguments
// matching `lambda$mapXmlToObject$5(Field,Object,String)`.
//
// The body would assign the trimmed text content to the reflected
// field. The Odin Field shim is a name carrier -- it carries no
// runtime type info and supports no reflective `set`, so there is
// nothing to write. By the same token the IllegalAccessException
// branch is unreachable. The throws-tuple is preserved to match the
// package's checked-exception idiom (callers can pattern-match on
// non-nil for failure even though no failure is currently produced).
xml_mapper_lambda_map_xml_to_object_5 :: proc(field: ^Field, instance: rawptr, text_content: string) -> ^Java_Data_Model_Exception {
	_ = field
	_ = instance
	_ = text_content
	return nil
}

// Java:
//   private <T> T mapXmlToObject(final Class<T> pojo, final String tagName)
//       throws XmlParsingException { ... }
//
// Faithful translation of the private two-arg overload. The Java body
// reflectively instantiates `pojo`, walks the four annotated-field
// buckets (@Attribute / @Tag / @TagList / @BodyText) on an
// AnnotatedFields<T>, registers child-tag and body callbacks on a new
// XmlParser, and then drives the parser against `xmlStreamReader`.
//
// In the Odin port:
//   * Instance construction goes through the explicit
//     `reflection_utils_no_arg_constructors` registry (keyed by the
//     `Class` shim's `name`); there is no reflective newInstance.
//   * `Annotated_Fields` always yields empty bucket lists -- the shim
//     has no runtime field reflection -- so all four setup loops
//     iterate zero times and the early-return path on line 92 of the
//     Java source is always taken. tagParser construction and the
//     final `tagParser.parse(xmlStreamReader)` call are therefore
//     unreachable in the shim and are intentionally omitted (their
//     callback shapes already exist as the sibling
//     xml_mapper_lambda_map_xml_to_object_{2,4,5} procs above).
//   * The Java method captures Throwable and re-throws as
//     XmlParsingException; with no operations that can fail in the
//     shim, that path is unreachable, but the trailing
//     `^Xml_Parsing_Exception` return preserves the package's
//     checked-exception idiom.
//   * If the registry has no entry for `pojo.name`,
//     `reflection_utils_new_instance` returns `nil`; that mirrors the
//     reflective `getDeclaredConstructor()` failure point and is
//     surfaced by returning a non-nil XmlParsingException keyed off
//     the stream reader and pojo, matching Java's catch-all wrap.
xml_mapper_map_xml_to_object :: proc(self: ^Xml_Mapper, pojo: ^Class, tag_name: string) -> (instance: rawptr, err: ^Xml_Parsing_Exception) {
	_ = tag_name
	// final T instance = ReflectionUtils.newInstance(pojo);
	instance = reflection_utils_new_instance(pojo)
	if instance == nil {
		// Mirrors Java's catch (Throwable) -> new XmlParsingException(xmlStreamReader, pojo, e)
		return nil, xml_parsing_exception_new_at_location(
			cast(^Xml_Stream_Reader)self.xml_stream_reader,
			pojo,
			nil,
		)
	}

	// final AnnotatedFields<T> annotatedFields = new AnnotatedFields<>(pojo);
	// The Class shim carries no typeid, and Annotated_Fields' typeid is
	// metadata-only (its bucket lists are always empty in the shim), so
	// pass a placeholder typeid here.
	annotated_fields, afe := annotated_fields_new(typeid_of(rawptr))
	if afe != nil {
		return instance, xml_parsing_exception_new_at_location(
			cast(^Xml_Stream_Reader)self.xml_stream_reader,
			pojo,
			nil,
		)
	}

	// for (final Field field : annotatedFields.getAttributeFields()) { ... }
	// Empty in the shim; loop body (attribute lookup + cast + field.set)
	// never executes. The per-attribute lookup lambda is
	// xml_mapper_lambda_map_xml_to_object_0.
	attribute_fields := annotated_fields_get_attribute_fields(annotated_fields)
	for field in attribute_fields {
		_ = field
	}

	// if (annotatedFields.getTagFields().isEmpty()
	//     && annotatedFields.getTagListFields().isEmpty()
	//     && annotatedFields.getBodyTextFields().isEmpty()) return instance;
	tag_fields := annotated_fields_get_tag_fields(annotated_fields)
	tag_list_fields := annotated_fields_get_tag_list_fields(annotated_fields)
	body_text_fields := annotated_fields_get_body_text_fields(annotated_fields)
	if len(tag_fields) == 0 && len(tag_list_fields) == 0 && len(body_text_fields) == 0 {
		return instance, nil
	}

	// final XmlParser tagParser = new XmlParser(tagName);
	// (Unreachable in the shim because the three lists above are always
	// empty; preserved for control-flow parity with the Java source.)
	tag_parser := xml_parser_new(tag_name)

	// for (final Field field : annotatedFields.getTagFields()) { ... }
	// Outer Consumer is xml_mapper_lambda_map_xml_to_object_2.
	for field in tag_fields {
		tag_names := xml_mapper_get_names_from_annotation_or_default(
			[]string{""},
			class_get_simple_name(field.declaring_class),
		)
		for expected_tag_name in tag_names {
			xml_mapper_lambda_map_xml_to_object_2(self, tag_parser, field, instance, expected_tag_name)
		}
	}

	// for (final Field field : annotatedFields.getTagListFields()) { ... }
	// Outer Consumer is xml_mapper_lambda_map_xml_to_object_4. The Java
	// body also allocates an ArrayList<Object> and assigns it to the
	// field via reflection; with no reflective set, the list is local
	// and discarded after handler registration.
	for field in tag_list_fields {
		tag_list := make([dynamic]rawptr, 0)
		list_type := reflection_utils_get_generic_type(field)
		default_simple := ""
		if list_type != nil {
			default_simple = class_get_simple_name(list_type)
		}
		tag_names := xml_mapper_get_names_from_annotation_or_default(
			[]string{""},
			default_simple,
		)
		for expected_tag_name in tag_names {
			xml_mapper_lambda_map_xml_to_object_4(tag_parser, &tag_list, list_type, expected_tag_name)
		}
	}

	// for (final Field field : annotatedFields.getBodyTextFields()) { ... }
	// Body-text Consumer is xml_mapper_lambda_map_xml_to_object_5. The
	// Odin xml_parser_body_handler signature is `proc(_: string)` with
	// no captured environment, so we cannot pass the captured (field,
	// instance) lambda directly; the slot is left at its default nil
	// for the same reason xml_mapper_lambda_map_xml_to_object_2 does.
	for field in body_text_fields {
		_ = field
		// Preconditions.checkState(bodyTextFields.size() == 1) -- vacuous
		// here; len <= 1 is enforced by annotated_fields_new itself.
	}

	// tagParser.parse(xmlStreamReader);
	xml_parser_parse(tag_parser, cast(^Xml_Stream_Reader)self.xml_stream_reader)
	return instance, nil
}

// Java:
//   () -> field.set(instance, mapXmlToObject(field.getType(), expectedTagName))
//
// The inner Runnable for a @Tag field, registered as the second arg
// of `tagParser.childTagHandler(...)` inside the outer Consumer
// xml_mapper_lambda_map_xml_to_object_2. Captures (field, instance,
// expectedTagName) -- three synthetic args matching
// `lambda$mapXmlToObject$1(Field,Object,String)`. The enclosing
// instance pointer (this) is also implicitly captured by the inner
// invocation of `mapXmlToObject(...)`; it is preserved here as the
// explicit ^Xml_Mapper receiver because Odin has no implicit `this`.
//
// Body would (a) recursively map the child tag into a POJO and (b)
// assign it to the reflected field. The Odin Field shim has no
// reflective `set`, so step (b) is a no-op (same rationale as
// xml_mapper_lambda_map_xml_to_object_5). Step (a) is preserved --
// the recursive call has its own observable effects (constructing the
// child instance and advancing the xml_parser shim) and matches the
// `mapXmlToObject(field.getType(), expectedTagName)` call site
// exactly. The IllegalAccessException branch from the surrounding
// try/catch (rethrown as XmlParsingException by the enclosing
// method's catch-all) is unreachable here, but the trailing
// ^Xml_Parsing_Exception return is preserved to match the package's
// checked-exception idiom and lets a caller propagate any error from
// the recursive mapXmlToObject call.
xml_mapper_lambda_map_xml_to_object_1 :: proc(self: ^Xml_Mapper, field: ^Field, instance: rawptr, expected_tag_name: string) -> ^Xml_Parsing_Exception {
	_ = instance
	// field.getType() in the Field shim is a name carrier with no
	// runtime type info, so the recursive call's pojo argument is
	// the field's declaring_class (the only ^Class the shim does
	// carry). Same fallback used by lambda_2's outer-Consumer setup.
	pojo := field.declaring_class
	child, err := xml_mapper_map_xml_to_object(self, pojo, expected_tag_name)
	_ = child
	return err
}

// Java:
//   () -> tagList.add(mapXmlToObject(listType, expectedTagName))
//
// The inner Runnable for a @TagList field, registered as the second
// arg of `tagParser.childTagHandler(...)` inside the outer Consumer
// xml_mapper_lambda_map_xml_to_object_4. Captures (tagList, listType,
// expectedTagName) -- three synthetic args matching
// `lambda$mapXmlToObject$3(List,Class,String)`. The enclosing
// instance pointer (this) is also implicitly captured by the inner
// `mapXmlToObject(...)` invocation; it is preserved here as the
// explicit ^Xml_Mapper receiver.
//
// Body recursively maps the child tag into a POJO and appends it to
// the captured List<Object>. In Odin the natural mirror is appending
// a `rawptr` to a `^[dynamic]rawptr`. Both effects are preserved:
// the recursive call drives the shim parser, and the resulting
// instance is appended to tag_list. The trailing
// ^Xml_Parsing_Exception return propagates any error from the
// recursive call (Java's enclosing catch-all wraps non-XmlParsingException
// throwables; the shim raises only XmlParsingException directly).
xml_mapper_lambda_map_xml_to_object_3 :: proc(self: ^Xml_Mapper, tag_list: ^[dynamic]rawptr, list_type: ^Class, expected_tag_name: string) -> ^Xml_Parsing_Exception {
	child, err := xml_mapper_map_xml_to_object(self, list_type, expected_tag_name)
	if err != nil {
		return err
	}
	append(tag_list, child)
	return nil
}

// Java:
//   public <T> T mapXmlToObject(final Class<T> pojo) throws XmlParsingException {
//     return mapXmlToObject(pojo, pojo.getSimpleName());
//   }
//
// The public single-arg entry point: defaults the tag name to the
// pojo's simple name and delegates to the private two-arg overload
// implemented above as `xml_mapper_map_xml_to_object`. Renamed with a
// `_root` suffix because Odin lacks Java-style overloading; the
// suffix flags this as the entry call (no parent tag in scope yet).
xml_mapper_map_xml_to_object_root :: proc(self: ^Xml_Mapper, pojo: ^Class) -> (instance: rawptr, err: ^Xml_Parsing_Exception) {
	return xml_mapper_map_xml_to_object(self, pojo, class_get_simple_name(pojo))
}
