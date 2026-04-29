package game

Server_Ready :: struct {
	using i_server_ready: I_Server_Ready,
	latch:   ^Count_Down_Latch,
	clients: i32,
}
