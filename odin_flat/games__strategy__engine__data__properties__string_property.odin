package game

// games.strategy.engine.data.properties.StringProperty

String_Property :: struct {
	using abstract_editable_property: Abstract_Editable_Property,
	value:        string,
}

string_property_get_value :: proc(self: ^String_Property) -> string {
	return self.value
}

string_property_set_value :: proc(self: ^String_Property, value: string) {
	self.value = value
}
