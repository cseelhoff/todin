package game

Server_Launcher_Server_Ready :: struct {
	using i_server_ready: I_Server_Ready,
	latch:        ^Count_Down_Latch,
	clients:      i32,
}

make_Server_Launcher_Server_Ready :: proc(clients_to_wait_for: int) -> Server_Launcher_Server_Ready {
	return Server_Launcher_Server_Ready{
		clients = i32(clients_to_wait_for),
		latch   = count_down_latch_new(i32(clients_to_wait_for)),
	}
}
