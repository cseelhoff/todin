package game

Attribute_Value_Casting :: struct {}

attribute_value_casting_new :: proc(field: ^Field) -> ^Attribute_Value_Casting {
	_ = field
	return new(Attribute_Value_Casting)
}
