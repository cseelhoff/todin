package game

Nio_Reader :: struct {
	output_queue:         ^Blocking_Queue,
	running:              bool,
	reading:              map[^Socket_Channel]^Socket_Read_Data,
	error_reporter:       ^Error_Reporter,
	selector:             ^Selector,
	sockets_to_add_mutex: ^Object,
	sockets_to_add:       [dynamic]^Socket_Channel,
}
