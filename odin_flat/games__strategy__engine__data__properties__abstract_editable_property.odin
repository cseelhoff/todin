package game

// games.strategy.engine.data.properties.AbstractEditableProperty

Abstract_Editable_Property :: struct {
	using i_editable_property: I_Editable_Property,
	name:         string,
	description:  string,
}

abstract_editable_property_get_name :: proc(self: ^Abstract_Editable_Property) -> string {
	return self.name
}
