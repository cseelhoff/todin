package game

Reflection_Utils :: struct {}

// Java owners covered by this file:
//   - org.triplea.generic.xml.reader.ReflectionUtils

reflection_utils_get_generic_type :: proc(field: ^Field) -> ^Class {
	return nil
}

// Class-name-keyed registry of no-arg constructors. Implementing types
// (the XML POJOs that XmlMapper rehydrates) populate this map at
// package initialization with a single allocator per fully-qualified
// Java class name carried on the `Class` shim. The Odin port has no
// runtime reflection over arbitrary types, so this registry is the
// explicit replacement for `Class#getDeclaredConstructor().newInstance()`.
// The same pattern is used for `property_enum_constants` in
// `games.strategy.engine.data.PropertyEnum`.
reflection_utils_no_arg_constructors: map[string]proc() -> rawptr

// org.triplea.generic.xml.reader.ReflectionUtils#newInstance(Class<T>)
//
// Java:
//   final Constructor<T> constructor = pojo.getDeclaredConstructor();
//   constructor.setAccessible(true);
//   return constructor.newInstance();
//
// The Odin port dispatches through `reflection_utils_no_arg_constructors`
// keyed by the fully-qualified class name carried on the `Class` shim.
// A nil `pojo` or an unregistered class name yields a nil pointer,
// mirroring the JavaDataModelException paths via the same nil-as-empty
// Optional idiom used elsewhere in the port (e.g.
// `property_enum_parse_from_string`). Setting the constructor
// "accessible" is meaningless in Odin and has no analogue.
reflection_utils_new_instance :: proc(pojo: ^Class) -> rawptr {
	if pojo == nil {
		return nil
	}
	ctor, ok := reflection_utils_no_arg_constructors[pojo.name]
	if !ok {
		return nil
	}
	return ctor()
}
