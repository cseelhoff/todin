package game

// JDK shim: java.io.InputStream — opaque marker plus the small set
// of procs the snapshot harness's callers actually need. The AI
// snapshot run does not perform real I/O; behavior here is the
// minimum required to compile the call sites.

Input_Stream :: struct {
	data:     [dynamic]u8,
	position: i32,
}

input_stream_new :: proc(data: []u8) -> ^Input_Stream {
	self := new(Input_Stream)
	self.data = make([dynamic]u8, len(data))
	for b, i in data { self.data[i] = b }
	self.position = 0
	return self
}

input_stream_read :: proc(self: ^Input_Stream) -> i32 {
	if self.position >= i32(len(self.data)) { return -1 }
	b := i32(self.data[self.position])
	self.position += 1
	return b
}

input_stream_available :: proc(self: ^Input_Stream) -> i32 {
	return i32(len(self.data)) - self.position
}

input_stream_close :: proc(self: ^Input_Stream) {
	// no-op for in-memory shim
}
