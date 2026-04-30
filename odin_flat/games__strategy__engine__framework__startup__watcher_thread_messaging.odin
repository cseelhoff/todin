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

// games.strategy.engine.framework.startup.WatcherThreadMessaging#handleCurrentGameHostNotReachable()
watcher_thread_messaging_handle_current_game_host_not_reachable :: proc(self: ^Watcher_Thread_Messaging) {
	self.handle_current_game_host_not_reachable(self)
}

