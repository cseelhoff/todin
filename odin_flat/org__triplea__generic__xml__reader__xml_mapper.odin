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
