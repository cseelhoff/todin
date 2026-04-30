package game

Object_Property_Change :: struct {
	using change: Change,
	object:    ^Unit,
	property:  string,
	new_value: rawptr,
	old_value: rawptr,
}

object_property_change_get_property :: proc(self: ^Object_Property_Change) -> string {
	return self.property
}
