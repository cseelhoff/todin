package game

import "core:strings"

Xml_Data_Exception :: struct {
	using exception: Exception,
}

// Java: public XmlDataException(final Field field, final String message)
//   super("Bad XML data while setting field: " + field + ", " + message);
xml_data_exception_new_for_field :: proc(field: ^Field, message: string) -> ^Xml_Data_Exception {
	self := new(Xml_Data_Exception)
	self.exception.message = strings.concatenate({"Bad XML data while setting field: ", field_to_string(field), ", ", message})
	return self
}

