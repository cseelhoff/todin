package game

// games.strategy.engine.data.PropertyEnum<A>
// Java interface implemented by enums that expose a property name and
// a MutableProperty accessor on an attachment. No data fields; methods
// belong to Phase B on the implementing enums.
Property_Enum :: struct {
	get_value:             proc(self: ^Property_Enum) -> string,
	get_property_accessor: proc(self: ^Property_Enum) -> proc(attachment: rawptr) -> ^Mutable_Property,
}

// Dispatch for the Java `PropertyEnum#getValue()` interface method.
// Implementing enums install their own `get_value` proc; this dispatch
// invokes it and returns "" when no override has been installed.
property_enum_get_value :: proc(self: ^Property_Enum) -> string {
	if self == nil {
		return ""
	}
	if self.get_value != nil {
		return self.get_value(self)
	}
	return ""
}

// Dispatch for the Java `PropertyEnum#getPropertyAccessor()` interface
// method. Returns a `Function<A, MutableProperty<?>>` modelled as a
// bare `proc(attachment: rawptr) -> ^Mutable_Property` (the per-enum
// override is non-capturing — it builds the MutableProperty from
// the attachment passed in at apply-time). Implementing enums install
// their own `get_property_accessor`; this dispatcher just forwards.
property_enum_get_property_accessor :: proc(
	self: ^Property_Enum,
) -> proc(attachment: rawptr) -> ^Mutable_Property {
	if self == nil {
		return nil
	}
	if self.get_property_accessor != nil {
		return self.get_property_accessor(self)
	}
	return nil
}

// Class-keyed registry of `PropertyEnum` constants. Implementing enums
// (e.g. `UnitSupportAttachment.PropertyName`) populate this map at
// package initialization with one `^Property_Enum` entry per enum
// constant, keyed by the fully-qualified Java class name carried on the
// `Class` shim. The Odin port has no reflection, so this registry is
// the explicit replacement for `Class.getEnumConstants()`.
property_enum_constants: map[string][dynamic]^Property_Enum

// games.strategy.engine.data.PropertyEnum#parseFromString(Class<E>, String)
//
// Java:
//   return Arrays.stream(enumClass.getEnumConstants())
//       .filter(e -> e.getValue().equals(propertyName))
//       .findAny();
//
// Returns `Optional<E>`. The Odin port models the Optional via a
// nil-as-empty `^Property_Enum`: a non-nil pointer is `Optional.of(e)`,
// nil is `Optional.empty()`. The lookup is a linear scan over the
// constants registered under `class.name`, mirroring the Java stream.
property_enum_parse_from_string :: proc(class: ^Class, property_name: string) -> ^Property_Enum {
	if class == nil {
		return nil
	}
	constants, ok := property_enum_constants[class.name]
	if !ok {
		return nil
	}
	for e in constants {
		if property_enum_get_value(e) == property_name {
			return e
		}
	}
	return nil
}

