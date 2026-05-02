package game

// Java owners covered by this file:
//   - org.triplea.io.IoUtils (utility class, no instance state)

Io_Utils :: struct {}

// Java: <T> T readFromMemory(byte[] bytes, ThrowingFunction<InputStream, T, IOException> function)
// Odin: T is erased to rawptr (matching Throwing_Function.apply); the
// IOException is surfaced as the Maybe(string) error half of apply's
// return tuple. ByteArrayInputStream collapses to the in-memory
// Input_Stream shim, which carries the entire byte buffer.
io_utils_read_from_memory :: proc(bytes: []u8, function: ^Throwing_Function) -> (rawptr, Maybe(string)) {
	assert(bytes != nil)
	assert(function != nil)
	// NB: ByteArrayInputStream does not need to be closed
	return function.apply(rawptr(input_stream_new(bytes)))
}

// Java: byte[] writeToMemory(ThrowingConsumer<OutputStream, IOException> consumer)
// Odin: an in-memory Output_Stream collects everything the consumer
// writes; on success we hand back a copy of its byte buffer.
io_utils_write_to_memory :: proc(consumer: ^Throwing_Consumer) -> ([]u8, Maybe(string)) {
	assert(consumer != nil)
	// NB: ByteArrayOutputStream does not need to be closed
	os := output_stream_new()
	err := consumer.accept(rawptr(os))
	if _, has_err := err.?; has_err {
		return nil, err
	}
	out := make([]u8, len(os.data))
	for b, i in os.data { out[i] = b }
	return out, nil
}

// Java lambda body inside IoUtils.consumeFromMemory:
//   is -> { consumer.accept(is); return null; }
// The captured ThrowingConsumer is passed in as the first parameter;
// the InputStream is the lambda's own argument. Return type matches
// the surrounding ThrowingFunction<InputStream, Void, IOException>:
// the value half is always nil, the error half forwards whatever the
// consumer raised.
io_utils_lambda_consume_from_memory_0 :: proc(consumer: ^Throwing_Consumer, is_stream: ^Input_Stream) -> (rawptr, Maybe(string)) {
	err := consumer.accept(rawptr(is_stream))
	return nil, err
}

