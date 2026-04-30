package game

I_Editable_Property :: struct {
	get_name:  proc(self: ^I_Editable_Property) -> string,
	get_value: proc(self: ^I_Editable_Property) -> rawptr,
	set_value: proc(self: ^I_Editable_Property, value: rawptr),
}

// Java owners covered by this file:
//   - games.strategy.engine.data.properties.IEditableProperty

// Dispatch for the Java `IEditableProperty#getName()` interface method.
// Embedding structs install their own `get_name` proc; this dispatch
// invokes it and returns "" when no override has been installed.
i_editable_property_get_name :: proc(self: ^I_Editable_Property) -> string {
	if self == nil {
		return ""
	}
	if self.get_name != nil {
		return self.get_name(self)
	}
	return ""
}

// Dispatch for the Java `IEditableProperty#getValue()` interface method.
// Embedding structs install their own `get_value` proc; this dispatch
// invokes it and returns nil when no override has been installed.
i_editable_property_get_value :: proc(self: ^I_Editable_Property) -> rawptr {
	if self == nil {
		return nil
	}
	if self.get_value != nil {
		return self.get_value(self)
	}
	return nil
}

// Dispatch for the Java `IEditableProperty#setValue(Object)` interface method.
// Embedding structs install their own `set_value` proc; this dispatch
// invokes it and is a no-op when no override has been installed.
i_editable_property_set_value :: proc(self: ^I_Editable_Property, value: rawptr) {
	if self == nil {
		return
	}
	if self.set_value != nil {
		self.set_value(self, value)
	}
}

