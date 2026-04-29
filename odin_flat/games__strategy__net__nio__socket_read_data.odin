package game

Socket_Read_Data :: struct {
	target_size:    i32,
	size_buffer:    ^u8,
	content_buffer: ^u8,
	channel:        ^u8,
	read_calls:     i32,
}

// Java owners covered by this file:
//   - games.strategy.net.nio.SocketReadData

