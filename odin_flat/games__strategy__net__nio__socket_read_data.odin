package game

Socket_Read_Data :: struct {
	target_size:    i32,
	size_buffer:    ^Byte_Buffer,
	content_buffer: ^Byte_Buffer,
	channel:        ^Socket_Channel,
	read_calls:     i32,
}

// Java owners covered by this file:
//   - games.strategy.net.nio.SocketReadData

