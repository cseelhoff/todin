package game

// JDK shim: synchronous in-process implementation; the AI snapshot
// harness is single-threaded, so Thread is just a holder for the
// runnable target plus a few state bits the callers inspect.
Thread :: struct {
	name:    string,
	target:  proc(),
	started: bool,
	alive:   bool,
}

thread_new :: proc(target: proc(), name: string = "") -> ^Thread {
	t := new(Thread)
	t.target = target
	t.name = name
	return t
}

thread_start :: proc(self: ^Thread) {
	self.started = true
	self.alive = true
	if self.target != nil {
		self.target()
	}
	self.alive = false
}

thread_join :: proc(self: ^Thread) {
	// Synchronous shim: start() already ran the target to completion.
}

thread_interrupt :: proc(self: ^Thread) {
	self.alive = false
}

thread_is_alive :: proc(self: ^Thread) -> bool {
	return self.alive
}

thread_get_name :: proc(self: ^Thread) -> string {
	return self.name
}

thread_set_name :: proc(self: ^Thread, name: string) {
	self.name = name
}
