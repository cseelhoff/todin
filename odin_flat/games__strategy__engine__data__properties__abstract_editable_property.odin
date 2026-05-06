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

abstract_editable_property_v_get_name :: proc(self: ^I_Editable_Property) -> string {
	return abstract_editable_property_get_name(cast(^Abstract_Editable_Property)self)
}

make_Abstract_Editable_Property :: proc(name: string, description: string) -> Abstract_Editable_Property {
	result := Abstract_Editable_Property{
		name = name,
		description = description,
	}
	result.i_editable_property.get_name = abstract_editable_property_v_get_name
	return result
}
