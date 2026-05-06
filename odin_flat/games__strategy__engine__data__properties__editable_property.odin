package game

// Editable_Property interface shim.
//
// Mirrors games.strategy.engine.data.properties.IEditableProperty: a
// named property whose `T getValue()` is the binding queried by
// GameProperties.get(key) before falling back to constantProperties.
// The Odin port collapses the IEditableProperty<T> generic into a
// single concrete struct holding a Property_Value union (the same
// union used by constant_properties).
Editable_Property :: struct {
	name:  string,
	value: Property_Value,
}

// IEditableProperty#getValue()
editable_property_get_value :: proc(self: ^Editable_Property) -> Property_Value {
	if self == nil {
		return nil
	}
	return self.value
}

// IEditableProperty#setValue(T)
editable_property_set_value :: proc(self: ^Editable_Property, value: Property_Value) {
	self.value = value
}
