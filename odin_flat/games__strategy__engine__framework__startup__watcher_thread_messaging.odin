package game

Watcher_Thread_Messaging :: struct {
	handle_current_game_host_not_reachable: proc(self: ^Watcher_Thread_Messaging),
}

Headless_Watcher_Thread_Messaging :: struct {
	using base: Watcher_Thread_Messaging,
}

Headed_Watcher_Thread_Messaging :: struct {
	using base: Watcher_Thread_Messaging,
        parent:     ^Component,
}

