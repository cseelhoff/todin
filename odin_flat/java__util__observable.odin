package game

// JDK shim: java.util.Observable. Synchronous in-process implementation;
// the AI snapshot harness is single-threaded.
Observable :: struct {
	observers: [dynamic]Observer_Callback,
	changed:   bool,
}

Observer_Callback :: proc(observable: ^Observable, arg: rawptr)

observable_add_observer :: proc(self: ^Observable, cb: Observer_Callback) {
	append(&self.observers, cb)
}

observable_delete_observer :: proc(self: ^Observable, cb: Observer_Callback) {
	for o, i in self.observers {
		if o == cb {
			ordered_remove(&self.observers, i)
			return
		}
	}
}

observable_delete_observers :: proc(self: ^Observable) {
	clear(&self.observers)
}

observable_count_observers :: proc(self: ^Observable) -> i32 {
	return i32(len(self.observers))
}

observable_set_changed :: proc(self: ^Observable) {
	self.changed = true
}

observable_clear_changed :: proc(self: ^Observable) {
	self.changed = false
}

observable_has_changed :: proc(self: ^Observable) -> bool {
	return self.changed
}

observable_notify_observers :: proc(self: ^Observable, arg: rawptr = nil) {
	if !self.changed {
		return
	}
	self.changed = false
	for o in self.observers {
		o(self, arg)
	}
}
