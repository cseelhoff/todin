package game

Server_Launcher_Server_Ready :: struct {
	using parent: I_Server_Ready,
	latch:        ^Count_Down_Latch,
	clients:      i32,
}
