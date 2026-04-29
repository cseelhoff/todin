package game

Decoder :: struct {
	reader: ^Nio_Reader,
	running: bool,
	error_reporter: ^Error_Reporter,
	object_stream_factory: ^I_Object_Stream_Factory,
	nio_socket: ^Nio_Socket,
	quarantine: map[^Socket_Channel]^Quarantine_Conversation,
	thread: ^Thread,
}
// Java owners covered by this file:
//   - games.strategy.net.nio.Decoder

