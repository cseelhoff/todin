package game

// games.strategy.engine.data.properties.StringProperty

String_Property :: struct {
	using abstract_editable_property: Abstract_Editable_Property,
	value:        string,
}

string_property_new :: proc(name: string, description: string, default_value: string) -> ^String_Property {
	self := new(String_Property)
	self.abstract_editable_property = make_Abstract_Editable_Property(name, description)
	self.value = default_value
	return self
}

string_property_get_value :: proc(self: ^String_Property) -> string {
	return self.value
}

string_property_set_value :: proc(self: ^String_Property, value: string) {
	self.value = value
}
