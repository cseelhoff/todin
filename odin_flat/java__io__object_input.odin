package game

// JDK shim: opaque marker for java.io.ObjectInput. The AI snapshot
// harness instantiates TripleA subclasses for compile-time wiring
// but does not perform real serialization during the snapshot run.
// The procs below are no-op stand-ins so that compile-only ports of
// Externalizable.readExternal can call them faithfully without
// implementing JVM serialization semantics.
Object_Input :: struct {}

object_input_read_object :: proc(self: ^Object_Input) -> rawptr {
	return nil
}

object_input_read_byte :: proc(self: ^Object_Input) -> u8 {
	return 0
}

object_input_read_int :: proc(self: ^Object_Input) -> i32 {
	return 0
}

object_input_read_long :: proc(self: ^Object_Input) -> i64 {
	return 0
}

object_input_read_boolean :: proc(self: ^Object_Input) -> bool {
	return false
}

object_input_read_utf :: proc(self: ^Object_Input) -> string {
	return ""
}
