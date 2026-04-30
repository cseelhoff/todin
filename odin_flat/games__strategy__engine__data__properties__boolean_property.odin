package game

// games.strategy.engine.data.properties.BooleanProperty

Boolean_Property :: struct {
	using abstract_editable_property: Abstract_Editable_Property,
	value:        bool,
}

boolean_property_get_value :: proc(self: ^Boolean_Property) -> bool {
	return self.value
}
