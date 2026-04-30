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

// Mirrors Java's `DynamicallyModifiable.getPropertyOrEmpty(String)`. In Java
// this is the abstract method that subclasses override; the Odin port stores
// the property table on the embedded `Dynamically_Modifiable` struct, so we
// look the name up there and return `nil` (empty) when absent.
dynamically_modifiable_get_property_or_empty :: proc(
	self: ^Dynamically_Modifiable,
	name: string,
) -> Maybe(^Mutable_Property) {
	property := dynamically_modifiable_get_property(self, name)
	if property == nil {
		return nil
	}
	return property
}

// Mirrors the synthetic supplier lambda Java emits for
// `getPropertyOrThrow`'s `orElseThrow(() -> new IllegalArgumentException(...))`.
// Returns the formatted message the Java side passes to the exception
// constructor; callers panic or surface the error themselves.
lambda_dynamically_modifiable_get_property_or_throw_0 :: proc(
	name: string,
) -> string {
	return fmt.aprintf("unknown property named '%s'", name)
}

