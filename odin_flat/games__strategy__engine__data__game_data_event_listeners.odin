package game

Game_Data_Event_Listeners :: struct {
	listeners: map[Game_Data_Event][dynamic]proc(),
}

make_Game_Data_Event_Listeners :: proc() -> Game_Data_Event_Listeners {
	return Game_Data_Event_Listeners{
		listeners = make(map[Game_Data_Event][dynamic]proc()),
	}
}

game_data_event_listeners_add_listener :: proc(self: ^Game_Data_Event_Listeners, event: Game_Data_Event, runnable: proc()) {
	if event not_in self.listeners {
		self.listeners[event] = make([dynamic]proc())
	}
	bucket := &self.listeners[event]
	append(bucket, runnable)
}

game_data_event_listeners_accept :: proc(self: ^Game_Data_Event_Listeners, event: Game_Data_Event) {
	runnables, ok := self.listeners[event]
	if !ok {
		return
	}
	// Copy to avoid concurrent modification (mirrors Java List.copyOf).
	snapshot := make([dynamic]proc(), 0, len(runnables))
	defer delete(snapshot)
	for r in runnables {
		append(&snapshot, r)
	}
	for r in snapshot {
		r()
	}
}
