package game

// JDK shim: java.io.OutputStream — opaque-ish struct plus the small
// set of procs the snapshot harness's callers actually need. The AI
// snapshot run does not perform real I/O; behavior here is the
// minimum required to compile the call sites.

Output_Stream :: struct {
	data: [dynamic]u8,
}

output_stream_new :: proc() -> ^Output_Stream {
	self := new(Output_Stream)
	self.data = make([dynamic]u8)
	return self
}

output_stream_write :: proc(self: ^Output_Stream, b: i32) {
	append(&self.data, u8(b & 0xFF))
}

output_stream_write_bytes :: proc(self: ^Output_Stream, bytes: []u8) {
	for b in bytes { append(&self.data, b) }
}

output_stream_flush :: proc(self: ^Output_Stream) {
	// no-op for in-memory shim
}

output_stream_close :: proc(self: ^Output_Stream) {
	// no-op for in-memory shim
}
