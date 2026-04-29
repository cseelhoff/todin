package game

// Java owner: games.strategy.net.nio.NioSocket
// implements ErrorReporter

Nio_Socket :: struct {
	using error_reporter: Error_Reporter,
	encoder:  ^Encoder,
	decoder:  ^Decoder,
	writer:   ^Nio_Writer,
	reader:   ^Nio_Reader,
	listener: ^Nio_Socket_Listener,
}
