package game

// JDK shim: synchronous in-process implementation; the AI snapshot
// harness is single-threaded, so ThreadLocal degenerates to a single
// value holder. Stored as an `any` so callers can use it for Boolean,
// Integer, or arbitrary reference types alike.
Thread_Local :: struct {
	value:   any,
	has_set: bool,
}

thread_local_new :: proc() -> ^Thread_Local {
	return new(Thread_Local)
}

thread_local_get :: proc(self: ^Thread_Local) -> any {
	return self.value
}

thread_local_set :: proc(self: ^Thread_Local, v: any) {
	self.value = v
	self.has_set = true
}

thread_local_remove :: proc(self: ^Thread_Local) {
	self.value = nil
	self.has_set = false
}
