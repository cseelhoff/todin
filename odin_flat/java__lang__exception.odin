package game

// JDK shim: minimal java.lang.Exception. The AI snapshot harness
// does not exercise real exception handling; this captures the
// message so call sites that pass exceptions around stay typed.
Exception :: struct {
	message: string,
	cause:   ^Exception,
}

exception_new :: proc(message: string) -> ^Exception {
	e := new(Exception)
	e.message = message
	return e
}

exception_get_message :: proc(self: ^Exception) -> string {
	return self.message
}
