package game

import "core:fmt"
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

// Java: Object castAttributeValue(final String attributeValue) throws XmlDataException
//
// Dispatches on the underlying Field's declared Java type. The Odin
// port does not unbox these values back to typed Maybe(i32) /
// Maybe(f64) / Maybe(bool) at any call site, so we render the cast
// result as its textual form and return Maybe(string), preserving
// nil-vs-empty distinctions exactly the way the Java side preserves
// null-vs-Optional. For the String branch the Java code is
//   Strings.emptyToNull(Optional.ofNullable(av).orElseGet(default))
// i.e. fall back to attributeAnnotation.defaultValue() when av is
// null, then map "" → null.
attribute_value_casting_cast_attribute_value :: proc(self: ^Attribute_Value_Casting, attribute_value: Maybe(string)) -> (result: Maybe(string), err: ^Xml_Data_Exception) {
	switch self.field.field_type_tag {
	case .INTEGER:
		v, ierr := attribute_value_casting_cast_to_int(self, attribute_value)
		if ierr != nil {
			return nil, ierr
		}
		iv, has_iv := v.?
		if !has_iv {
			return nil, nil
		}
		return fmt.tprintf("%d", iv), nil
	case .DOUBLE:
		v, derr := attribute_value_casting_cast_to_double(self, attribute_value)
		if derr != nil {
			return nil, derr
		}
		dv, has_dv := v.?
		if !has_dv {
			return nil, nil
		}
		buf: [40]u8
		s := strconv.write_float(buf[:], dv, 'g', -1, 64)
		return strings.clone(s), nil
	case .BOOLEAN:
		v, berr := attribute_value_casting_cast_to_boolean(self, attribute_value)
		if berr != nil {
			return nil, berr
		}
		bv, has_bv := v.?
		if !has_bv {
			return nil, nil
		}
		if bv {
			return "true", nil
		}
		return "false", nil
	case .STRING:
		fallthrough
	case:
		// Strings.emptyToNull(Optional.ofNullable(av).orElseGet(default))
		s: string
		if av, has_av := attribute_value.?; has_av {
			s = av
		} else if self.attribute_annotation != nil {
			s = self.attribute_annotation.default_value
		}
		if len(s) == 0 {
			return nil, nil
		}
		return s, nil
	}
}
