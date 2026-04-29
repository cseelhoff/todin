package game

// JDK shim: java.nio.ByteBuffer — minimal byte buffer for
// compile-time references. The AI snapshot harness does not
// perform real NIO I/O, so the buffer's only job is to satisfy
// type signatures.

Byte_Buffer :: struct {
	data:     [dynamic]u8,
	position: i32,
	limit:    i32,
	capacity: i32,
}

byte_buffer_allocate :: proc(capacity: i32) -> ^Byte_Buffer {
	b := new(Byte_Buffer)
	b.data = make([dynamic]u8, capacity)
	b.position = 0
	b.limit = capacity
	b.capacity = capacity
	return b
}

byte_buffer_wrap :: proc(bytes: []u8) -> ^Byte_Buffer {
	b := new(Byte_Buffer)
	b.data = make([dynamic]u8, len(bytes))
	for v, i in bytes do b.data[i] = v
	b.position = 0
	b.limit = i32(len(bytes))
	b.capacity = i32(len(bytes))
	return b
}

byte_buffer_clear :: proc(self: ^Byte_Buffer) {
	self.position = 0
	self.limit = self.capacity
}

byte_buffer_flip :: proc(self: ^Byte_Buffer) {
	self.limit = self.position
	self.position = 0
}

byte_buffer_remaining :: proc(self: ^Byte_Buffer) -> i32 {
	return self.limit - self.position
}

byte_buffer_has_remaining :: proc(self: ^Byte_Buffer) -> bool {
	return self.position < self.limit
}
