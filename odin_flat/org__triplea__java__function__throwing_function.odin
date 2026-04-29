package game

// Ported from org.triplea.java.function.ThrowingFunction
// Functional interface: R apply(T value) throws E.
// Odin has no generics or checked exceptions; modeled as a struct holding
// a proc field that takes a rawptr argument and returns a rawptr result
// plus an optional error. Callers cast to the concrete input/output types.
Throwing_Function :: struct {
	apply: proc(value: rawptr) -> (result: rawptr, err: Maybe(string)),
}

