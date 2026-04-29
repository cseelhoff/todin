package game

import "core:fmt"

Dynamically_Modifiable :: struct {
	get_property_map: map[string]^Mutable_Property,
}

// Mirrors Java's `DynamicallyModifiable.getPropertyOrThrow(String)`. Delegates
// to `dynamically_modifiable_get_property` and panics with the same message
// the Java side raises via `IllegalArgumentException` when the property is
// missing.
dynamically_modifiable_get_property_or_throw :: proc(
	self: ^Dynamically_Modifiable,
	name: string,
) -> ^Mutable_Property {
	property := dynamically_modifiable_get_property(self, name)
	if property == nil {
		fmt.panicf("unknown property named '%s'", name)
	}
	return property
}

// Mirrors Java's `DynamicallyModifiable.getProperty(String)` default method.
// Java delegates to `getPropertyOrEmpty`; the Odin port stores properties in
// a map field on the implementing struct, so we look up the name directly.
dynamically_modifiable_get_property :: proc(
	self: ^Dynamically_Modifiable,
	name: string,
) -> ^Mutable_Property {
	return self.get_property_map[name]
}

