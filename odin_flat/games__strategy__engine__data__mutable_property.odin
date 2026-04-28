package game

Mutable_Property_Setter :: #type proc(value: rawptr) -> Maybe(string)
Mutable_Property_String_Setter :: #type proc(value: string) -> Maybe(string)
Mutable_Property_Getter :: #type proc() -> rawptr
Mutable_Property_Resetter :: #type proc()

Mutable_Property :: struct {
	setter:        Mutable_Property_Setter,
	string_setter: Mutable_Property_String_Setter,
	getter:        Mutable_Property_Getter,
	resetter:      Mutable_Property_Resetter,
}

Mutable_Property_Invalid_Value_Exception :: struct {
	message: string,
	cause:   ^Mutable_Property_Invalid_Value_Exception,
}

