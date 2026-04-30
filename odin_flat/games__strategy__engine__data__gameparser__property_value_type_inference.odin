package game

import "core:strconv"
import "core:strings"

Property_Value_Type_Inference :: struct {}

property_value_type_inference_infer_type :: proc(value: string) -> typeid {
	if value == "" {
		return typeid_of(string)
	}
	if strings.equal_fold(value, "true") || strings.equal_fold(value, "false") {
		return typeid_of(bool)
	}
	if _, ok := strconv.parse_int(value, 10); ok {
		return typeid_of(i32)
	}
	return typeid_of(string)
}

property_value_type_inference_cast_to_inferred_type :: proc(value: string) -> Property_Value {
	inferred_type := property_value_type_inference_infer_type(value)
	if inferred_type == typeid_of(bool) {
		return strings.equal_fold(value, "true")
	} else if inferred_type == typeid_of(i32) {
		parsed, _ := strconv.parse_int(value, 10)
		return i32(parsed)
	} else {
		return value
	}
}

