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

// Synchronous shim: a single shared "current thread" sentinel suffices
// since the snapshot harness runs single-threaded.
@(private="file")
_current_thread: ^Thread

thread_current_thread :: proc() -> ^Thread {
	if _current_thread == nil {
		_current_thread = new(Thread)
		_current_thread.name = "main"
		_current_thread.alive = true
	}
	return _current_thread
}

thread_get_context_class_loader :: proc(self: ^Thread) -> ^Class_Loader {
	@(static) loader: ^Class_Loader
	if loader == nil { loader = new(Class_Loader) }
	_ = self
	return loader
}
