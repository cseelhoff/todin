package game

// JDK shim: java.lang.Class — minimal value carrier for the few sites that
// pass a `Class<T>` token (e.g. attachment-type lookups, error formatting).
// The TripleA port does not use reflection; the shim only carries the
// simple/full class name so it can be printed and compared.

Class :: struct {
	name:        string,
	simple_name: string,
}

class_new :: proc(name: string, simple_name: string) -> ^Class {
	c := new(Class)
	c.name = name
	c.simple_name = simple_name
	return c
}

class_get_name :: proc(self: ^Class) -> string {
	return self.name
}

class_get_simple_name :: proc(self: ^Class) -> string {
	return self.simple_name
}

class_to_string :: proc(self: ^Class) -> string {
	return self.name
}

// Class.cast(Object) — runtime type check. The Odin port does not do
// reflective casts, so this is a pass-through identity returning the
// value unchanged. Callers that genuinely need narrowing perform it
// elsewhere via Odin's type system.
class_cast :: proc(self: ^Class, value: rawptr) -> rawptr {
	_ = self
	return value
}

// Class.equals(other) — name-based equality is sufficient for the
// snapshot harness.
class_equals :: proc(self: ^Class, other: ^Class) -> bool {
	if self == other {
		return true
	}
	if self == nil || other == nil {
		return false
	}
	return self.name == other.name
}
