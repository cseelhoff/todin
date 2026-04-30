package game

// JDK shim: java.lang.StringBuilder
//
// Wraps Odin's core:strings.Builder to give callers the Java-style append
// API. Single-threaded; no synchronization (matches JDK StringBuilder).

import "core:strings"
import "core:fmt"

String_Builder :: struct {
	inner: strings.Builder,
}

string_builder_new :: proc() -> ^String_Builder {
	self := new(String_Builder)
	self.inner = strings.builder_make()
	return self
}

string_builder_append :: proc(self: ^String_Builder, s: string) -> ^String_Builder {
	strings.write_string(&self.inner, s)
	return self
}

string_builder_append_int :: proc(self: ^String_Builder, n: i64) -> ^String_Builder {
	fmt.sbprintf(&self.inner, "%d", n)
	return self
}

string_builder_to_string :: proc(self: ^String_Builder) -> string {
	return strings.to_string(self.inner)
}

string_builder_length :: proc(self: ^String_Builder) -> i32 {
	return i32(len(strings.to_string(self.inner)))
}
