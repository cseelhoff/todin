package game

// games.strategy.engine.data.properties.BooleanProperty

Boolean_Property :: struct {
	using abstract_editable_property: Abstract_Editable_Property,
	value:        bool,
}

boolean_property_get_value :: proc(self: ^Boolean_Property) -> bool {
	return self.value
}

boolean_property_set_value :: proc(self: ^Boolean_Property, value: bool) {
	self.value = value
}

boolean_property_new :: proc(name: string, description: string, default_value: bool) -> ^Boolean_Property {
	self := new(Boolean_Property)
	self.abstract_editable_property = make_Abstract_Editable_Property(name, description)
	self.value = default_value
	return self
}
