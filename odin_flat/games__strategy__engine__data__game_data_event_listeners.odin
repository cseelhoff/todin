package game

// A listener entry stores a proc that takes an opaque context pointer
// alongside the context itself. This mirrors Java's lambda captures:
// `() -> { self.foo = ... }` becomes `(proc(ctx: rawptr) { ... }, self)`.
//
// Bare-Runnable callers (no captured context) pass `nil` for `ctx`.
Game_Data_Event_Listener_Entry :: struct {
	callback: proc(ctx: rawptr),
	ctx:      rawptr,
}

Game_Data_Event_Listeners :: struct {
	listeners: map[Game_Data_Event][dynamic]Game_Data_Event_Listener_Entry,
}

make_Game_Data_Event_Listeners :: proc() -> Game_Data_Event_Listeners {
	return Game_Data_Event_Listeners{
		listeners = make(map[Game_Data_Event][dynamic]Game_Data_Event_Listener_Entry),
	}
}

game_data_event_listeners_add_listener :: proc(
	self: ^Game_Data_Event_Listeners,
	event: Game_Data_Event,
	callback: proc(ctx: rawptr),
	ctx: rawptr = nil,
) {
	if event not_in self.listeners {
		self.listeners[event] = make([dynamic]Game_Data_Event_Listener_Entry)
	}
	bucket := &self.listeners[event]
	append(bucket, Game_Data_Event_Listener_Entry{callback = callback, ctx = ctx})
}

game_data_event_listeners_accept :: proc(self: ^Game_Data_Event_Listeners, event: Game_Data_Event) {
	entries, ok := self.listeners[event]
	if !ok {
		return
	}
	// Copy to avoid concurrent modification (mirrors Java List.copyOf).
	snapshot := make([dynamic]Game_Data_Event_Listener_Entry, 0, len(entries))
	defer delete(snapshot)
	for e in entries {
		append(&snapshot, e)
	}
	for e in snapshot {
		e.callback(e.ctx)
	}
}
