package game

Object_Property_Change :: struct {
	using change: Change,
	object:    ^Unit,
	property:  string,
	new_value: rawptr,
	old_value: rawptr,
}
