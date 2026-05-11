package game

// JDK shim: synchronous in-process implementation; the AI snapshot
// harness is single-threaded, so ThreadLocal degenerates to a single
// value holder. The only live use stores a Boolean, so the value is
// kept as a typed `bool` (storing it as `any` and assigning literals
// causes a stack-use-after-return: Odin synthesises a temporary on
// the caller's stack to back the implicit `bool -> any` conversion,
// and the stored `value.data` pointer dangles after the caller returns).
Thread_Local :: struct {
	value:   bool,
	has_set: bool,
}

thread_local_new :: proc() -> ^Thread_Local {
	return new(Thread_Local)
}

thread_local_get :: proc(self: ^Thread_Local) -> bool {
	return self.value
}

thread_local_set :: proc(self: ^Thread_Local, v: bool) {
	self.value = v
	self.has_set = true
}

thread_local_remove :: proc(self: ^Thread_Local) {
	self.value = false
	self.has_set = false
}
