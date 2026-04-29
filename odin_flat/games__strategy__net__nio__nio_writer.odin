package game

Nio_Writer :: struct {
	selector:        ^Selector,
	error_reporter:  ^Error_Reporter,
	writing:         map[^Socket_Channel][dynamic]^Socket_Write_Data,
	sockets_to_wake: [dynamic]^Socket_Channel,
	mutex:           ^Object,
	running:         bool,
}

