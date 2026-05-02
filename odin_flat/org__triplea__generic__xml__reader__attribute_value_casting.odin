package game

import "core:strconv"
import "core:strings"

Attribute_Value_Casting :: struct {
	field:                ^Field,
	attribute_annotation: ^Attribute,
}

attribute_value_casting_new :: proc(field: ^Field, attribute_annotation: ^Attribute = nil) -> ^Attribute_Value_Casting {
	self := new(Attribute_Value_Casting)
	self.field = field
	self.attribute_annotation = attribute_annotation
	return self
}

// Java: private Integer castToInt(final String attributeValue) throws XmlDataException
//
// The Odin JDK Field shim does not carry runtime type information,
// so the "boxed Integer with zero default returns null" short-circuit
// from Java cannot be distinguished from the primitive-int case. The
// remaining logic is a direct translation.
attribute_value_casting_cast_to_int :: proc(self: ^Attribute_Value_Casting, attribute_value: Maybe(string)) -> (result: Maybe(i32), err: ^Xml_Data_Exception) {
	av, has_av := attribute_value.?
	if !has_av {
		if self.attribute_annotation != nil {
			return i32(self.attribute_annotation.default_int), nil
		}
		return 0, nil
	}
	v, ok := strconv.parse_int(av)
	if !ok {
		err = xml_data_exception_new_for_field(
			self.field,
			strings.concatenate({"Invalid value: ", av, ", required an integer number"}),
		)
		return nil, err
	}
	return i32(v), nil
}

// Java: private Double castToDouble(final String attributeValue) throws XmlDataException
attribute_value_casting_cast_to_double :: proc(self: ^Attribute_Value_Casting, attribute_value: Maybe(string)) -> (result: Maybe(f64), err: ^Xml_Data_Exception) {
	av, has_av := attribute_value.?
	if !has_av {
		if self.attribute_annotation != nil {
			return self.attribute_annotation.default_double, nil
		}
		return 0.0, nil
	}
	v, ok := strconv.parse_f64(av)
	if !ok {
		err = xml_data_exception_new_for_field(
			self.field,
			strings.concatenate({"Invalid value: ", av, ", required a number"}),
		)
		return nil, err
	}
	return v, nil
}

// Java: private Boolean castToBoolean(final String attributeValue) throws XmlDataException
attribute_value_casting_cast_to_boolean :: proc(self: ^Attribute_Value_Casting, attribute_value: Maybe(string)) -> (result: Maybe(bool), err: ^Xml_Data_Exception) {
	av, has_av := attribute_value.?
	if !has_av {
		if self.attribute_annotation != nil {
			return self.attribute_annotation.default_boolean, nil
		}
		return false, nil
	}
	if !strings.equal_fold(av, "true") && !strings.equal_fold(av, "false") {
		err = xml_data_exception_new_for_field(
			self.field,
			strings.concatenate({"Invalid value: ", av, ", required either 'true' or 'false'"}),
		)
		return nil, err
	}
	return strings.equal_fold(av, "true"), nil
}
