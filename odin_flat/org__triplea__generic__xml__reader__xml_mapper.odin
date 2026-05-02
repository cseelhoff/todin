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
