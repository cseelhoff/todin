package game

Error_Reporter :: struct {
	error: proc(self: ^Error_Reporter, channel: ^Socket_Channel, e: ^Exception),
}

