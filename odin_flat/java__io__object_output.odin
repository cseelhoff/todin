package game

// JDK shim: opaque marker for java.io.ObjectOutput. The AI snapshot
// harness instantiates TripleA subclasses for compile-time wiring
// but does not perform real serialization during the snapshot run.
// The procs below are no-op stand-ins so that compile-only ports of
// Externalizable.writeExternal can call them faithfully without
// implementing JVM serialization semantics.
Object_Output :: struct {}

object_output_write_object :: proc(self: ^Object_Output, obj: rawptr) {
}

object_output_write_byte :: proc(self: ^Object_Output, b: u8) {
}

object_output_write_int :: proc(self: ^Object_Output, v: i32) {
}

object_output_write_long :: proc(self: ^Object_Output, v: i64) {
}

object_output_write_boolean :: proc(self: ^Object_Output, v: bool) {
}

object_output_write_utf :: proc(self: ^Object_Output, s: string) {
}
